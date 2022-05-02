package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"net"
	"sync"
	"time"

	"github.com/panjf2000/ants/v2"
)

type BenchFastReporter[Re Reporter] struct {
	internal Re
	comm chan <- SingleReportPerform
}

func goBenchFastReporting[Re Reporter](ctx context.Context, internal Re, in <- chan SingleReportPerform) {
	for {
		select {
		case newReport := <- in:
			internal.ReportPerform(newReport.pattern, newReport.expected, newReport.given, newReport.duration)

		case <- ctx.Done():
			return
		}
	}
}

func NewBenchFastReporter[Re Reporter](internal Re) *BenchFastReporter[Re] {
	comm := make(chan SingleReportPerform)
	go goBenchFastReporting(context.TODO(), internal, comm)
	ret := BenchFastReporter[Re]{
		internal: internal,
		comm: comm,
	}
	return &ret
}

func (r *BenchFastReporter[Re]) Report(pattern Pattern, expected, given string, duration *time.Duration) {
	sReport := SingleReportPerform{pattern, expected, given, duration}
	r.comm <- sReport
}

type BenchRunner[Re Reporter] struct {
	state *State
	fastReporter *BenchFastReporter[Re]
	pool *ants.PoolWithFunc
	waitGroup *sync.WaitGroup
}

var remoteAddress = ""

type SinglePatterns struct {
	patterns []Pattern
	config OperationConfig
}

func NewBenchRunner[Re Reporter](reporter Re, general *OperationConfig) *BenchRunner[Re] {
	remoteAddress = fmt.Sprintf("%v:%v", general.hostname, general.port)

	fastReporter := NewBenchFastReporter(reporter)	
	var waitGroup sync.WaitGroup
	ret := BenchRunner[Re]{nil, fastReporter, nil, &waitGroup}
	pool, err := ants.NewPoolWithFunc(int(fileDescriptorLimit), func(i interface{}) {
		singlePatterns := i.(SinglePatterns)
		ret.Run(singlePatterns.patterns, singlePatterns.config)
		waitGroup.Done()	
	})
	if err != nil {
		log.Fatal(err)
	}
	ret.pool = pool
	return &ret
}

func (b *BenchRunner[Re]) SetState(state *State) {
	b.state = state
}

func (b *BenchRunner[Re]) GetState() *State {
	return b.state
}


func NewConBuf[C net.Conn](conn C) *bufio.ReadWriter {
	connWriter := bufio.NewWriter(conn)
	connReader := bufio.NewReader(conn)
	return bufio.NewReadWriter(connReader, connWriter)
}

func (b *BenchRunner[Re]) Run(patterns []Pattern, general OperationConfig) {
	useCounter := 0
	conn, err := net.Dial("tcp", remoteAddress)
	if err != nil {
		log.Println("ERROR during initial connection with server")
		log.Fatal(err)
	}
	connBuf := NewConBuf(conn)
	for _, pattern := range patterns {
		if useCounter > 5 {
			useCounter = 0
			conn, err = net.Dial("tcp", remoteAddress)
			if err != nil {
				log.Println("ERROR while refreshing connection to server")
				log.Fatal(err)
			}
			connBuf = NewConBuf(conn)
		}

		err = b.RunPatternOpt(pattern, connBuf)
		
		if err != nil {
			log.Println("ERROR during run of pattern", pattern)
		}

		useCounter++
	}
}

func (b *BenchRunner[Re]) RunPatternOpt(pattern Pattern, connBuf *bufio.ReadWriter) error {
	switch pattern.kind {
	case Set, Get, Del, SetCounter, GetCounter, DelCounter:
		outStr := b.state.PerformPattern(pattern) + "\n"
		startTime := time.Now()
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
		duration := time.Since(startTime)
		b.fastReporter.Report(pattern, outStr, realStr, &duration)
	default:
		log.Fatal("Invalid pattern")
	}

	return nil
}

func (b *BenchRunner[Re]) Release() error {
	b.pool.Release()
	return nil
}

func (b *BenchRunner[Re]) RunAsync(ctx context.Context, patternChan <- chan []Pattern, general OperationConfig) error {

	for {
		select {
		case  <- ctx.Done():
			return nil
		case patterns := <- patternChan:
			singlePatterns := SinglePatterns{patterns: patterns, config: general}
			err := b.pool.Invoke(singlePatterns)
			if err != nil {
				log.Fatal("Couldn't invoke function on pool", err)
			}
		}
	}

}
