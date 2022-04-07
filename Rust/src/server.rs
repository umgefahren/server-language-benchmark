use crate::command::CompleteCommand;
use crate::store::Store;
use std::error::Error;
use std::str::FromStr;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader, BufWriter};
use tokio::net::{TcpListener, TcpStream};

pub(crate) async fn server(store: Arc<Store>) -> Result<(), Box<dyn Error>> {
    let listener = TcpListener::bind("127.0.0.1:8080").await?;

    loop {
        let (socket, _) = listener.accept().await?;
        let tmp_store = store.clone();
        tokio::spawn(async move {
            let result = handler(tmp_store, socket).await;
            match result {
                Ok(_) => {}
                Err(e) => {
                    eprintln!("{:?}", e.to_string());
                }
            }
        });
    }
}

pub(crate) async fn handler(
    store: Arc<Store>,
    socket: TcpStream,
) -> Result<(), Box<dyn Error + 'static>> {
    let (owned_reader, owned_writer) = socket.into_split();
    let mut buf_reader = BufReader::new(owned_reader);
    let mut buf_writer = BufWriter::new(owned_writer);
    loop {
        let mut read_line = String::new();
        buf_reader
            .read_line(&mut read_line)
            .await
            .map_err(|e| e.to_string())?;
        let read_line = read_line.trim();

        let command_result = CompleteCommand::from_str(&read_line);
        let command = match command_result {
            Ok(command) => command,
            Err(e) => {
                let write_string = e.to_string() + "\n";
                buf_writer.write_all(write_string.as_bytes()).await?;
                buf_writer.flush().await?;
                return Ok(());
            }
        };

        command.execute(store.clone(), &mut buf_writer).await?;
    }
}
