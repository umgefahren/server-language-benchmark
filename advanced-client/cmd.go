package main

import (
	"flag"
	"fmt"
	"github.com/goccy/go-yaml"
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

var generateDataMode     = flag.NewFlagSet("gen", flag.ExitOnError)
var performBenchmarkMode = flag.NewFlagSet("bench", flag.ExitOnError)
var performTestMode      = flag.NewFlagSet("test", flag.ExitOnError)
var interactiveMode      = flag.NewFlagSet("it", flag.ExitOnError)
var singleMode           = flag.NewFlagSet("single", flag.ExitOnError)


// Data generation mode
var outGendata = generateDataMode.String("o", "data.txt", "Filename for generated data")
var amountGendata = generateDataMode.Float64("amount", 0.5, "Amount of data in GB to generate")
var compressionGendata = generateDataMode.Bool("compress", false, "Specify if the generated data should be compressed")
var planGendata = generateDataMode.String("plan", "plan.yaml", "Filename of the plan configuration file")

// Benchmark mode
var serverHostnameBench = performBenchmarkMode.String("host", "localhost", "Server Hostname")
var serverPortBench = performBenchmarkMode.Uint("port", 8080, "Server port")

// Test mode
var serverHostnameTest = performTestMode.String("host", "localhost", "Server Hostname")
var serverPortTest = performTestMode.Uint("port", 8080, "Server port")
var commandTest = performTestMode.String("cmd", "all", "Comma seperated list of commands to test")
var testLevelTest = performTestMode.Uint("level", 1, "Command complexity level for test (0 -> Only separate specified ; 1 -> Essential ; 2 -> 1 + Dumping ; 3 -> 2 + Delayed ; 4 -> 3 + Heavy Load)")
var testCyclesTest = performTestMode.Int("c", 10, "Number of test cycles to perform")
var colorOutput = performTestMode.Bool("color", true, "Colored output")

// Interactive mode
var serverHostnameIt = interactiveMode.String("host", "localhost", "Server Hostname")
var serverPortIt = interactiveMode.Uint("port", 8080, "Server port")

// Single mode
var serverHostnameSingle = singleMode.String("host", "localhost", "Server Hostname")
var serverPortSingle = singleMode.Uint("port", 8080, "Server port")
var commandSingle = singleMode.String("cmd", "all", "Command to execute")
var keySingle = singleMode.String("key", "hello", "Key to operate on")
var valueSingle = singleMode.String("value", "world", "Value to use")
var pathSingle = singleMode.String("file", "file.txt", "Filename of a file to upload / download to")
var durationSingle = singleMode.Duration("duration", time.Second*10, "Duration")

type OperationConfig struct {
	operationKind uint
	generateData  *GenerateDataConfig
	testConfig    *TestConfig
	singleConfig  *Single
	hostname      string
	port          uint
}

type GenerateDataConfig struct {
	planPath string
	outPath  string
	amount   float64
  compress bool
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

func (s Single) ToPattern() Pattern {
	return Pattern{
		kind:     int(s.kind),
		key:      s.key,
		value:    s.value,
		duration: &s.duration,
		path:     s.path,
	}
}

func (g *GenerateDataConfig) String() string {
	return fmt.Sprintf("Generate Data for plan %v to %v. Data Amount %vGB", g.planPath, g.outPath, g.amount)
}

func printHelp() {
  generalUsage := fmt.Sprintf("Usage: client <gen / g | bench / b | test / t | single / s | interactive / it / i> [options]\nSee client <command> -h for details")
  if len(os.Args) <= 1 {
    fmt.Println(generalUsage)
  } else {
    switch os.Args[1] {
    case "gen", "g":
      generateDataMode.PrintDefaults()
      fmt.Println("\nDefault configuration:")
      yamlBytes, err := yaml.Marshal(DefaultBenchmarkConfig)
      if err != nil {
        panic(err)
      }
      fmt.Println(string(yamlBytes))
    case "test", "t":
      performTestMode.PrintDefaults()
    case "bench", "b":
      performBenchmarkMode.PrintDefaults()
    case "single", "s":
      singleMode.PrintDefaults()
    case "interactive", "it", "i":
      interactiveMode.PrintDefaults()
    default:
      fmt.Println(generalUsage)
    }
  }


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

func parseGenerateData() OperationConfig {
  generateDataMode.Parse(os.Args[2:])
  var ret OperationConfig
	ret.operationKind = GenerateData

	if !FileExists(*planGendata) {
		fmt.Println("Plan file does not exist")
    printHelp()
		os.Exit(1)
	}

	genDataConfig := new(GenerateDataConfig)

	genDataConfig.outPath = *outGendata
	genDataConfig.planPath = *planGendata
	genDataConfig.amount = *amountGendata
  genDataConfig.compress = *compressionGendata

	fmt.Println(genDataConfig.String())

	ret.generateData = genDataConfig

	return ret
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
      printHelp()
			os.Exit(1)
		}
	}
	return ret
}

func parseTest() OperationConfig {
  performTestMode.Parse(os.Args[2:])
	if *testLevelTest > 4 {
    fmt.Printf("Test level %d is not in [1,2,3,4]\n", *testLevelTest)
    printHelp()
		os.Exit(1)
	}

  var ret OperationConfig
	ret.operationKind = PerformTest

	performTestConfig := new(TestConfig)
	performTestConfig.level = *testLevelTest
	commands := parseCommands(*commandTest)

	performTestConfig.commands = commands

	upperBound := *testCyclesTest

	for i := 0; i < upperBound; i++ {
		performTestConfig.commands = append(performTestConfig.commands, commands...)
	}

	ret.testConfig = performTestConfig
  ret.hostname = *serverHostnameTest
  ret.port = *serverPortTest

	return ret
}

func parseSingle() OperationConfig {
  singleMode.Parse(os.Args[2:])
  var ret OperationConfig
	ret.operationKind = SingleCommand

	commandString := *commandSingle
	command, err := OperationStringToInt[uint](commandString)
	if err != nil {
    fmt.Printf("Command is invalid: %s\n", commandString)
    printHelp()
		os.Exit(1)
	}

	singleOpt := new(Single)
	singleOpt.kind = command
  singleOpt.duration = *durationSingle

	switch {
	case command == Set || command == Get || command == Del:
		keyPot := *keySingle
		if !validateString(keyPot) {
			fmt.Println(keyPot, "is invalid as a key")
      printHelp()
			os.Exit(1)
		}
		singleOpt.key = keyPot
		fallthrough
	case command == Set:
		valueOpt := *valueSingle
		if !validateString(valueOpt) {
			fmt.Println(valueOpt, "is invalid as a value")
      printHelp()
			os.Exit(1)
		}
		singleOpt.value = valueOpt
	}

	ret.singleConfig = singleOpt
  ret.hostname = *serverHostnameSingle
  ret.port = *serverPortSingle

	return ret
}

func parseBenchmark() OperationConfig {
  performBenchmarkMode.Parse(os.Args[2:])
  var ret OperationConfig
  ret.operationKind = PerformBenchmark

  ret.hostname = *serverHostnameBench
  ret.port = *serverPortBench

  return ret
}

func parseInteractive() OperationConfig {
  interactiveMode.Parse(os.Args[2:])
  var ret OperationConfig
  ret.operationKind = RunInteractive

  ret.hostname = *serverHostnameIt
  ret.port = *serverPortIt
  
  return ret
}

func OperationConfigFromFlags() OperationConfig {
  if len(os.Args) <= 1 {
    printHelp()
    os.Exit(0)
  }

  switch os.Args[1] {
  case "gen", "g":
    return parseGenerateData()
  case "test", "t":
    return parseTest()
  case "bench", "b":
    return parseBenchmark()
  case "single", "s":
    return parseSingle()
  case "interactive", "it", "i":
    return parseInteractive()
  case "help", "h", "-h", "--help":
    printHelp()
    os.Exit(0)
  default:
    fmt.Printf("Invalid command: %s\n", os.Args[1])
    printHelp()
    os.Exit(1)
  }

  // unreached
  var empty OperationConfig
  return empty
}
