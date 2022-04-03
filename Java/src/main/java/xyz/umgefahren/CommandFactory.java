package xyz.umgefahren;

import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CommandFactory {
    private static final String GetString = "GET";
    private static final String SetString = "SET";
    private static final String DelString = "DEL";
    private static final String GetCounterString = "GETC";
    private static final String SetCounterString = "SETC";
    private static final String DelCounterString = "DELC";
    private static final String GetDumpString = "GETDUMP";
    private static final String NewDumpString = "NEWDUMP";
    private static final String DumpIntervalString = "DUMPINTERVAL";
    private static final String SetTTLString = "SETTTL";

    private static final Pattern pattern = Pattern.compile("[a-zA-Z0-9]+");
    private static final Pattern time_pattern = Pattern.compile("(?<hours>[0-9][0-9])h-(?<minutes>[0-9][0-9])m-(?<seconds>[0-9][0-9])s");

    private static boolean validate_string(String input) {
        Matcher matcher = pattern.matcher(input);
        return !matcher.find();
    }

    private static Duration parse_duration(String input) {
        Matcher matcher = time_pattern.matcher(input);
        if (!matcher.find()) {
            return null;
        }
        String hour_string = matcher.group("hours");
        String minute_string = matcher.group("minutes");
        String second_string = matcher.group("seconds");
        long hours = Long.parseLong(hour_string);
        long minutes = Long.parseLong(minute_string);
        long seconds = Long.parseLong(second_string);
        Duration duration = Duration.ZERO;
        duration = duration.plusHours(hours);
        duration = duration.plusMinutes(minutes);
        duration = duration.plusSeconds(seconds);
        return duration;
    }

    private static CommandType parse_type(String input) {
        return switch (input) {
            case GetString -> CommandType.Get;
            case SetString -> CommandType.Set;
            case DelString -> CommandType.Del;
            case GetCounterString -> CommandType.GetCounter;
            case SetCounterString -> CommandType.SetCounter;
            case DelCounterString -> CommandType.DelCounter;
            case GetDumpString -> CommandType.GetDump;
            case NewDumpString -> CommandType.NewDump;
            case DumpIntervalString -> CommandType.DumpInterval;
            case SetTTLString -> CommandType.SetTTL;
            default -> CommandType.Invalid;
        };
    }

    public static CompleteCommand parse(String input) {
        String[] parts = input.split(" ");
        if (parts.length < 1) {
            return null;
        }
        CommandType type = parse_type(parts[0]);
        CompleteCommand command = new CompleteCommand();
        command.type = type;
        if (type == CommandType.Invalid)
            return null;
        else if (type == CommandType.Get) {
            if (parts.length != 2) {
                return null;
            }
            if (validate_string(parts[1]))
                return null;
            command.key = parts[1];
        } else if (type == CommandType.Set) {
            if (parts.length != 3)
                return null;
            if (validate_string(parts[1]))
                return null;
            if (validate_string(parts[2]))
                return null;
            command.key = parts[1];
            command.value = parts[2];
        } else if (type == CommandType.Del) {
            if (parts.length != 2)
                return null;
            if (validate_string(parts[1]))
                return null;
            command.key = parts[1];
        } else if (type == CommandType.GetCounter || type == CommandType.SetCounter || type == CommandType.DelCounter || type == CommandType.NewDump || type == CommandType.GetDump) {
            if (parts.length != 1)
                return null;
        } else if (type == CommandType.DumpInterval) {
            if (parts.length != 2)
                return null;
            Duration duration = parse_duration(parts[1]);
            if (duration == null) {
                return null;
            }
            command.duration = duration;
        } else if (type == CommandType.SetTTL) {
            if (parts.length != 4)
                return null;
            if (validate_string(parts[1]))
                return null;
            if (validate_string(parts[2]))
                return null;
            command.key = parts[1];
            command.value = parts[2];
            Duration duration = parse_duration(parts[3]);
            if (duration == null)
                return null;
            command.duration = duration;
        } else {
            return null;
        }
        return command;
    }
}
