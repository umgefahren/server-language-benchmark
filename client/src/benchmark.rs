use crate::{idle_till_server_connection, CompleteCommand, BENCH_COUNT, CONCURRENT_CONNS};
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::str::FromStr;
use std::sync::Arc;
use tokio::fs::File;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpStream, ToSocketAddrs};
use tokio::sync::Mutex;
use tokio::time::Instant;

fn generate_string() -> String {
    thread_rng()
        .sample_iter(&Alphanumeric)
        .take(30)
        .map(char::from)
        .collect()
}

async fn perform_sequence<A: ToSocketAddrs>(
    addr: A,
    key: String,
    value: String,
    conn_mutex: Arc<Mutex<()>>,
    start: Arc<Instant>,
) -> StandardSequenceDuration {
    let set_command = CompleteCommand::Set {
        key: key.clone(),
        value: value.clone(),
    };

    // println!("Key => {:?} Value => {:?}", key, value);

    let set_string = String::from(set_command) + "\n";
    let get_command = CompleteCommand::Get { key: key.clone() };
    let get_string = String::from(get_command) + "\n";
    let del_command = CompleteCommand::Del { key: key.clone() };
    let del_string = String::from(del_command) + "\n";

    let m = conn_mutex.lock().await;

    let start_duration = start.elapsed();
    let total_instant = Instant::now();

    let mut socket = TcpStream::connect(addr).await.unwrap();
    let (owned_reader, mut owned_writer) = socket.split();
    let mut buf_reader = BufReader::new(owned_reader);

    let mut out_buf = String::new();

    let set_instant = Instant::now();
    owned_writer.write_all(set_string.as_bytes()).await.unwrap();
    owned_writer.flush().await.unwrap();
    buf_reader.read_line(&mut out_buf).await.unwrap();
    let set_duration = set_instant.elapsed();

    assert_eq!(out_buf, "not found\n");
    out_buf.clear();

    let get0_instant = Instant::now();
    owned_writer.write_all(get_string.as_bytes()).await.unwrap();
    owned_writer.flush().await.unwrap();
    buf_reader.read_line(&mut out_buf).await.unwrap();
    let get0_duration = get0_instant.elapsed();
    while strip(out_buf.clone()) == "" {
        buf_reader.read_line(&mut out_buf).await.unwrap();
    }

    assert_eq!(strip(out_buf.clone()), value);
    out_buf.clear();

    let get1_instant = Instant::now();
    owned_writer.write_all(get_string.as_bytes()).await.unwrap();
    owned_writer.flush().await.unwrap();
    buf_reader.read_line(&mut out_buf).await.unwrap();

    let get1_duration = get1_instant.elapsed();
    assert_eq!(strip(out_buf.clone()), value);
    out_buf.clear();

    let get2_instant = Instant::now();
    owned_writer.write_all(get_string.as_bytes()).await.unwrap();
    owned_writer.flush().await.unwrap();
    buf_reader.read_line(&mut out_buf).await.unwrap();
    let get2_duration = get2_instant.elapsed();

    assert_eq!(strip(out_buf.clone()), value);
    out_buf.clear();

    let del_instant = Instant::now();
    owned_writer.write_all(del_string.as_bytes()).await.unwrap();
    owned_writer.flush().await.unwrap();
    buf_reader.read_line(&mut out_buf).await.unwrap();

    let del_duration = del_instant.elapsed();
    let total_duration = total_instant.elapsed();
    assert_eq!(strip(out_buf.clone()), value);
    out_buf.clear();

    drop(socket);
    std::mem::drop(m);

    StandardSequenceDuration {
        start: start_duration,
        total: total_duration,
        set: set_duration,
        get0: get0_duration,
        get1: get1_duration,
        get2: get2_duration,
        del: del_duration,
    }
}

fn strip(input: String) -> String {
    let mut ret = input.trim().to_string();
    ret = ret.replace(" ", "");
    ret = ret.replace("\t", "");
    ret.replace("\n", "")
}

