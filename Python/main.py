import asyncio
import traceback
from asyncio import StreamReader, StreamWriter, start_server
from store import Store
from command import CompleteCommand


def handler(store: Store):
    async def handling_function(reader: StreamReader, writer: StreamWriter):
        while True:
            try:
                line_bytes = await reader.readline()

                if line_bytes == b'':
                    break
                line_string = str(line_bytes, 'utf-8')
                line = line_string.strip()

                command = CompleteCommand()
                command.parse(line)
                await command.execute(store, writer)
                await writer.drain()
            except Exception as _:
                break

    return handling_function


async def main():
    store = Store()
    server = await start_server(handler(store), host="localhost", port=8080)
    async with server:
        await server.serve_forever()

asyncio.run(main())
