package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"
)

const (
	GenerateData = iota
	PerformTest
	PerformBenchmark
	RunInteractive
	SingleCommand
)

var allCommands = []uint{Set, Get, Del, SetCounter, GetCounter, DelCounter}

var generateDataOpt = flag.Bool("gen", false, "Pass this flag to generate benchmark data")
var performBenchmarkOpt = flag.Bool("bench", false, "Pass this flag to perform a benchmark")
var performTestOpt = flag.Bool("test", false, "Pass this flag to perform a test")
var interactiveModeOpt = flag.Bool("it", false, "Pass this flag to run in interactive mode")
var singleModeOpt = flag.Bool("single", false, "Pass this flag to run a single command")
var helpOpt = flag.Bool("h", false, "Pass this flag to get help")
var serverHostnameOpt = flag.String("host", "localhost", "Hostname of server for benchmark/test/interactive/single")
var serverPortOpt = flag.Uint("port", 8080, "Port of server for benchmark/test/interactive/single")
var testLevelOpt = flag.Uint("level", 1, "Command complexity level for test (0 -> Only separate specified ; 1 -> Essential ; 2 -> 1 + Dumping ; 3 -> 2 + Delayed ; 4 -> 3 + Heavy Load)")
var commandOpt = flag.String("cmd", "all", "Command to perform in single mode or comma seperated commands for testing")
var keyOpt = flag.String("key", "hello", "Key value for single mode")
var valueOpt = flag.String("value", "world", "Value value for single mode")
var durationOpt = flag.Duration("duration", time.Second*10, "Duration for single mode")
var outOpt = flag.String("o", "bench.txt", "Path for output of benchmark/data generation")
var amountOpt = flag.Float64("amount", 0.5, "Amount of data in GB to generate")

var planOpt = "plan.yaml"
var pathOpt = "unset"

type OperationConfig struct {
	operationKind uint
	generateData  *GenerateDataConfig
	testConfig    *TestConfig
	hostname      string
	port          uint
}

type GenerateDataConfig struct {
	planPath string
	outPath  string
	amount   float64
}

type TestConfig struct {
	level    uint
	commands []uint
}

type Single struct {
	kind     uint
	key      string
	value    string
	duration time.Duration
	path     string
}

func (g *GenerateDataConfig) String() string {
	return fmt.Sprintf("Generate Data for plan %v to %v. Data Amount %vGB", g.planPath, g.outPath, g.amount)
}

func preemptiveTests() {
	flag.Func("plan", "Pass the location of the plan configuration file", func(s string) error {
		if !FileExists(s) {
			return errors.New("plan file doesn't exist")
		}
		planOpt = s
		return nil
	})

	flag.Func("path", "Pass the location of a file for single command", func(s string) error {
		if s == "unset" {
			return nil
		}

		if !FileExists(s) {
			return errors.New("data file for single command doesn't exist")
		}
		return nil
	})
}

func PrintHelp() {
	flag.PrintDefaults()
}

func FileExists(path string) bool {
	f, err := os.Open(path)
	if err != nil {
		return false
	}
	err = f.Close()
	if err != nil {
		panic(err)
	}
	return true
}

func parseGenerateDataOpt(in OperationConfig) OperationConfig {
	in.operationKind = GenerateData

	if !FileExists(planOpt) {
		fmt.Println("Plan file doesn't exist")
		flag.PrintDefaults()
		os.Exit(1)
	}

	genDataConfig := new(GenerateDataConfig)

	genDataConfig.outPath = *outOpt
	genDataConfig.planPath = planOpt
	genDataConfig.amount = *amountOpt

	fmt.Println(genDataConfig.String())

	in.generateData = genDataConfig

	return in
}

func parseCommands(in string) []uint {
	if in == "all" {
		return allCommands
	}

	ret := make([]uint, 1)
	splits := strings.Split(in, ",")
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
		default:
			fmt.Printf("Provided command \"%v\" argument is invalid\n", split)
			os.Exit(1)
		}
	}
	return ret
}

func parsePerformTestOpt(in OperationConfig) OperationConfig {
	if *testLevelOpt > 4 {
		fmt.Println("Test level is set to an invalid value")
		os.Exit(1)
	}

	performTestConfig := new(TestConfig)
	performTestConfig.level = *testLevelOpt
	performTestConfig.commands = parseCommands(*commandOpt)

	return in
}

func OperationConfigFromFlags() OperationConfig {
	flag.Parse()

	preemptiveTests()

	if *helpOpt {
		PrintHelp()
		os.Exit(0)
	}

	if !(*generateDataOpt != *performTestOpt != *performBenchmarkOpt != *interactiveModeOpt != *singleModeOpt) {
		_, err := fmt.Fprintln(os.Stderr, "Zero or more than one operation options passed")
		if err != nil {
			panic(err)
		}
		os.Exit(1)
	}

	var ret OperationConfig

	switch {
	case *generateDataOpt:
		return parseGenerateDataOpt(ret)
	case *performTestOpt:
		return parsePerformTestOpt(ret)
	case *performBenchmarkOpt:
		panic("unimplemented")
	case *interactiveModeOpt:
		ret.operationKind = RunInteractive
	default:
		panic("WTF?")
	}

	return ret
}
