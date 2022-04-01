package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"net"
	"strings"
)

type newConn struct {
	conn net.Conn
	connerr error
}

func NewListener(ctx context.Context, store *Storage) error {
	ln, err := net.Listen("tcp", ":8080")
	if err != nil {
		return err
	}
	defer ln.Close()
	connChan := make(chan newConn)
	go func() {
		connection, err := ln.Accept()
		fmt.Println("New Connection")
		if errors.Is(err, net.ErrClosed) {
			fmt.Println("Connection is closed")
			return
		}
		inChan :=  newConn{
			conn: connection,
			connerr: err,
		}
		connChan <- inChan
	}()
	for {
		select {
		case nConn := <- connChan:
			if nConn.connerr != nil {
				return nConn.connerr
			}
			fmt.Println("Spawning new handler")
			go ConnectionHandler(nConn.conn, store)
		case <- ctx.Done():
			err = ctx.Err()
			if err != nil {
				fmt.Printf("Closing server with error %v\n", err)
				return err
			}
			return nil
		}
	}
}

func ConnectionHandler(conn net.Conn, store *Storage) error {
	defer conn.Close()
	bufRead := bufio.NewReader(conn)
	bufWriter := bufio.NewWriter(conn)
	for {
		line, err := bufRead.ReadString('\n')
		if err != nil {
			return err
		}
		line = strings.TrimSuffix(line, "\n")
		fmt.Println("Got new line => '" + line + "'")
		cmd, err := InterpretCommand(line)
		if err != nil {
			bufWriter.WriteString(err.Error() + "\n")
			return err
		}
		err = ExecuteCommand(*bufWriter, store, cmd)
		if err != nil {
			return err
		}
	}
}

func ExecuteCommand(w bufio.Writer, store *Storage, cmd *CompleteCommand) error {
	writingString := ""
	switch cmd.CommandKind {
	case Get:
		writingString = store.Get(cmd.Key)
	case Set:
		writingString = store.Set(cmd.Key, cmd.Value)
	case Del:
		writingString = store.Delete(cmd.Key)
	case GetCounter:
		writingNum := store.GetCounter()
		writingString = fmt.Sprintf("%v", writingNum)
	case SetCounter:
		writingNum := store.SetCounter()
		writingString = fmt.Sprintf("%v", writingNum)
	case DelCounter:
		writingNum := store.DelCounter()
		writingString = fmt.Sprintf("%v", writingNum)
	case SetTTL:
		writingString = store.SetTTL(*cmd.Ttl, cmd.Key, cmd.Value)
	case NewDump:
		jsonBytes, err := store.NewDump()
		if err != nil {
			return err
		}
		_, err = w.Write(jsonBytes)
		if err != nil {
			return err
		}
	case GetDump:
		jsonBytes, err := store.GetDump()
		if err != nil {
			return err
		}
		_, err = w.Write(jsonBytes)
		if err != nil {
			return err
		}
	case DumpInterval:
		newInterval := cmd.Ttl
		store.ChangeInterval(*newInterval)
		writingString = fmt.Sprintf("Set new interval %v", newInterval)
	default:
		return errors.New("Unimplemented")
	}
	fmt.Println("Writing => " + writingString)
	_, err := w.WriteString(writingString + "\n")
	err = w.Flush()
	return err
}