pub async fn generate_data() {
    let mut first_names = HashSet::new();
    let mut last_names = HashSet::new();
    let mut file = tokio::fs::File::create("data.txt").await.unwrap();
    file.write_all(format!("{:?}\n", BENCH_COUNT).as_bytes())
        .await
        .unwrap();
    for _ in 0..BENCH_COUNT {
        let first_name = loop {
            let mut first_name = generate_string();
            first_name = strip(first_name.clone());
            if !first_names.contains(&first_name) {
                first_names.insert(first_name.clone());
                break first_name;
            }
        };
        let last_name = loop {
            let mut last_name = generate_string();
            last_name = strip(last_name.clone());
            if !last_names.contains(&last_name) {
                last_names.insert(last_name.clone());
                break last_name;
            }
        };
        let line = first_name + " " + &last_name + "\n";
        file.write_all(line.as_bytes()).await.unwrap();
    }
    file.flush().await.unwrap();
}

pub async fn perform_benchmark() {
    let file = tokio::fs::File::open("data.txt").await.unwrap();
    let mut reader = BufReader::new(file);
    let mut string_buf = String::new();
    reader.read_line(&mut string_buf).await.unwrap();
    string_buf = strip(string_buf);
    let count = usize::from_str(&string_buf).unwrap();
    string_buf.clear();
    let mut entries = Vec::with_capacity(count);

    let connection_mutexes = vec![Arc::new(Mutex::new(())); CONCURRENT_CONNS];

    for _ in 0..count {
        reader.read_line(&mut string_buf).await.unwrap();
        let mut splits = string_buf.split(" ");
        let pre = splits.next().unwrap().to_string();
        let mut last = splits.next().unwrap().to_string();
        last = strip(last);
        let tup = (pre, last);

        entries.push(tup);
        string_buf.clear();
    }
    let start = Instant::now();
    let start_wrapper = Arc::new(start);

    let mut up = 0;
    let mut handlers = Vec::with_capacity(count);
    let addr = "127.0.0.1:8080";
    idle_till_server_connection(addr).await;
    for e in entries {
        let key = e.0;
        let value = e.1;
        // std::thread::sleep(std::time::Duration::from_millis(1));
        if up % 1000 == 0 {
            println!("{}", up);
        }
        up += 1;
        let conn_num = up % CONCURRENT_CONNS;
        let ass_conn_mutex = connection_mutexes.get(conn_num).unwrap().clone();
        let new_wrapper = start_wrapper.clone();
        let handler = tokio::spawn(async move {
            // sleep(core::time::Duration::from_millis(100)).await;
            perform_sequence(addr, key, value, ass_conn_mutex, new_wrapper).await
        });
        handlers.push(handler);
    }

    println!("submitted all");

    let mut durations: Vec<StandardSequenceDuration> = Vec::with_capacity(count);

    for num in 0..handlers.len() {
        // println!("num => {} to {}", num, handlers.len());
        if num == handlers.len() - 1 {
            continue;
        }
        let handler = handlers.get_mut(num).unwrap();
        // println!("Handler => {:?}", handler);
        let duration = handler.await.unwrap();
        durations.push(duration);
    }

    let mut out_file = File::create("bench.txt").await.unwrap();

    for duration in durations {
        let json_string = serde_json::to_string(&duration).unwrap() + "\n";
        out_file.write_all(json_string.as_bytes()).await.unwrap();
        // println!("Duration => {:?}", duration);
    }

    out_file.flush().await.unwrap();
}

#[derive(Debug, Serialize, Deserialize)]
struct StandardSequenceDuration {
    start: core::time::Duration,
    total: core::time::Duration,
    set: core::time::Duration,
    get0: core::time::Duration,
    get1: core::time::Duration,
    get2: core::time::Duration,
    del: core::time::Duration,
}
