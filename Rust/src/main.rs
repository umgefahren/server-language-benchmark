use std::error::Error;
use crate::store::Store;

mod command;
mod store;
mod record;
mod server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>>{
    let store = Store::new().await;
    server::server(store).await?;
    Ok(())
}
