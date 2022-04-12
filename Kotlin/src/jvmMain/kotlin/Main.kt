import io.ktor.network.selector.*
import io.ktor.network.sockets.*
import io.ktor.utils.io.*
import kotlinx.coroutines.*

fun main(args: Array<String>) {
    val commandParser = CommandParser()


    runBlocking {
        val store = Store<JavaConcurrentHashmap<String, Record>, JavaAtomicLong>(JavaConcurrentHashmap(), JavaAtomicLong(), JavaAtomicLong(), JavaAtomicLong())
        val selectorManager = ActorSelectorManager(Dispatchers.IO)
        val serverSocket = aSocket(selectorManager).tcp().bind("127.0.0.1", 8080)
        println("Server is listening at ${serverSocket.localAddress}")
        while (true) {
            val socket = serverSocket.accept()
            launch {
                val receiveChannel = socket.openReadChannel()
                val sendChannel = socket.openWriteChannel(autoFlush = true)
                try {
                    while (true) {
                        val clientLine = receiveChannel.readUTF8Line()
                        if (clientLine != null) {
                            val command = commandParser.parseCommand(clientLine)
                            val out = store.executeCommand(command)
                            sendChannel.writeStringUtf8(out + "\n")
                        }
                    }
                } catch (e: Throwable) {
                    socket.close()
                }
            }
        }
    }
}