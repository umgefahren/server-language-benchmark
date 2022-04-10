import { handlers, startRecurring } from "./handlers.ts";
import { decoder, messages } from "./constants.ts";

async function handleConn(conn: Deno.Conn) {
  const buf = new Uint8Array(1024);
  while (true) {
    try {
      const read = await conn.read(buf);
      if (read == null) {
        conn.close();
        break;
      }
      const text = decoder.decode(buf.subarray(0, read - 1));
      const [cmd, key, val, duration] = text.split(" ");

      const handler = handlers[cmd];

      if (handler) {
        await handler({ conn, key, val, duration });
      } else {
        await conn.write(messages.invalidCommand);
      }
    } catch {
      break;
    }
  }
}

export async function start() {
  const listener = Deno.listen({
    port: 8080,
    transport: "tcp",
  });

  startRecurring();

  for await (const conn of listener) {
    handleConn(conn);
  }
}
