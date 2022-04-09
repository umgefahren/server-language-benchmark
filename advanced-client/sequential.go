package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
)

type SerialRunner struct {
	state *State
}

func NewSerialRunner() SerialRunner {
	state := NewState()
	return SerialRunner{&state}
}

func (s SerialRunner) SetState(state *State) {
	s.state = state
}

func (s SerialRunner) GetState() *State {
	return s.state
}

func (s SerialRunner) Run(patterns []Pattern, general OperationConfig, reporter Reporter) {
	address := fmt.Sprintf("%v:%v", general.hostname, general.port)
	useCounter := 0
	conn, err := net.Dial("tcp", address)
	if err != nil {
		log.Println("ERROR while initial connection to server")
		log.Fatal(err)
	}
	for _, pattern := range patterns {
		if useCounter > 5 {
			useCounter = 0
			conn, err = net.Dial("tcp", address)
			if err != nil {
				log.Println("ERROR while refreshing connection to server")
				log.Fatal(err)
			}
		}

		err = s.RunPattern(pattern, conn, reporter)

		if err != nil {
			log.Println("ERROR during run of pattern", pattern)
		}

		useCounter++
	}
}

func (s SerialRunner) RunPattern(pattern Pattern, conn net.Conn, reporter Reporter) error {
	connWriter := bufio.NewWriter(conn)
	connReader := bufio.NewReader(conn)
	connBuf := bufio.NewReadWriter(connReader, connWriter)
	switch pattern.kind {
	case Set, Get, Del, SetCounter, GetCounter, DelCounter:
		outStr := s.state.PerformPattern(pattern) + "\n"
		_, err := connBuf.WriteString(pattern.String() + "\n")
		if err != nil {
			return err
		}
		err = connBuf.Flush()
		if err != nil {
			return err
		}
		realStr, err := connBuf.ReadString('\n')
		if err != nil {
			return err
		}
		reporter.Report(pattern, outStr, realStr)
	default:
		log.Fatal("Invalid pattern")
	}

	return nil
}
