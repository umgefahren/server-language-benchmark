use std::cell::RefCell;
use std::ops::Deref;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;
use chashmap::CHashMap;
use tokio::sync::{Mutex, RwLock};
use tokio::task::JoinHandle;
use tokio::time::sleep;
use crate::record::Record;

pub(crate) struct Store {
	content: CHashMap<String, Record>,
	get_counter: AtomicU64,
	set_counter: AtomicU64,
	del_counter: AtomicU64,
	dump_content: RwLock<Option<Arc<String>>>,
	dump_interval: Arc<Mutex<RefCell<tokio::time::Duration>>>,
	dumper: Arc<Mutex<Option<JoinHandle<()>>>>,
}

async fn dumping_fun(store: Arc<Store>) {
	let duration = store.dump_interval.clone().lock().await.clone().into_inner();
	loop {
		sleep(duration).await;
		store.new_dump().await;
	}
}

impl Store {
	pub(crate) async fn new() -> Arc<Self> {
		let ret = Self {
			content: CHashMap::new(),
			get_counter: AtomicU64::new(0),
			set_counter: AtomicU64::new(0),
			del_counter: AtomicU64::new(0),
			dump_content: RwLock::new(None),
			dump_interval: Arc::new(Mutex::new(RefCell::new(Duration::from_secs(10)))),
			dumper: Arc::new(Mutex::new(None)),
		};

		let store = Arc::new(ret);
		let ret_store = store.clone();
		let new_dumper = tokio::spawn(async move {
			dumping_fun(store).await
		});
		ret_store.dumper.lock().await.replace(new_dumper);
		ret_store
	}

	pub(crate) fn set(&self, key: String, value: String) -> Option<Record> {
		let new_record = Record::new(key.clone(), value);
		self.set_counter.fetch_add(1, Ordering::Relaxed);
		self.content.insert(key, new_record)
	}

	pub(crate) fn get(&self, key: &str) -> Option<Record> {
		self.content.get(key).map(|e| e.deref().clone())
	}

	pub(crate) fn del(&self, key: &str) -> Option<Record> {
		self.content.remove(key)
	}

	pub(crate) fn get_counter(&self) -> u64 {
		self.get_counter.load(Ordering::Relaxed)
	}

	pub(crate) fn set_counter(&self) -> u64 {
		self.set_counter.load(Ordering::Relaxed)
	}

	pub(crate) fn del_counter(&self) -> u64 {
		self.del_counter.load(Ordering::Relaxed)
	}

	pub(crate) async fn new_dump(&self) -> Arc<String> {
		let mut json_records = Vec::with_capacity(self.content.len());
		self.content.clone().into_iter().for_each(|pair| {
			let record = pair.1;
			let json_record = record.to_json_record();
			json_records.push(json_record);
		});
		let dump_result = serde_json::to_string(&json_records).unwrap();
		let wrapped_dump = Arc::new(dump_result);
		let replace_val = wrapped_dump.clone();
		{
			let mut write_lock = self.dump_content.write().await;
			write_lock.replace(replace_val);
		}
		wrapped_dump
	}

	pub(crate) async fn get_dump(&self) -> Arc<String> {
		let res: Option<Arc<String>> = {
			let r_lock = self.dump_content.read().await;
			if r_lock.is_none() {
				None
			} else {
				let m = r_lock.clone().unwrap();
				Some(m)
			}
		};
		match res {
			None => self.new_dump().await,
			Some(d) => d,
		}
	}

	pub(crate) async fn change_interval(&self, store: Arc<Store>, duration: Duration) {
		let arc = self.dump_interval.clone();
		let guard = arc.lock().await;
		guard.replace(duration.clone());
		let new_dumper = tokio::spawn(async move {
			dumping_fun(store).await
		});
		let mut dumper_guard = self.dumper.lock().await;
		dumper_guard.replace(new_dumper);
	}
}