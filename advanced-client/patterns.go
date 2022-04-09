package main

import (
	"fmt"
	"math/rand"
	"strings"
	"time"
)

const (
	Set = iota
	Get
	Del
	SetCounter
	GetCounter
	DelCounter
)

const (
	SetString        = "SET"
	GetString        = "GET"
	DelString        = "DEL"
	SetCounterString = "SETC"
	GetCounterString = "GETC"
	DelCounterString = "DELC"
)

const upperStringLimit = 1000
const lowerStringLimit = 10

const delta = upperStringLimit - lowerStringLimit

var letterRunes = []rune("abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
var letterLen = len(letterRunes)

type Pattern struct {
	kind     int
	key      string
	value    string
	duration *time.Duration
	path     string
}

func (p *Pattern) String() string {
	var retString string
	switch p.kind {
	case Set:
		retString = fmt.Sprintf("SET %v %v", p.kind, p.value)
	case Get:
		retString = fmt.Sprintf("GET %v", p.key)
	case Del:
		retString = fmt.Sprintf("DEL %v", p.key)
	case SetCounter:
		retString = "SETC"
	case GetCounter:
		retString = "GETC"
	case DelCounter:
		retString = "DELC"
	}
	return retString
}

func generateStringLength() int {
	return rand.Intn(delta)
}

func generateRune() rune {
	chosenN := rand.Intn(letterLen)
	return letterRunes[chosenN]
}

func generateString() string {
	stringLength := generateStringLength()
	var b strings.Builder
	for i := 0; i < stringLength; i++ {
		newRune := generateRune()
		_, err := b.WriteRune(newRune)
		if err != nil {
			panic(err)
		}
	}
	return b.String()
}

func generatePatternWithKey(kind int) Pattern {
	ret := Pattern{}
	ret.kind = kind
	ret.key = generateString()
	return ret
}
