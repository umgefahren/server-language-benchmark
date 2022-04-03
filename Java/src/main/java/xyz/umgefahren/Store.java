package xyz.umgefahren;

import java.time.Duration;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.json.*;

public class Store {
    public static class DumpThread implements Runnable {
        private final Store store;

        DumpThread(Store store) {
            this.store = store;
        }

        @Override
        public void run() {
            while (true) {
                try {
                    Thread.sleep(store.dump_delta.toMillis());
                    store.newDump();
                } catch (InterruptedException e) {
                    return;
                }
            }
        }
    }

    public static class DeleteThread implements Runnable {
        private final Store store;
        private final String key;
        private final Duration delay;

        DeleteThread(Store store, String key, Duration delay) {
            this.store = store;
            this.key = key;
            this.delay = delay;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(delay.toMillis());
            } catch (InterruptedException e) {
                return;
            }
            store.Del(key);
        }
    }

    private final ConcurrentHashMap<String, Record> content = new ConcurrentHashMap<>();
    private final AtomicLong get_counter = new AtomicLong(0);
    private final AtomicLong set_counter = new AtomicLong(0);
    private final AtomicLong del_counter = new AtomicLong(0);

    private String dump_string = "[]";
    private final ReadWriteLock dump_mutex = new ReentrantReadWriteLock();
    private Duration dump_delta = Duration.ofSeconds(10);
    private Thread dump_thread;

    Store() {
        Calendar.getInstance();
        dump_thread = newDumpThread(this);
    }

    public Record Set(String key, String value) {
        Record record = new Record(key, value);
        Record old_record = content.put(key, record);
        set_counter.addAndGet(1);
        return old_record;
    }

    public Record Get(String key) {
        Record record = this.content.get(key);
        get_counter.addAndGet(1);
        return record;
    }

    public Record Del(String key) {
        Record old_record = content.remove(key);
        del_counter.addAndGet(1);
        return old_record;
    }

    public long GetCounter() {
        return get_counter.get();
    }

    public long SetCounter() {
        return set_counter.get();
    }

    public long DelCounter() {
        return del_counter.get();
    }

    public String newDump() {
        JSONArray jsonArray = new JSONArray();
        Collection<Record> recordCollection = content.values();
        for (Record record : recordCollection) {
            JSONObject super_object = new JSONObject();
            super_object = super_object.put("key", record.getKey());
            JSONObject sub_object = new JSONObject();
            sub_object = sub_object.put("value", record.getValue());
            Date timestamp = record.getTimestamp().getTime();
            String timestampString = timestamp.toString();
            sub_object = sub_object.put("timestamp", timestampString);
            super_object = super_object.put("associated_value", sub_object);
            jsonArray = jsonArray.put(super_object);
        }
        String dumpString = jsonArray.toString();
        Lock lock = dump_mutex.writeLock();
        lock.lock();
        this.dump_string = dumpString;
        lock.unlock();
        return dumpString;
    }

    public String getDump() {
        Lock lock = dump_mutex.readLock();
        lock.lock();
        String ret_string = dump_string;
        lock.unlock();
        return ret_string;
    }

    public void ChangeInterval(Duration new_interval) {
        Lock lock = dump_mutex.writeLock();
        lock.lock();
        dump_delta = new_interval;
        dump_thread.interrupt();
        dump_thread = newDumpThread(this);
        lock.unlock();
        newDump();
    }

    public static Thread newDumpThread(Store store) {
        Thread newThread =  new Thread(new DumpThread(store));
        newThread.start();
        return newThread;
    }

    public void SetTTL(String key, Duration duration) {
        Thread thread = new Thread(new DeleteThread(this, key, duration));
        thread.start();
    }
}
