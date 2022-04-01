use tokio::net::TcpStream;
use tokio::io::{AsyncWriteExt, AsyncReadExt, AsyncBufRead, AsyncBufReadExt, BufReader, BufWriter};

#[tokio::main]
async fn main() {
    let socket = TcpStream::connect("127.0.0.1:8080").await.expect("Error during connection");
    let (socket_read, socket_write) = socket.into_split();
    let (mut stream_read, mut stream_write) = (BufReader::new(socket_read), BufWriter::new(socket_write));
    loop {
        println!("Enter input => ");
        let mut input = String::new();
        std::io::stdin().read_line(&mut input).expect("Error during read");
        println!("Writing => {:?}", input);
        stream_write.write_all((input).as_bytes()).await.expect("Error during connection write");
        stream_write.flush().await.unwrap();
        println!("Starting to read");
        let mut back = String::new();
        stream_read.read_line(&mut back).await.expect("Error");
        println!("=> {:?}", back);
    }
}
