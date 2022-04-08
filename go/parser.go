package main

import (
	"errors"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var InvalidCommand error = errors.New("Invalid command")

const (
	Get = iota
	Set
	Del
	GetCounter
	SetCounter
	DelCounter
	GetDump
	NewDump
	DumpInterval
	SetTTL
	Upload
	Download
	Remove
)

const GetString = "GET"
const SetString = "SET"
const DelString = "DEL"
const GetCounterString = "GETC"
const SetCounterString = "SETC"
const DelCounterString = "DELC"
const GetDumpString = "GETDUMP"
const NewDumpString = "NEWDUMP"
const DumpIntervalString = "DUMPINTERVAL"
const SetTTLString = "SETTTL"
const UploadString = "UPLOAD"
const DownloadString = "DOWNLOAD"
const RemoveString = "REMOVE"

const regExp = "[[:alnum:]]+"

var matcher, _ = regexp.Compile(regExp)

const timeExp = "([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9])s"

var timeMatcher, _ = regexp.Compile(timeExp)

func parseDuration(input string) *time.Duration {
	subMatches := timeMatcher.FindStringSubmatch(input)
	if len(subMatches) != 4 {
		return nil
	}
	var hours int64
	var minutes int64
	var seconds int64

	hours, err := strconv.ParseInt(subMatches[1], 10, 32)
	if err != nil {
		return nil
	}
	minutes, err = strconv.ParseInt(subMatches[2], 10, 32)
	if err != nil {
		return nil
	}
	seconds, err = strconv.ParseInt(subMatches[3], 10, 32)
	if err != nil {
		return nil
	}
	minutes += hours * 60
	seconds += minutes * 60
	ret := time.Second * time.Duration(seconds)
	return &ret
}

type CompleteCommand struct {
	CommandKind uint16
	Key         string
	Value       string
	Size        int64
	Ttl         *time.Duration
}

func InterpretCommand(command string) (*CompleteCommand, error) {

	parts := strings.Split(command, " ")
	if len(parts) == 0 {
		return nil, InvalidCommand
	}
	commandString := parts[0]
	retCommand := CompleteCommand{}

	switch commandString {
	case GetString:
		if len(parts) != 2 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = Get
		potKey := parts[1]
		potKeyReg := matcher.MatchString(potKey)
		if !potKeyReg {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
	case SetString:
		if len(parts) != 3 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = Set
		potKey := parts[1]
		potVal := parts[2]
		potKeyReg := matcher.MatchString(potKey)
		potValReg := matcher.MatchString(potVal)
		if !(potKeyReg && potValReg) {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
		retCommand.Value = potVal
	case DelString:
		if len(parts) != 2 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = Del
		potKey := parts[1]
		potKeyReg := matcher.MatchString(potKey)
		if !potKeyReg {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
	case GetCounterString:
		if len(parts) != 1 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = GetCounter
	case SetCounterString:
		if len(parts) != 1 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = SetCounter
	case DelCounterString:
		if len(parts) != 1 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = DelCounter
	case GetDumpString:
		if len(parts) != 1 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = GetDump
	case NewDumpString:
		if len(parts) != 1 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = NewDump
	case DumpIntervalString:
		if len(parts) != 2 {
			return nil, InvalidCommand
		}
		duration := parseDuration(parts[1])
		if duration == nil {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = DumpInterval
		retCommand.Ttl = duration
	case SetTTLString:
		if len(parts) != 4 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = SetTTL
		potKey := parts[1]
		potVal := parts[2]
		potKeyReg := matcher.MatchString(potKey)
		potValReg := matcher.MatchString(potVal)
		if !(potKeyReg && potValReg) {
			return nil, InvalidCommand
		}
		potDur := parts[3]
		duration := parseDuration(potDur)
		if duration == nil {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
		retCommand.Value = potVal
		retCommand.Ttl = duration
	case UploadString:
		if len(parts) != 3 {

			return nil, InvalidCommand
		}
		retCommand.CommandKind = Upload
		potKey := parts[1]
		potKeyReg := matcher.MatchString(potKey)
		if !potKeyReg {
			return nil, InvalidCommand
		}
		potSize := parts[2]
		size, err := strconv.ParseInt(potSize, 10, 64)
		if err != nil {
			return nil, InvalidCommand
		}
		retCommand.Size = size
		retCommand.Key = potKey
	case DownloadString:
		if len(parts) != 2 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = Download
		potKey := parts[1]
		potKeyReg := matcher.MatchString(potKey)
		if !potKeyReg {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
	case RemoveString:
		if len(parts) != 2 {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = Remove
		potKey := parts[1]
		potKeyReg := matcher.MatchString(potKey)
		if !potKeyReg {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
	default:
		return nil, InvalidCommand
	}
	return &retCommand, nil
}
