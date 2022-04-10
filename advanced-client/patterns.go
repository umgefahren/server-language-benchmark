package main

import (
	"errors"
	"fmt"
	"math/rand"
	"regexp"
	"strconv"
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

var searchRunes = map[rune]uint8{}

var timeRegex = "([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9])s"
var timeMatcher = regexp.MustCompile(timeRegex)

var invalidDurationErr = errors.New("invalid duration")

func makeSearchRunes() {
	for _, r := range letterRunes {
		searchRunes[r] = 0
	}
}

func validateString(input string) bool {
	for _, c := range input {
		_, exists := searchRunes[c]
		if exists {
			return true
		}
	}
	return false
}

func parseDuration(input string) (time.Duration, error) {
	hours, err := strconv.ParseUint(input[:2], 10, 8)
	if err != nil {
		return 0, invalidDurationErr
	}
	if hours > 99 {
		return 0, invalidDurationErr
	}
	if input[2:4] != "h-" {
		return 0, invalidDurationErr
	}
	minutes, err := strconv.ParseUint(input[4:6], 10, 8)
	if err != nil {
		return 0, invalidDurationErr
	}
	if minutes > 99 {
		return 0, invalidDurationErr
	}
	if input[6:8] != "m-" {
		return 0, invalidDurationErr
	}
	seconds, err := strconv.ParseUint(input[8:10], 10, 8)
	if err != nil {
		return 0, invalidDurationErr
	}
	if seconds > 99 {
		return 0, invalidDurationErr
	}
	if input[10:] != "s" {
		return 0, invalidDurationErr
	}
	ret := time.Second * time.Duration(seconds)
	ret += time.Minute * time.Duration(minutes)
	ret += time.Hour * time.Duration(hours)
	return ret, nil
}

func parseDurationRegEx(input string) (time.Duration, error) {
	submatches := timeMatcher.FindStringSubmatch(input)
	if len(submatches) != 4 {
		return 0, errors.New("invalid duration")
	}
	hours, err := strconv.ParseInt(submatches[1], 10, 32)
	if err != nil {
		return 0, err
	}
	minutes, err := strconv.ParseInt(submatches[2], 10, 32)
	if err != nil {
		return 0, err
	}
	seconds, err := strconv.ParseInt(submatches[3], 10, 32)
	if err != nil {
		return 0, err
	}
	res := time.Second * time.Duration(seconds)
	res += time.Minute * time.Duration(minutes)
	res += time.Hour * time.Duration(hours)
	return res, nil
}

func generateDurationString(minHours, maxHours, minMinutes, maxMinutes, minSeconds, maxSeconds uint64) string {
	if minHours > 99 || maxHours > 99 || minMinutes > 99 || maxMinutes > 99 || minSeconds > 99 || maxSeconds > 99 {
		panic("You fucked up buddy")
	}
	hourN := maxHours - minHours
	minuteN := maxMinutes - minMinutes
	secondN := maxSeconds - minSeconds
	hour := (rand.Uint64() % hourN) + minHours
	minute := (rand.Uint64() % minuteN) + minMinutes
	second := (rand.Uint64() % secondN) + minSeconds
	return fmt.Sprintf("%02dh-%02dm-%02ds", hour, minute, second)
}

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

func OperationStringToInt[N number](str string) (N, error) {
	switch str {
	case SetString:
		return Set, nil
	case GetString:
		return Get, nil
	case DelString:
		return Del, nil
	case SetCounterString:
		return SetCounter, nil
	case GetCounterString:
		return GetCounter, nil
	case DelCounterString:
		return DelCounter, nil
	default:
		return 0, errors.New("invalid command passed")
	}
}
