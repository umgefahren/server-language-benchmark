package main

import (
	"errors"
	"github.com/goccy/go-yaml"
	"strings"
)

var InvalidCyclePattern = errors.New("pattern is invalid")

// BenchmarkConfig is the collection of all sub-configs
type BenchmarkConfig struct {
	General GeneralConfig
	Basic   BasicConfig
}

// GeneralConfig specifies all options for the hole test cycle - all config can also be passed via command-line flag, overwriting these configs
type GeneralConfig struct {
	// TotalDuration specifies how long the test should take in minutes
	TotalDuration float64
	// ServerHostname specifies the hostname of the server to bench
	ServerHostname string
	// ServerPort specifies the port of the server to bench
	ServerPort int
	// CommandsPerConn specifies the number of operations to perform with one connection
	CommandsPerConn int
}

// BasicConfig specifies all options for the Basic Commands (SET, GET, DEL, SETC, GETC and DELC)
type BasicConfig struct {
	// Key specifies the config for the pseudo-random key generation
	Key StringConfig
	// Value specifies the config for the pseudo-random value generation
	Value StringConfig
	// CycleDuration specifies how many milliseconds should pass before repeating the instruction pattern (-1 means as often as possible)
	CycleDuration float64
	// CyclePattern specifies the pattern in which the instruction should be performed with one key-value pair. (i.e. GET-SET-SET-GET-GET-DEL)
	CyclePattern string
}

type StringConfig struct {
	MinLen       int
	MaxLen       int
	AlphaNumeric bool
}

var DefaultBenchmarkConfig = BenchmarkConfig{
	General: DefaultGeneralConfig,
	Basic:   DefaultBasicConfig,
}

var DefaultGeneralConfig = GeneralConfig{
	TotalDuration:   10,
	ServerHostname:  "localhost",
	ServerPort:      8080,
	CommandsPerConn: 5,
}

var DefaultBasicConfig = BasicConfig{
	Key: StringConfig{
		MinLen: 10,
		MaxLen: 1000,
	},
	Value: StringConfig{
		MinLen: 10,
		MaxLen: 1000,
	},
	CycleDuration: -1,
	CyclePattern:  "SET-GET-GET-GET-DEL",
}

func ParseConfig(input string) (*BenchmarkConfig, error) {
	ret := DefaultBenchmarkConfig
	err := yaml.Unmarshal([]byte(input), ret)
	if err != nil {
		return nil, err
	}
	return &ret, nil
}

func parseCyclePattern(input string) ([]uint, error) {
	splits := strings.Split(input, "-")
	ret := make([]uint, len(splits))
	for _, split := range splits {
		switch split {
		case SetString:
			ret = append(ret, Set)
		case GetString:
			ret = append(ret, Get)
		case DelString:
			ret = append(ret, Del)
		case SetCounterString:
			ret = append(ret, SetCounter)
		case GetCounterString:
			ret = append(ret, GetCounter)
		case DelCounterString:
			ret = append(ret, DelCounter)
		}
	}
	return ret, InvalidCyclePattern
}
