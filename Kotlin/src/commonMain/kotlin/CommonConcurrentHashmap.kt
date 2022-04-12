import kotlinx.coroutines.sync.*

class CommonConcurrentHashmap<K, V> : ConcurrentHashmapStore<K, V>() {
    var mapMutex: Mutex = Mutex()
    var map: HashMap<K, V> = HashMap()

    override suspend fun get(key: K): V? {
        this.mapMutex.withLock {
            return map[key]
        }
    }

    override suspend fun set(key: K, value: V): V? {
        this.mapMutex.withLock {
            val ret = map[key]
            map[key] = value
            return ret
        }
    }

    override suspend fun del(key: K): V? {
        this.mapMutex.withLock {
            return map.remove(key)
        }
    }
}