package xyz.umgefahren;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class Server {
    public Store store;

    Server(Store store) {
        this.store = store;
    }

    public void run() throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        do {
            Socket socket = serverSocket.accept();
            Thread handler = new Thread(new Handler(socket, this.store));
            try {
                handler.start();
            } catch (IllegalThreadStateException e) {
                e.printStackTrace();
                return;
            }

        } while (true);
    }
}
