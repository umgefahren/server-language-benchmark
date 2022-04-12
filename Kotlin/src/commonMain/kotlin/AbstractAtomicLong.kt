abstract class AbstractAtomicLong() {
    abstract suspend fun add(delta: Long)
    abstract suspend fun load(): Long
}