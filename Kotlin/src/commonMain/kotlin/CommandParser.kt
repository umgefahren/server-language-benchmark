import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.toDuration

class CommandParser {
    private val keyValidatorSet: Set<Char>

    init {
        val alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

        val set = HashSet<Char>()

        alphanumeric.forEach {
            set.add(it)
        }

        keyValidatorSet = set
    }

    private fun validKeyString(input: String): Boolean {
        input.forEach {
            if (!keyValidatorSet.contains(it)) {
                return false
            }
        }

        return true
    }

    private fun parseDuration(input: String): Duration? {
        if (input.length > 11) {
            return null
        }

        var potString = input.slice(0..1)
        val hours = potString.toUIntOrNull() ?: return null
        if (hours > 99u) {
            return null
        }
        if (input.slice(2..3) != "h-") {
            return null
        }

        potString = input.slice(4..5)
        val minutes = potString.toUIntOrNull() ?: return null
        if (minutes > 99u) {
            return null
        }
        if (input.slice(6..7) != "m-") {
            return null
        }

        potString = input.slice(8..9)
        val seconds = potString.toUIntOrNull() ?: return null
        if (seconds > 99u) {
            return null
        }

        val trailingString = input.slice(10..11)
        if (trailingString != "s") {
            return null
        }

        var ret = seconds.toInt().toDuration(DurationUnit.SECONDS)
        ret += minutes.toInt().toDuration(DurationUnit.MINUTES)
        ret += hours.toInt().toDuration(DurationUnit.HOURS)
        return ret
    }

    fun parseCommand(input: String): Command? {
        val splits = input.split(' ')

        val commandTypeString = splits[0]

        val commandType = StringToCommandType(commandTypeString) ?: return null

        var keyString: String? = null
        var valueString: String? = null

        when (splits.size) {
            1 -> {
                if (!(commandType == CommandType.SetCounter || commandType == CommandType.GetCounter || commandType == CommandType.DelCounter)) {
                    return null
                }
            }
            2 -> {
                if (!(commandType == CommandType.Get || commandType == CommandType.Del)) {
                    return null
                }
                if (!validKeyString(splits[1])) {
                    return null
                }
                keyString = splits[1]
            }
            3 -> {
                if (commandType != CommandType.Set) {
                    return null
                }
                if (!validKeyString(splits[1])) {
                    return null
                }
                if (!validKeyString(splits[2])) {
                    return null
                }
                keyString = splits[1]
                valueString = splits[2]
            }
        }

        return Command(commandType, keyString, valueString)
    }
}