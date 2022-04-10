import type { Handler, HandlerParams, MapValue } from "./types.ts";
import { encoder, notFound } from "./constants.ts";
import { validKeyNoValue, validKeyAndValue, checkNoKey } from "./middleware.ts";
import { Lock, streamDump, parseDuration } from "./helpers.ts";

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
};

async function get({ conn, key }: HandlerParams) {
  getCount++;
  const value = map.get(key);
  conn.write(value ? encoder.encode(`${value.text}\n`) : notFound);
}

async function set({ conn, key, val }: HandlerParams) {
  setCount++;
  const current = map.get(key);
  if (current) {
    conn.write(encoder.encode(`${current.text}\n`));
    current.text = val;
    current.date = new Date();
  } else {
    conn.write(notFound);
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
    conn.write(notFound);
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
    conn.write(notFound);
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
    params.conn.write(notFound);
  }
}
