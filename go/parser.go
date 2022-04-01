package main

import (
	"errors"
	"regexp"
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

const regExp = "[[:alnum:]]+"

var matcher, _ = regexp.Compile(regExp)

type CompleteCommand struct {
	CommandKind uint16
	Key string
	Value string
	Ttl *time.Duration
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
		duration, err := time.ParseDuration(parts[1])
		if err != nil {
			return nil, InvalidCommand
		}
		retCommand.CommandKind = DumpInterval 
		retCommand.Ttl = &duration
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
		duration, err := time.ParseDuration(potDur)
		if err != nil {
			return nil, InvalidCommand
		}
		retCommand.Key = potKey
		retCommand.Value = potVal
		retCommand.Ttl = &duration
	default:
		return nil, InvalidCommand
	}
	return &retCommand, nil
}
