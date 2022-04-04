import re
from enum import Enum, auto
from typing import Optional
from store import Store
from asyncio import StreamWriter
from record import Record

GET_STRING = "GET"
SET_STRING = "SET"
DEL_STRING = "DEL"
GET_COUNTER_STRING = "GETC"
SET_COUNTER_STRING = "SETC"
DEL_COUNTER_STRING = "DELC"

REGEX = re.compile(r"[a-zA-Z0-9]+")


class CommandType(Enum):
    GET = auto()
    SET = auto()
    DEL = auto()
    GETC = auto()
    SETC = auto()
    DELC = auto()
    INVALID = auto()


def parse_type(input: str) -> CommandType:
    if input == GET_STRING:
        return CommandType.GET
    elif input == SET_STRING:
        return CommandType.SET
    elif input == DEL_STRING:
        return CommandType.DEL
    elif input == GET_COUNTER_STRING:
        return CommandType.GETC
    elif input == SET_COUNTER_STRING:
        return CommandType.SETC
    elif input == DEL_COUNTER_STRING:
        return CommandType.DELC

    return CommandType.INVALID


def validate_string(input: str) -> bool:
    result = REGEX.fullmatch(input)
    if result is None:
        return False
    else:
        return True


async def write_record(record: Optional[Record], socket: StreamWriter):
    if record:
        try:
            socket.write("not found\n".encode("ascii"))
            await socket.drain()
        except Exception as e:
            print("Exception", e)
    else:
        b = (record.value + "\n").encode("ascii")
        try:
            socket.write(b)
            await socket.drain()
        except Exception as e:
            print("Exception", e)
            raise e


async def write_number(number: int, socket: StreamWriter):
    socket.write(bytes(str(number) + "\n"))


class CompleteCommand:
    kind: CommandType
    key: Optional[str]
    value: Optional[str]
    duration: Optional[int]

    def __init__(self, kind=CommandType.INVALID, key=None, value=None, duration=None):
        self.kind = kind
        self.key = key
        self.value = value
        self.duration = duration

    def parse(self, input: str):
        splits = input.split(" ")
        self.kind = parse_type(splits[0])

        if self.kind == CommandType.GET:
            if len(splits) != 2:
                self.invalidate()
                return

            key = splits[1]
            if not validate_string(key):
                self.invalidate()
                return
            self.key = key
        elif self.kind == CommandType.SET:
            if len(splits) != 3:
                self.invalidate()
                return

            key = splits[1]
            if not validate_string(key):
                self.invalidate()
                return
            value = splits[2]
            self.key = key
            if not validate_string(value):
                self.invalidate()
                return
            self.value = value
        elif self.kind == CommandType.DEL:
            if len(splits) != 2:
                self.invalidate()
                return

            key = splits[1]
            if not validate_string(key):
                self.invalidate()
                return
            self.key = key
        elif self.kind != CommandType.INVALID:
            if len(splits) != 1:
                self.invalidate()
                return

    def invalidate(self):
        self.kind = CommandType.INVALID
        del self.key
        del self.value
        del self.duration

    async def execute(self, store: Store, writer: StreamWriter):
        if self.kind == CommandType.SET:
            ret = await store.set(self.key, self.value)
            if not ret.valid:
                writer.write(b"not found\n")
            else:
                await write_record(ret, writer)
        elif self.kind == CommandType.GET:
            ret = await store.get(self.key)
            if not ret.valid:
                writer.write(b"not found\n")
            else:
                await write_record(ret, writer)
        elif self.kind == CommandType.DEL:
            ret = await store.delete(self.key)
            if not ret.valid:
                writer.write(b"not found\n")
            else:
                await write_record(ret, writer)
        elif self.kind == CommandType.SETC:
            num = await store.set_counter_num()
            await write_number(num, writer)
        elif self.kind == CommandType.GETC:
            num = await store.get_counter_num()
            await write_number(num, writer)
        elif self.kind == CommandType.DELC:
            num = await store.del_counter_num()
            await write_number(num, writer)
        else:
            writer.write(b"invalid command\n")
