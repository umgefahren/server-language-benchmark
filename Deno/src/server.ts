import { handlers, startRecurring } from "./handlers.ts";
import { decoder, messages } from "./constants.ts";

const listener = Deno.listen({
  port: 8080,
  hostname: "127.0.0.1",
  transport: "tcp",
});

startRecurring();

for await (const conn of listener) {
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
        conn.write(messages.invalidCommand);
      }
    } catch {
      break;
    }
  }
}
