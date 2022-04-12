import java.util.concurrent.ConcurrentHashMap

class JavaConcurrentHashmap<K : Any, V>: ConcurrentHashmapStore<K, V>() {
    private val internal = ConcurrentHashMap<K, V>()

    override suspend fun get(key: K): V? {
        return internal[key]
    }

    override suspend fun set(key: K, value: V): V? {
        val ret = internal[key]
        internal[key] = value
        return ret
    }

    override suspend fun del(key: K): V? {
        return internal.remove(key)
    }
}