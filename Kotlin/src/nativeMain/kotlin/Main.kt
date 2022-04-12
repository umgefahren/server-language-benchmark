import io.ktor.network.selector.*
import io.ktor.network.sockets.*
import io.ktor.utils.io.*
import kotlinx.coroutines.*

fun main(args: Array<String>) {
    println("Hello World")
    runBlocking {
        println("Hello world 2")
        val manager = SelectorManager(Dispatchers.Main)

        // val manager = SelectorManager()
        /*
        val serverSocket = aSocket(manager).tcp().bind("localhost", 8080)
        println("Server is listening at ${serverSocket.localAddress}")
        while (true) {
            val socket = serverSocket.accept()
        }

         */
    }
}