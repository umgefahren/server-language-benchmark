import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class MultiAtomicLong: AbstractAtomicLong() {
    var value: Long = 0
    var mutex = Mutex()
    override suspend fun add(delta: Long) {
        mutex.withLock { value += 1 }
    }

    override suspend fun load(): Long {
        mutex.withLock { return value }
    }

}