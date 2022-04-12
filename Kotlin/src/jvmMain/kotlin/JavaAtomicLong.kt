import java.util.concurrent.atomic.AtomicLong

class JavaAtomicLong: AbstractAtomicLong() {
    var value: AtomicLong = AtomicLong(0)
    override suspend fun add(delta: Long) {
        this.value.addAndGet(delta)
    }

    override suspend fun load(): Long {
        return value.get()
    }
}