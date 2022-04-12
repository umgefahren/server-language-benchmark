import kotlin.native.concurrent.AtomicLong

class NativeAtomicLong: AbstractAtomicLong() {
    var value: AtomicLong = AtomicLong(0)
    override suspend fun add(delta: Long) {
        value.addAndGet(delta)
    }

    override suspend fun load(): Long {
        return value.value
    }
}