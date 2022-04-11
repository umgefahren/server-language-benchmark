package main

import (
	"fmt"
	"github.com/fatih/color"
	"sync/atomic"
	"time"
)

type TestReporter struct {
	successes *uint64
	failures  *uint64
}

func NewTestReporter() TestReporter {
	suc := uint64(0)
	fai := uint64(0)
	return TestReporter{
		successes: &suc,
		failures:  &fai,
	}
}

func (t *TestReporter) Report(pattern Pattern, expected, given string) {
	green := color.New(color.FgGreen)
	red := color.New(color.FgRed)

	matches := expected == given
	var foreground *color.Color
	if matches {
		atomic.AddUint64(t.successes, 1)
		foreground = green
	} else {
		atomic.AddUint64(t.failures, 1)
		foreground = red
	}

	outPrint := pattern.String()
	if !matches {
		outPrint = fmt.Sprintf("%v Expected => %v Got => %v", outPrint, expected, given)
	}
	if *colorOutput {
		_, err := foreground.Println(outPrint)
		if err != nil {
			return
		}
	} else {
		fmt.Println(outPrint)
	}
}

func (t *TestReporter) ReportPerform(pattern Pattern, expected, given string, duration *time.Duration) {
	panic("implement me")
}

func (t *TestReporter) Successes() uint64 {
	return atomic.LoadUint64(t.successes)
}

func (t *TestReporter) Failures() uint64 {
	return atomic.LoadUint64(t.failures)
}
