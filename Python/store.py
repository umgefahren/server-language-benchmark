import asyncio
from typing import Dict, Optional

from record import Record


class Store:
    content: Dict[str, Record]
    content_lock: asyncio.Lock
    get_counter: int
    get_counter_lock: asyncio.Lock
    set_counter: int
    set_counter_lock: asyncio.Lock
    del_counter: int
    del_counter_lock: asyncio.Lock

    def __init__(self):
        self.content = {}
        self.content_lock = asyncio.Lock()
        self.get_counter = 0
        self.get_counter_lock = asyncio.Lock()
        self.set_counter = 0
        self.set_counter_lock = asyncio.Lock()
        self.del_counter = 0
        self.del_counter_lock = asyncio.Lock()

    async def set(self, key: str, value: str) -> Optional[Record]:
        record = Record(key, value)
        await self.content_lock.acquire()
        ret = Record()
        ret.invalidate()
        if key in self.content:
            ret = self.content[key]
        self.content[key] = record
        self.content_lock.release()
        await self.set_counter_lock.acquire()
        self.set_counter += 1
        self.set_counter_lock.release()
        return ret

    async def get(self, key: str) -> Optional[Record]:
        await self.content_lock.acquire()
        ret = Record()
        ret.invalidate()
        if key in self.content:
            ret = self.content[key]
        self.content_lock.release()
        await self.get_counter_lock.acquire()
        self.get_counter += 1
        self.get_counter_lock.release()
        return ret

    async def delete(self, key: str) -> Optional[Record]:
        await self.content_lock.acquire()
        ret = Record()
        ret.invalidate()
        if key in self.content:
            ret = self.content[key]
        del self.content[key]
        self.content_lock.release()
        await self.del_counter_lock.acquire()
        self.del_counter += 1
        self.del_counter_lock.release()
        return ret

    async def set_counter_num(self) -> int:
        await self.set_counter_lock.acquire()
        ret = self.set_counter
        self.set_counter_lock.release()
        return ret

    async def get_counter_num(self):
        await self.get_counter_lock.acquire()
        ret = self.get_counter
        self.get_counter_lock.release()
        return ret

    async def del_counter_num(self):
        await self.del_counter_lock.acquire()
        ret = self.del_counter
        self.del_counter_lock.release()
        return ret
