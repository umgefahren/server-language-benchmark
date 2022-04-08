package main

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

const initialInterval = time.Second * 10

type Value struct {
	Value     string    `json:"value"`
	Timestamp time.Time `json:"timestamp"`
}

type Pair struct {
	Key   string `json:"key"`
	Value Value  `json:"associated_value"`
}

type Storage struct {
	content      *sync.Map
	setCounter   *uint64
	getCounter   *uint64
	delCounter   *uint64
	dumpContent  []byte
	dumpLock     sync.RWMutex
	dumperLock   sync.Mutex
	dumperCancel context.CancelFunc
}

func dumpingProcess(ctx context.Context, s *Storage, ticker *time.Ticker) {
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.dumperLock.Lock()
			s.NewDump()
			s.dumperLock.Unlock()
			// fmt.Println("Dumped automatically")
		}
	}
}

func NewStorage() *Storage {
	setCounterTmp := uint64(0)
	getCounterTmp := uint64(0)
	delCounterTmp := uint64(0)
	ctx, cancel := context.WithCancel(context.TODO())
	ticker := time.NewTicker(initialInterval)
	ret := &Storage{
		content:      &sync.Map{},
		setCounter:   &setCounterTmp,
		getCounter:   &getCounterTmp,
		delCounter:   &delCounterTmp,
		dumperCancel: cancel,
	}
	go dumpingProcess(ctx, ret, ticker)
	return ret
}

func (s *Storage) ChangeInterval(d time.Duration) {
	s.dumperLock.Lock()
	defer s.dumperLock.Unlock()
	s.dumperCancel()
	ctx, cancel := context.WithCancel(context.TODO())
	s.dumperCancel = cancel
	ticker := time.NewTicker(d)
	go dumpingProcess(ctx, s, ticker)
}

func (s *Storage) Set(key, value string) string {
	tmpCurrentVal, _ := s.content.Load(key)
	ret := "not found"
	defer atomic.AddUint64(s.setCounter, 1)
	if tmpCurrentVal != nil {
		retS := tmpCurrentVal.(Value)
		ret = retS.Value
	}
	sValue := Value{
		Value:     value,
		Timestamp: time.Now(),
	}
	s.content.Store(key, sValue)
	return ret
}

func (s *Storage) Get(key string) string {
	tmpRetVal, ok := s.content.Load(key)
	defer atomic.AddUint64(s.getCounter, 1)
	if ok {
		retS := tmpRetVal.(Value)
		casted := retS.Value
		return casted
	}
	return "not found"
}

func (s *Storage) Delete(key string) string {
	tmpRetVal, ok := s.content.LoadAndDelete(key)
	defer atomic.AddUint64(s.delCounter, 1)
	if ok {
		casted := tmpRetVal.(Value)
		return casted.Value
	}
	return "not found"
}

func (s *Storage) GetCounter() uint64 {
	return atomic.LoadUint64(s.getCounter)
}

func (s *Storage) SetCounter() uint64 {
	return atomic.LoadUint64(s.setCounter)
}

func (s *Storage) DelCounter() uint64 {
	return atomic.LoadUint64(s.delCounter)
}

func (s *Storage) SetTTL(d time.Duration, key, value string) string {
	ret := s.Set(key, value)
	timer := time.NewTimer(d)
	fmt.Println("Spawning with ttl")
	go func() {
		<-timer.C
		fmt.Println("Deleting after TTL")
		s.Delete(key)
	}()
	return ret
}

func (s *Storage) NewDump() ([]byte, error) {
	// tabw := tabwriter.NewWriter(os.Stdout, 0, 0, 1, ' ', tabwriter.Debug)
	// fmt.Fprintln(tabw, "KEY\tVALUE")
	list := make([]Pair, 0)
	s.content.Range(func(key, value any) bool {
		keyS := key.(string)
		valS := value.(Value)
		// fmt.Fprintf(tabw, "%v\t%v\n", keyS, valS.Value)
		pair := Pair{
			Key:   keyS,
			Value: valS,
		}
		list = append(list, pair)
		return true
	})
	// tabw.Flush()
	jsonBytes, err := json.Marshal(list)
	if err != nil {
		return nil, err
	}
	copiedBytes := make([]byte, len(jsonBytes))
	copy(copiedBytes, jsonBytes)
	s.dumpLock.Lock()
	s.dumpContent = copiedBytes
	s.dumpLock.Unlock()
	return jsonBytes, nil
}

func (s *Storage) GetDump() ([]byte, error) {
	s.dumpLock.RLock()
	if len(s.dumpContent) == 0 {
		s.dumpLock.RUnlock()
		return s.NewDump()
	}
	defer s.dumpLock.RUnlock()
	outBytes := make([]byte, len(s.dumpContent))
	copy(outBytes, s.dumpContent)
	return outBytes, nil
}
