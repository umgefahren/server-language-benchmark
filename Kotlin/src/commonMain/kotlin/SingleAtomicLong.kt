class SingleAtomicLong: AbstractAtomicLong() {
    var value: Long = 0
    override suspend fun add(delta: Long) {
        value += delta
    }

    override suspend fun load(): Long {
        return value
    }
}