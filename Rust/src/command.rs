use std::error::Error;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncWrite, AsyncWriteExt};
use lazy_static::lazy_static;
use regex::{Captures, Regex};
use tokio::time::sleep;
use crate::record::Record;
use crate::store::Store;

const INVALID_COMMAND_STRING: &'static str = "invalid command";
const INVALID_COMMAND_ERR: Result<CompleteCommand, &str> = Err("invalid command");
const INVALID_COMMAND_TIME_ERR: Result<Duration, &str> = Err("invalid command");

const NOT_FOUND_STRING: &'static str = "not found\n";

#[inline]
fn validate_string(input: &str) -> Result<(), &'static str> {
	lazy_static! {
		static ref RE: Regex = Regex::new("[a-zA-Z0-9]+").unwrap();
	}
	if RE.is_match(input) {
		Ok(())
	} else {
		Err("invalid command")
	}
}

#[inline]
fn parse_duration(input: &str) -> Result<Duration, &'static str> {
	lazy_static! {
		static ref RE: Regex = Regex::new("([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9])s").unwrap();
	}
	let cap_option: Option<Captures> = RE.captures(input);
	let captures = cap_option.ok_or(INVALID_COMMAND_STRING)?;
	if captures.len() != 4 {
		return INVALID_COMMAND_TIME_ERR;
	}
	let hours_string = captures.get(1).unwrap().as_str();
	let hours = u64::from_str(hours_string).map_err(|_| INVALID_COMMAND_STRING)?;
	let minutes_string = captures.get(2).unwrap().as_str();
	let minutes = u64::from_str(minutes_string).map_err(|_| INVALID_COMMAND_STRING)?;
	let seconds_string = captures.get(3).unwrap().as_str();
	let mut seconds = u64::from_str(seconds_string).map_err(|_| INVALID_COMMAND_STRING)?;
	seconds += minutes * 60;
	seconds += hours * 60 * 60;
	Ok(Duration::from_secs(seconds))
}

#[derive(Debug)]
pub(crate) enum CompleteCommand {
	Get {
		key: String
	},
	Set {
		key: String,
		value: String
	},
	Del {
		key: String
	},
	GetCounter,
	SetCounter,
	DelCounter,
	GetDump,
	NewDump,
	DumpInterval {
		duration: Duration
	},
	SetTTL {
		key: String,
		value: String,
		ttl: Duration,
	}
}

impl FromStr for CompleteCommand {
	type Err = &'static str;

	fn from_str(s: &str) -> Result<Self, Self::Err> {
		// println!("command => {:?}", s);
		let splits: Vec<&str> = s.split(' ').collect();
		let command = match splits.get(0).ok_or("invalid command")?.to_owned() {
			"GET" => {
				if splits.len() != 2 {
					return INVALID_COMMAND_ERR;
				}
				let key = splits.get(1).ok_or("invalid command")?.to_owned();
				validate_string(key)?;
				CompleteCommand::Get {
					key: key.to_string(),
				}
			},
			"SET" => {
				if splits.len() != 3 {
					return INVALID_COMMAND_ERR
				}
				let key = splits.get(1).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				validate_string(key)?;
				let value = splits.get(2).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				validate_string(value)?;
				CompleteCommand::Set {
					key: key.to_string(),
					value: value.to_string()
				}
			},
			"DEL" => {
				if splits.len() != 2 {
					return INVALID_COMMAND_ERR
				}
				let key = splits.get(1).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				validate_string(key)?;
				CompleteCommand::Del {
					key: key.to_string()
				}
			},
			"GETC" => {
				if splits.len() != 1 {
					return INVALID_COMMAND_ERR
				}
				CompleteCommand::GetCounter
			},
			"SETC" => {
				if splits.len() != 1 {
					return INVALID_COMMAND_ERR
				}
				CompleteCommand::SetCounter
			},
			"DELC" => {
				if splits.len() != 1 {
					return INVALID_COMMAND_ERR
				}
				CompleteCommand::DelCounter
			},
			"GETDUMP" => {
				if splits.len() != 1 {
					return INVALID_COMMAND_ERR
				}
				CompleteCommand::GetDump
			},
			"NEWDUMP" => {
				if splits.len() != 1 {
					return INVALID_COMMAND_ERR
				}
				CompleteCommand::NewDump
			},
			"DUMPINTERVAL" => {

				if splits.len() != 2 {
					return INVALID_COMMAND_ERR
				}

				let duration_string = splits.get(1).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				let duration = parse_duration(duration_string)?;

				CompleteCommand::DumpInterval {
					duration
				}
			},
			"SETTTL" => {
				if splits.len() != 4 {
					return INVALID_COMMAND_ERR
				}
				let key = splits.get(1).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				validate_string(key)?;
				let value = splits.get(2).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				validate_string(value)?;
				let duration_string = splits.get(3).ok_or(INVALID_COMMAND_STRING)?.to_owned();
				let duration = parse_duration(duration_string)?;
				CompleteCommand::SetTTL {
					key: key.to_string(),
					value: value.to_string(),
					ttl: duration
				}
			},
			_ => {
				return INVALID_COMMAND_ERR;
			}
		};
		Ok(command)
	}
}

