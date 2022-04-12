class Store<CHM: ConcurrentHashmapStore<String, Record>, A: AbstractAtomicLong>(
    private val map: CHM,
    private val getCounter: A,
    private val setCounter: A,
    private val delCounter: A
) {
    private suspend fun set(key: String, value: String): String? {
        val record = Record(key, value)
        setCounter.add(1)
        return map.set(key, record)?.value
    }

    private suspend fun get(key: String): String? {
        getCounter.add(1)
        return map.get(key)?.value
    }

    private suspend fun del(key: String): String? {
        delCounter.add(1)
        return map.del(key)?.value
    }

    private suspend fun getCounter(): Long {
        return getCounter.load()
    }

    private suspend fun setCounter(): Long {
        return setCounter.load()
    }

    private suspend fun delCounter(): Long {
        return delCounter.load()
    }

    private fun resultToString(input: String?): String {
        if (input == null) {
            return "not found"
        }
        return input
    }

    private fun longToString(input: Long): String {
        return "$input"
    }

    suspend fun executeCommand(command: Command?): String {
        if (command == null) {
            return "invalid command"
        }

        return when (command.type) {
            CommandType.Set -> {
                resultToString(set(command.key!!, command.value!!))
            }
            CommandType.Get -> {
                resultToString(get(command.key!!))
            }
            CommandType.Del -> {
                resultToString(del(command.key!!))
            }
            CommandType.SetCounter -> {
                longToString(setCounter())
            }
            CommandType.GetCounter -> {
                longToString(getCounter())
            }
            CommandType.DelCounter -> {
                longToString(delCounter())
            }
            CommandType.Invalid -> {
                "invalid command"
            }
        }
    }
}