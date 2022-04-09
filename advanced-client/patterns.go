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

const upperStringLimit = 10
const lowerStringLimit = 5

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

func (p Pattern) DeriveGet() Pattern {
	return Pattern{
		kind: Get,
		key:  p.key,
	}
}

func (p Pattern) DeriveDel() Pattern {
	return Pattern{
		kind: Del,
		key:  p.key,
	}
}

func (p *Pattern) String() string {
	var retString string
	switch p.kind {
	case Set:
		retString = fmt.Sprintf("SET %v %v", p.key, p.value)
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
	return rand.Intn(delta) + lowerStringLimit
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

func GenerateRandomSet() Pattern {
	ret := generatePatternWithKey(Set)
	ret.value = generateString()
	return ret
}

func DerivePatternsFromCyclePattern(cyclePattern []uint) []Pattern {
	ret := make([]Pattern, 0)
	currentSet := GenerateRandomSet()
	for _, p := range cyclePattern {

		switch p {
		case Set:
			currentSet = GenerateRandomSet()
			ret = append(ret, currentSet)
		case Get:
			newGet := currentSet.DeriveGet()
			ret = append(ret, newGet)
		case Del:
			newDel := currentSet.DeriveDel()
			ret = append(ret, newDel)
		case SetCounter, GetCounter, DelCounter:
			ret = append(ret, Pattern{kind: int(p)})
		}
	}
	return ret
}

type number interface {
	int | int8 | int16 | int32 | int64 | uint | uint8 | uint16 | uint32 | uint64
}

func OperationIntToString[N number](num N) string {
	switch num {
	case Set:
		return SetString
	case Get:
		return GetString
	case Del:
		return DelString
	case SetCounter:
		return SetCounterString
	case GetCounter:
		return GetCounterString
	case DelCounter:
		return DelCounterString
	default:
		panic("unimplemented")
	}
}

func OperationStringToInt[N number](str string) N {
	switch str {
	case SetString:
		return Set
	case GetString:
		return Get
	case DelString:
		return Del
	case SetCounterString:
		return SetCounter
	case GetCounterString:
		return GetCounter
	case DelCounterString:
		return DelCounter
	default:
		panic("unimplemented")
	}
}
