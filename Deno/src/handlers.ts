import type { Handler, HandlerParams, MapValue } from "./types.ts";
import { encoder, decoder, messages } from "./constants.ts";
import {
  validKeyNoValue,
  validKeyAndValue,
  checkNoKey,
  validKey,
} from "./middleware.ts";
import { Lock, streamDump, parseDuration } from "./helpers.ts";

import { createHash } from "https://deno.land/std@0.134.0/hash/mod.ts";
import { encode } from "https://deno.land/std@0.134.0/encoding/base64.ts";

const map = new Map<string, MapValue>();

let timeout = 10000;
let snapshot = new Map<string, MapValue>();
const dumpLock = new Lock();

let getCount = 0;
let setCount = 0;
let delCount = 0;

export async function startRecurring() {
  setTimeout(async () => {
    await dumpLock.lock();
    snapshot = new Map(map);
    dumpLock.release();
    startRecurring();
  }, timeout);
}

export const handlers: Record<string, Handler> = {
  GET: validKeyNoValue(get),
  SET: validKeyAndValue(set),
  DEL: validKeyNoValue(del),
  GETC: checkNoKey(getc),
  SETC: checkNoKey(setc),
  DELC: checkNoKey(delc),
  NEWDUMP: checkNoKey(newdump),
  GETDUMP: checkNoKey(getdump),
  DUMPINTERVAL: dumpinterval,
  SETTTL: validKeyAndValue(setttl),
  UPLOAD: validKey(upload),
  DOWNLOAD: validKeyNoValue(download),
  REMOVE: validKeyNoValue(remove),
};

async function get({ conn, key }: HandlerParams) {
  getCount++;
  const value = map.get(key);
  conn.write(value ? encoder.encode(`${value.text}\n`) : messages.notFound);
}

async function set({ conn, key, val }: HandlerParams) {
  setCount++;
  const current = map.get(key);
  if (current) {
    conn.write(encoder.encode(`${current.text}\n`));
    current.text = val;
    current.date = new Date();
  } else {
    conn.write(messages.notFound);
    map.set(key, { text: val, date: new Date() });
  }
}

async function del({ conn, key }: HandlerParams) {
  delCount++;
  const val = map.get(key);
  if (val) {
    conn.write(encoder.encode(`${val.text}\n`));
    map.delete(key);
  } else {
    conn.write(messages.notFound);
  }
}

async function getc({ conn }: HandlerParams) {
  conn.write(encoder.encode(`${getCount}\n`));
}

async function setc({ conn }: HandlerParams) {
  conn.write(encoder.encode(`${setCount}\n`));
}

async function delc({ conn }: HandlerParams) {
  conn.write(encoder.encode(`${delCount}\n`));
}

async function newdump({ conn }: HandlerParams) {
  await dumpLock.lock();
  snapshot = new Map(map);
  await streamDump(conn, snapshot);
  dumpLock.release();
}

async function getdump({ conn, ...rest }: HandlerParams) {
  if (snapshot) {
    await dumpLock.lock();
    await streamDump(conn, snapshot);
    dumpLock.release();
  } else {
    await newdump({ conn, ...rest });
  }
}

async function dumpinterval({ conn, key }: HandlerParams) {
  const { success, duration } = parseDuration(key);
  if (success) {
    timeout = duration * 1000;
  } else {
    conn.write(messages.notFound);
  }
}

async function setttl(params: HandlerParams) {
  const { success, duration } = parseDuration(params.duration);
  if (success) {
    await set(params);
    setTimeout(() => {
      map.delete(params.key);
    }, duration * 1000);
  } else {
    params.conn.write(messages.notFound);
  }
}

async function upload({ conn, key, val, duration }: HandlerParams) {
  if (duration) {
    await conn.write(messages.notFound);
    return;
  }

  let size: bigint;
  try {
    size = BigInt(val);
  } catch {
    await conn.write(messages.notFound);
    return;
  }

  const file = await Deno.open(key, {
    create: true,
    write: true,
    truncate: true,
  });

  let readTotal = BigInt(0);
  const bufsize = 1024;
  const buf = new Uint8Array(bufsize);
  const hash = createHash("sha512");

  await conn.write(messages.ready);

  while (readTotal < size) {
    const read = await conn.read(buf);
    if (read == null) {
      conn.close();
      break;
    }

    const filled = buf.subarray(
      0,
      readTotal + BigInt(read) > size ? Number(size - readTotal) : read
    );

    readTotal += BigInt(read);
    hash.update(filled);
    await file.write(filled);
  }

  file.close();

  await conn.write(encoder.encode(`${encode(hash.digest())}\n`));

  const read = await conn.read(buf);
  if (read == null) {
    conn.close();
    return;
  }
  const text = decoder.decode(buf.subarray(0, read - 1));
  if (text == "ERROR") {
    await Deno.remove(key);
  }
}

async function download({ conn, key }: HandlerParams) {}

async function remove({ conn, key }: HandlerParams) {
  try {
    await Deno.remove(key);
  } catch {
    await conn.write(messages.notFound);
  }
}
