package main

import (
	"bufio"
	"fmt"
	"github.com/fatih/color"
	"net"
	"os"
)

func interactiveRun(config OperationConfig) error {
	address := fmt.Sprintf("%v:%v", config.hostname, config.port)
	fmt.Println("Connecting to address", address)

	conn, err := net.Dial("tcp", address)
	if err != nil {
		return err
	}

	stdinReader := bufio.NewReader(os.Stdin)
	connReader := bufio.NewReader(conn)
	for {
		userLine, err := stdinReader.ReadString('\n')
		if err != nil {
			return err
		}
		if userLine == "EXIT" {
			return nil
		}
		_, err = conn.Write([]byte(userLine))
		if err != nil {
			return err
		}
		connLine, err := connReader.ReadString('\n')
		if err != nil {
			return err
		}
		fmt.Print(connLine)
	}
}

func PerformOperation(config OperationConfig) error {
	switch config.operationKind {
	case RunInteractive:
		return interactiveRun(config)
	case GenerateData:
		panic("unimplemented")
	case PerformTest:
		reporter := NewTestReporter()
		runner := NewSerialRunner(&reporter)
		ops := DerivePatternsFromCyclePattern(config.testConfig.commands)
		runner.Run(ops, config)
		success := reporter.Successes()
		failures := reporter.Failures()
		if *colorOutput {
			color.New(color.FgGreen).Printf("Successes: %v\n", success)
			color.New(color.FgRed).Printf("Failures: %v\n", failures)
		} else {
			fmt.Printf("Successes: %v\n", success)
			fmt.Printf("Failures: %v\n", failures)
		}
	case SingleCommand:
		pattern := config.singleConfig.ToPattern()
		fmt.Println("Performing pattern:", pattern.String())

		address := fmt.Sprintf("%v:%v", config.hostname, config.port)

		client, err := net.Dial("tcp", address)
		if err != nil {
			fmt.Println("Error dialing the server:", err)
			os.Exit(1)
		}
		defer client.Close()
		_, err = client.Write([]byte(pattern.String() + "\n"))
		if err != nil {
			fmt.Println("Error writing to the server:", err)
			os.Exit(1)
		}
		bufReader := bufio.NewReader(client)
		serverLine, err := bufReader.ReadString('\n')
		if err != nil {
			fmt.Println("Error reading server response:", err)
			os.Exit(1)
		}
		fmt.Println("Server response:")
		fmt.Print(serverLine)
	default:
		panic("unimplemented")
	}
	return nil
}
