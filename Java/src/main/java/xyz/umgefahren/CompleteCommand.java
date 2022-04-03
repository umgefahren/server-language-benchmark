package xyz.umgefahren;

import java.io.PrintWriter;
import java.time.Duration;

public class CompleteCommand {
    public CommandType type = CommandType.Invalid;
    public String key = null;
    public String value = null;
    public Duration duration = null;

    public static void writeRecord(PrintWriter out, Record record) {
        if (record == null) {
            out.println("not found");
        } else {
            out.println(record.getValue());
        }
    }

    public static void writeCounter(PrintWriter out, long number) {
        out.println(number);
    }

    public void execute(PrintWriter out, Store store) {
        switch (type) {

            case Get -> {
                Record ret_record = store.Get(key);
                writeRecord(out, ret_record);
            }
            case Set -> {
                Record ret_record = store.Set(key, value);
                writeRecord(out, ret_record);
            }
            case Del -> {
                Record ret_record = store.Del(key);
                writeRecord(out, ret_record);
            }
            case GetCounter -> {
                long counter = store.GetCounter();
                writeCounter(out, counter);
            }
            case SetCounter -> {
                long counter = store.SetCounter();
                writeCounter(out, counter);
            }
            case DelCounter -> {
                long counter = store.DelCounter();
                writeCounter(out, counter);
            }
            case GetDump -> {
                String dump = store.getDump();
                out.println(dump);
            }
            case NewDump -> {
                String dump = store.newDump();
                out.println(dump);
            }
            case DumpInterval -> {
                store.ChangeInterval(duration);
                out.println("changed interval");
            }
            case SetTTL -> {
                Record retRecord = store.Set(key, value);
                writeRecord(out, retRecord);
                store.SetTTL(key, duration);
            }
        }
    }
}
