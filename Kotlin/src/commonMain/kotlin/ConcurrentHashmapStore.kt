abstract class ConcurrentHashmapStore<K, V>() {
    abstract suspend fun get(key: K): V?
    abstract suspend fun set(key: K, value: V): V?
    abstract suspend fun del(key: K): V?
}