package xyz.umgefahren;

import java.util.Calendar;

public class Record {
    private final String key;
    private final String value;
    private final Calendar timestamp;

    Record(String key, String value) {
        this.key = key;
        this.value = value;
        this.timestamp = Calendar.getInstance();
    }

    public String getKey() {
        return this.key;
    }

    public String getValue() {
        return this.value;
    }

    public Calendar getTimestamp() {
        return this.timestamp;
    }
}