#[inline]
pub(crate) async fn write_record_opt<T: AsyncWrite + std::marker::Unpin>(record_opt: Option<Record>, mut writer: T) -> Result<(), Box<dyn Error>> {
	match record_opt {
		Some(record) => {
			record.write(writer).await?;
		},
		None => {
			// println!("Writing {:?}", NOT_FOUND_STRING);
			writer.write_all((NOT_FOUND_STRING.to_owned() + "\n").as_bytes()).await?;
			writer.flush().await?;
		}
	}
	Ok(())
}

pub(crate) async fn write_counter<T: AsyncWrite + std::marker::Unpin>(num: u64, mut writer: T) -> Result<(), Box<dyn Error>> {
	let write_string = format!("{}\n", num);
	writer.write_all(write_string.as_bytes()).await?;
	writer.flush().await?;
	Ok(())
}

pub(crate) async fn write_dump<T: AsyncWrite + std::marker::Unpin>(dump: Arc<String>, mut writer: T) -> Result<(), Box<dyn Error>> {
	let write_string = format!("{}\n", dump.as_str());
	writer.write_all(write_string.as_bytes()).await?;
	writer.flush().await?;
	Ok(())
}

impl CompleteCommand {
	pub(crate) async fn execute<T: AsyncWrite + std::marker::Unpin>(&self, store: Arc<Store>, mut writer: T) -> Result<(), Box<dyn Error>> {
		match self {
			CompleteCommand::Get { key } => {
				let record_opt = store.get(key);
				write_record_opt(record_opt, writer).await?;
			}
			CompleteCommand::Set { key, value } => {
				let record_opt = store.set(key.to_string(), value.to_string());
				write_record_opt(record_opt, writer).await?;
			}
			CompleteCommand::Del { key } => {
				let record_opt = store.del(key);

				write_record_opt(record_opt, writer).await?;
			}
			CompleteCommand::GetCounter => {
				let num = store.get_counter();
				write_counter(num, writer).await?;
			}
			CompleteCommand::SetCounter => {
				let num = store.set_counter();
				write_counter(num, writer).await?;
			}
			CompleteCommand::DelCounter => {
				let num = store.del_counter();
				write_counter(num, writer).await?;
			}
			CompleteCommand::GetDump => {
				let dump = store.get_dump().await;
				write_dump(dump, writer).await?;
			}
			CompleteCommand::NewDump => {
				let dump = store.new_dump().await;
				write_dump(dump, writer).await?;
			}
			CompleteCommand::DumpInterval { duration } => {
				let inner_store = store.clone();
				store.change_interval(inner_store, duration.clone()).await;
				writer.write_all("changed interval\n".as_bytes()).await?;
				writer.flush().await?;
			}
			CompleteCommand::SetTTL { key, value, ttl } => {
				let delete_store = store.clone();
				let ret_record = store.set(key.to_string(), value.to_string());
				write_record_opt(ret_record, writer).await?;
				let inner_duration = ttl.clone();
				let inner_key = key.to_string();
				tokio::spawn(async move {
					sleep(inner_duration).await;
					delete_store.del(&inner_key);
					println!("Deleted delayed");
				});
			}
		}
		Ok(())
	}
}