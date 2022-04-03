package xyz.umgefahren;

import java.io.IOException;

public class Main {

    public static void main(String[] args) throws IOException {
        Store store = new Store();
        Server server = new Server(store);
        server.run();
    }
}
