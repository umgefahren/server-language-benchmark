package xyz.umgefahren;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

public class Handler implements Runnable {
    private final Socket socket;
    private final Store store;

    Handler(Socket socket, Store store) {
        this.socket = socket;
        this.store = store;
    }


    @Override
    public void run() {
        BufferedReader in;
        try {
            in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
        PrintWriter out;
        try {
            out = new PrintWriter(socket.getOutputStream());
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
        try {
            String inLine = in.readLine();
            inLine = inLine.stripTrailing();
            System.out.println("Read Line => " + inLine);
            CompleteCommand command = CommandFactory.parse(inLine);
            if (command == null) {
                out.println("Invalid command");
            } else {
                command.execute(out, store);
            }
            out.flush();
            socket.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
