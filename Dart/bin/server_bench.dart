import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';


void main() async {
  // bind the socket server to an address and port
  InternetAddress? addr = InternetAddress.tryParse("0.0.0.0");
  final server = await ServerSocket.bind(addr, 8080);
  HashMap<String, String> map = HashMap();
  AtomicInt getc = AtomicInt();
  AtomicInt setc = AtomicInt();

  // listen for client connections to the server
  server.listen((client) {
    handleConnection(client, map, getc, setc);
  });
}

void handleConnection(Socket client, HashMap<String, String> map, AtomicInt getc, AtomicInt setc) {
  // listen for events from the client
  client.listen(

    // handle data from the client
    (Uint8List data) async {
      final messageArr = String.fromCharCodes(data).trim().split(' ');
      if (messageArr[0] == "GETC") {
        client.write(getc.number.toString() + "\n");
      } else if (messageArr[0] == "SETC") {
        client.write(setc.number.toString() + "\n");
      }
      else if (messageArr[0] == "GET") {
        String? val = map[messageArr[1]];
        if (messageArr.length != 2) {
          client.write("invalid command\n");
        }
        else if (val == null) {
          getc.number++;
          client.write("not found\n");
        } else {
          getc.number++;
          client.write(val + "\n");
        }
      } else if (messageArr[0] == "SET") {
        if (messageArr.length != 3) {
          client.write("invalid command\n");
        } else {
          setc.number++;
          map[messageArr[1]] =  messageArr[2];
          client.write(messageArr[2] + "\n");
        }
      } else {
        client.write("invalid command\n");
      }
    },

    // handle errors
    onError: (error) {
      print(error);
      client.close();
    },

    // handle the client closing the connection
    onDone: () {
      client.close();
    },
  );
}

class AtomicInt {
  int number = 0;
}

