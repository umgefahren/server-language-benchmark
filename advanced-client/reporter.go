package main

import "time"

type Reporter interface {
	Report(pattern Pattern, expected, given string)
	ReportPerform(pattern Pattern, expected, given string, duration *time.Duration)
}
