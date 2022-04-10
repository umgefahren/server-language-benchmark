const encoder = new TextEncoder();
const decoder = new TextDecoder();

const notFound = encoder.encode("not found\n");
const invalidCommand = encoder.encode("not found\n");

const map = new Map<string, string>();
let getCount = 0;
let setCount = 0;
let delCount = 0;

type Handler = (conn: Deno.Conn, key: string, val: string) => Promise<void>;

const ops: Record<string, Handler> = {
  GET: validKeyNoValue(get),
  SET: validKeyAndValue(set),
  DEL: validKeyNoValue(del),
  GETC: checkNoKey(getc),
  SETC: checkNoKey(setc),
  DELC: checkNoKey(delc),
};

function isValidKey(key: string): boolean {
  for (const char of key) {
    const code = char.charCodeAt(0);
    if (
      !(code > 47 && code < 58) &&
      !(code > 64 && code < 91) &&
      !(code > 96 && code < 123)
    ) {
      return false;
    }
  }
  return true;
}

function checkValidKey(handler: Handler): Handler {
  return async (conn: Deno.Conn, key: string, val: string) => {
    if (isValidKey(key)) {
      handler(conn, key, val);
    } else {
      conn.write(notFound);
    }
  };
}

function checkValidValue(handler: Handler): Handler {
  return async (conn: Deno.Conn, key: string, val: string) => {
    if (isValidKey(val)) {
      handler(conn, key, val);
    } else {
      conn.write(notFound);
    }
  };
}

function checkNoValue(handler: Handler): Handler {
  return async (conn: Deno.Conn, key: string, val: string) => {
    if (val) {
      conn.write(invalidCommand);
    } else {
      handler(conn, key, val);
    }
  };
}

function checkNoKey(handler: Handler): Handler {
  return async (conn: Deno.Conn, key: string, val: string) => {
    if (key) {
      conn.write(invalidCommand);
    } else {
      handler(conn, key, val);
    }
  };
}

function validKeyNoValue(handler: Handler): Handler {
  return checkValidKey(checkNoValue(handler));
}

function validKeyAndValue(handler: Handler): Handler {
  return checkValidKey(checkValidValue(handler));
}

async function get(conn: Deno.Conn, key: string, _: string) {
  getCount++;
  const value = map.get(key);
  conn.write(value ? encoder.encode(`${value}\n`) : notFound);
}

async function set(conn: Deno.Conn, key: string, val: string) {
  setCount++;
  const current = map.get(key);
  conn.write(current ? encoder.encode(`${current}\n`) : notFound);
  map.set(key, val);
}

async function del(conn: Deno.Conn, key: string, _: string) {
  delCount++;
  const val = map.get(key);
  if (val) {
    conn.write(encoder.encode(`${val}\n`));
    map.delete(key);
  } else {
    conn.write(notFound);
  }
}

async function getc(conn: Deno.Conn, _: string, __: string) {
  conn.write(encoder.encode(`${getCount}\n`));
}

async function setc(conn: Deno.Conn, _: string, __: string) {
  conn.write(encoder.encode(`${setCount}\n`));
}

async function delc(conn: Deno.Conn, _: string, __: string) {
  conn.write(encoder.encode(`${delCount}\n`));
}

const listener = Deno.listen({
  port: 8080,
  hostname: "127.0.0.1",
  transport: "tcp",
});

for await (const conn of listener) {
  while (true) {
    const buf = new Uint8Array(1024);
    const read = await conn.read(buf);
    if (read == null) {
      conn.close();
      break;
    }
    const text = decoder.decode(buf.slice(0, read - 1));
    const [cmd, key, val] = text.split(" ");

    const op = ops[cmd];

    if (op) {
      op(conn, key, val);
    } else {
      conn.write(encoder.encode("invalid command\n"));
    }
  }
}
