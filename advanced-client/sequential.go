package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
)

type SerialRunner[Re Reporter] struct {
	state    *State
	reporter Re
}

func NewSerialRunner[Re Reporter](reporter Re) SerialRunner[Re] {
	state := NewState()
	runner := SerialRunner[Re]{
		state:    &state,
		reporter: reporter,
	}
	runner.reporter = reporter
	return runner
}

func (s SerialRunner[Re]) SetState(state *State) {
	s.state = state
}

func (s SerialRunner[Re]) GetState() *State {
	return s.state
}

func (s SerialRunner[Re]) Run(patterns []Pattern, general OperationConfig) {
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

		err = s.RunPattern(pattern, conn)

		if err != nil {
			log.Println("ERROR during run of pattern", pattern)
		}

		useCounter++
	}
}

func (s SerialRunner[Re]) RunPattern(pattern Pattern, conn net.Conn) error {
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
		s.reporter.Report(pattern, outStr, realStr)
	default:
		log.Fatal("Invalid pattern")
	}

	return nil
}
