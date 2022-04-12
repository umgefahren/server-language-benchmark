import net.createServer

fun main() {
    createServer {  }
    println(greeting("js"))
}

fun greeting(name: String) =
    "Hello, $name"