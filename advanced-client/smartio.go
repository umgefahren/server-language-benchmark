package main

import (
	"errors"
	"io"
	"sync/atomic"
	"time"
)

const ioSize = 4096

type MeasurePoint struct {
	readBytes    int
	readDuration time.Duration
}

type bytesAndError struct {
	err         error
	transferred int
}

type IoMeasurer struct {
	readSpeed        chan MeasurePoint
	writeSpeed       chan MeasurePoint
	allReadSpeed     chan MeasurePoint
	allWriteSpeed    chan MeasurePoint
	doneChan         chan bytesAndError
	startTime        time.Time
	totalDuration    time.Duration
	bytesTransferred *uint64
	bytesSize        int
	isDone           *uint32
}

func goRoutineIoMeasurer[R io.Reader, W io.Writer](measurer *IoMeasurer, reader R, writer W) {
	buffer := make([]byte, measurer.bytesSize)
	totalTransferred := 0
	defer measurer.setDone()
	measurer.startTime = time.Now()
	for {
		readStart := time.Now()
		n, err := reader.Read(buffer)
		readDuration := time.Since(readStart)
		if errors.Is(err, io.EOF) {
			measurer.doneChan <- bytesAndError{nil, totalTransferred}
			return
		} else if err != nil {
			measurer.doneChan <- bytesAndError{err, totalTransferred}
			return
		}
		readPoint := MeasurePoint{n, readDuration}
		measurer.readSpeed <- readPoint
		writeStart := time.Now()
		n, err = writer.Write(buffer[:n])
		writeDuration := time.Since(writeStart)
		if err != nil {
			measurer.doneChan <- bytesAndError{err, totalTransferred}
			return
		}
		writePoint := MeasurePoint{n, writeDuration}
		measurer.writeSpeed <- writePoint
		totalTransferred += n
		atomic.AddUint64(measurer.bytesTransferred, uint64(n))
	}
}

func NewIoMeasurer[R io.Reader, W io.Writer](reader R, writer W) IoMeasurer {
	readSpeed := make(chan MeasurePoint)
	writeSpeed := make(chan MeasurePoint)
	allReadSpeed := make(chan MeasurePoint)
	allWriteSpeed := make(chan MeasurePoint)
	doneChan := make(chan bytesAndError)
	bytesTransferred := uint64(0)
	isDone := uint32(0)
	measurer := IoMeasurer{readSpeed: readSpeed, writeSpeed: writeSpeed, doneChan: doneChan, allReadSpeed: allReadSpeed, allWriteSpeed: allWriteSpeed, bytesTransferred: &bytesTransferred, isDone: &isDone, bytesSize: ioSize}
	go goRoutineIoMeasurer(&measurer, reader, writer)
	return measurer
}

func (i IoMeasurer) Done() (int, error) {
	res := <-i.doneChan

	if !(len(i.readSpeed) == 0) {
		for {
			val := <-i.readSpeed
			i.allReadSpeed <- val
			if len(i.readSpeed) == 0 {
				break
			}
		}
	}

	if !(len(i.writeSpeed) == 0) {
		for {
			val := <-i.writeSpeed
			i.allWriteSpeed <- val
			if len(i.writeSpeed) == 0 {
				break
			}
		}
	}

	return res.transferred, res.err
}

func (i IoMeasurer) GetRead() *MeasurePoint {
	if i.isAlreadyDone() {
		return nil
	}
	ret := <-i.readSpeed
	i.allReadSpeed <- ret
	if len(i.readSpeed) == 0 {
		return &ret
	}
	for val := range i.readSpeed {
		ret = val
		i.allReadSpeed <- val
		if len(i.readSpeed) == 0 {
			break
		}
	}
	return &ret
}

func (i IoMeasurer) GetWrite() *MeasurePoint {
	if i.isAlreadyDone() {
		return nil
	}

	ret := <-i.writeSpeed
	i.allWriteSpeed <- ret
	if len(i.writeSpeed) == 0 {
		return &ret
	}
	for val := range i.writeSpeed {
		ret = val
		i.allWriteSpeed <- val
		if len(i.writeSpeed) == 0 {
			break
		}
	}
	return &ret
}

func (i IoMeasurer) transferred() uint64 {
	return atomic.LoadUint64(i.bytesTransferred)
}

func (i IoMeasurer) averageSpeed() float64 {
	val := i.transferred()
	duration := time.Since(i.startTime)
	seconds := duration.Seconds()
	return float64(val) / seconds
}

func (i IoMeasurer) isAlreadyDone() bool {
	currentVal := atomic.LoadUint32(i.isDone)
	if currentVal > 0 {
		return true
	}
	return false
}

func (i *IoMeasurer) setDone() {
	i.totalDuration = time.Since(i.startTime)
	atomic.AddUint32(i.isDone, 1)
}

func (m *MeasurePoint) Speed() float64 {
	bytesTransferred := float64(m.readBytes)
	duration := m.readDuration.Seconds()
	return bytesTransferred / duration
}
