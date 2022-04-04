use std::error::Error;
use tokio::io::{AsyncWrite, AsyncWriteExt};
use tokio::time::Instant;
use serde::Serialize;

#[derive(Clone)]
pub(crate) struct Record {
	key: String,
	value: String,
	timestamp: Instant
}

impl Record {
	#[inline]
	pub fn new(key: String, value: String) -> Record {
		let timestamp = Instant::now();
		Record {
			key: key.to_string(),
			value,
			timestamp
		}
	}

	#[inline]
	pub async fn write<T: AsyncWrite + std::marker::Unpin>(&self, mut writer: T) -> Result<(), Box<dyn Error>> {
		let value_string = self.value.clone() + "\n";
		writer.write_all(value_string.as_bytes()).await?;
		writer.flush().await?;
		Ok(())
	}

	#[inline]
	pub fn to_json_record(&self) -> JsonRecord {
		let sub_record = SubRecord {
			value: self.value.clone(),
			timestamp: self.timestamp.clone().into_std(),
		};
		JsonRecord {
			key: self.key.clone(),
			value: sub_record,
		}
	}
}

#[derive(Serialize)]
pub(crate) struct JsonRecord {
	#[serde(rename = "key")]
	key: String,
	#[serde(rename = "associated_value")]
	value: SubRecord,
}

#[derive(Serialize)]
pub(crate) struct SubRecord {
	#[serde(rename = "value")]
	value: String,
	#[serde(rename = "timestamp")]
	#[serde(with = "serde_millis")]
	timestamp: std::time::Instant,
}