package main

import (
	"context"
	"strconv"
	"sync"
	"sync/atomic"
)

type State struct {
	clientHashMap sync.Map
	setCounter    *uint64
	getCounter    *uint64
	delCounter    *uint64
}

func NewState() State {
	setC := uint64(0)
	getC := uint64(0)
	delC := uint64(0)
	return State{
		setCounter: &setC,
		getCounter: &getC,
		delCounter: &delC,
	}
}

func (s *State) Set(key, value string) *string {
	var ret *string = nil

	curVal, exists := s.clientHashMap.Load(key)
	if exists {
		curStr := curVal.(string)
		ret = &curStr
	}

	s.clientHashMap.Store(key, value)

	atomic.AddUint64(s.setCounter, 1)

	return ret
}

func (s *State) Get(key string) *string {
	var ret *string = nil

	curVal, exists := s.clientHashMap.Load(key)
	if exists {
		curStr := curVal.(string)
		ret = &curStr
	}

	atomic.AddUint64(s.getCounter, 1)

	return ret
}

func (s *State) Del(key string) *string {
	var ret *string = nil

	curVal, exists := s.clientHashMap.Load(key)
	if exists {
		curStr := curVal.(string)
		ret = &curStr

		s.clientHashMap.Delete(key)
	}

	atomic.AddUint64(s.delCounter, 1)

	return ret
}

func (s *State) SetCounter() uint64 {
	return atomic.LoadUint64(s.setCounter)
}

func (s *State) GetCounter() uint64 {
	return atomic.LoadUint64(s.getCounter)
}

func (s *State) DelCounter() uint64 {
	return atomic.LoadUint64(s.delCounter)
}

func (s *State) PerformPattern(pattern Pattern) string {
	switch pattern.kind {
	case Set:
		tmpStr := s.Set(pattern.key, pattern.value)
		return stringPointerToString(tmpStr)
	case Get:
		tmpStr := s.Get(pattern.key)
		return stringPointerToString(tmpStr)
	case Del:
		tmpStr := s.Del(pattern.key)
		return stringPointerToString(tmpStr)
	case SetCounter:
		tmpCount := s.SetCounter()
		return counterToString(tmpCount)
	case GetCounter:
		tmpCount := s.GetCounter()
		return counterToString(tmpCount)
	case DelCounter:
		tmpCount := s.DelCounter()
		return counterToString(tmpCount)
	default:
		panic("WTF??")
	}
}

type Runner interface {
	SetState(state *State)
	GetState() *State
	Run(patterns []Pattern, general OperationConfig) error
	RunAsync(ctx context.Context, patternChan <- chan []Pattern, general OperationConfig) error
}

func stringPointerToString(input *string) string {
	if input == nil {
		return "not found"
	} else {
		return *input
	}
}

func counterToString(input uint64) string {
	return strconv.FormatUint(input, 10)
}
