import kotlin.time.Duration

class Command(
    val type: CommandType = CommandType.Invalid,
    var key: String? = null,
    var value: String? = null,
    var duration: Duration? = null
) {

}