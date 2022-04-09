package main

import (
	"bufio"
	"fmt"
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
	default:
		panic("unimplemented")
	}
	return nil
}
