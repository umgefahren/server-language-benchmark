package main

import (
	"regexp"
	"testing"
)

var benchKeyData = make([]string, 0)

var benchDurData = make([]string, 0)

var regexExp = "[a-zA-Z0-9]+"
var matcher = regexp.MustCompile(regexExp)

func BenchmarkValidateString(b *testing.B) {
	for i := len(benchKeyData); i < b.N; i++ {
		key := generateString()
		benchKeyData = append(benchKeyData, key)
	}

	makeSearchRunes()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		key := benchKeyData[i]
		validateString(key)
	}
}

func BenchmarkValidateStringReg(b *testing.B) {
	for i := len(benchKeyData); i < b.N; i++ {
		key := generateString()
		benchKeyData = append(benchKeyData, key)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		key := benchKeyData[i]
		matcher.FindString(key)
	}
}

func BenchmarkValidateDuration(b *testing.B) {
	for i := len(benchDurData); i < b.N; i++ {
		val := generateDurationString(0, 99, 0, 99, 0, 99)
		benchDurData = append(benchDurData, val)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		dur := benchDurData[i]
		_, err := parseDuration(dur)
		if err != nil {
			b.Error(err)
		}
	}
}

func BenchmarkValidateDurationReg(b *testing.B) {
	for i := len(benchDurData); i < b.N; i++ {
		val := generateDurationString(0, 99, 0, 99, 0, 99)
		benchDurData = append(benchDurData, val)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		dur := benchDurData[i]
		_, err := parseDurationRegEx(dur)
		if err != nil {
			b.Error(err, dur)
		}
	}
}
