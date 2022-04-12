const val SetString = "SET"
const val GetString = "GET"
const val DelString = "DEL"
const val SetCounterString = "SETC"
const val GetCounterString = "GETC"
const val DelCounterString = "DELC"

fun StringToCommandType(input: String): CommandType? {
    return when (input) {
        SetString -> CommandType.Set
        GetString -> CommandType.Get
        DelString -> CommandType.Del
        SetCounterString -> CommandType.SetCounter
        GetCounterString -> CommandType.GetCounter
        DelCounterString -> CommandType.DelCounter
        else -> null
    }
}

fun CommandTypeToString(input: CommandType?): String {
    if (input == null) {
        return "invalid command"
    }

    return when (input) {
        CommandType.Set -> SetString
        CommandType.Get -> GetString
        CommandType.Del -> DelString
        CommandType.SetCounter -> SetCounterString
        CommandType.GetCounter -> GetCounterString
        CommandType.DelCounter -> DelCounterString
        CommandType.Invalid -> "invalid command"
    }
}

enum class CommandType {
    Set,
    Get,
    Del,
    SetCounter,
    GetCounter,
    DelCounter,
    Invalid
}
