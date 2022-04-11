package main

import (
	"bufio"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"time"
)

const Gigabyte = 1_000_000_000

type WriterFlusher interface {
	io.Writer
	Flush() error
}

type GeneralDataConfig struct {
	TotalDuration     float64 `json:"total-duration"`
	ServerHostname    string  `json:"server-hostname"`
	ServerPort        int     `json:"server-port"`
	CommandsPerConn   int     `json:"commands-per-conn"`
	BasicDataFilename string  `json:"basic-data-filename"`
}

func NewGeneralDataConfig(config *BenchmarkConfig, basicDataFilename string) GeneralDataConfig {
	return GeneralDataConfig{
		TotalDuration:     config.General.TotalDuration,
		ServerHostname:    config.General.ServerHostname,
		ServerPort:        config.General.ServerPort,
		CommandsPerConn:   config.General.CommandsPerConn,
		BasicDataFilename: basicDataFilename,
	}
}

type BasicDataConfig struct {
	CycleDuration float64 `json:"cycle-duration"`
	Cycles        int     `json:"cycles"`
}

func NewBasicDataConfig(config *BenchmarkConfig, cycles int) BasicDataConfig {
	return BasicDataConfig{
		CycleDuration: config.Basic.CycleDuration,
		Cycles:        cycles,
	}
}

type JsonPattern struct {
	Kind     string
	Key      string
	Value    string
	duration *time.Duration
	path     string
}

func PatternsToJsonPatterns(patterns []Pattern) []JsonPattern {
	ret := make([]JsonPattern, len(patterns))
	for i, pattern := range patterns {
		jsonPattern := JsonPattern{
			Kind:     OperationIntToString(pattern.kind),
			Key:      pattern.key,
			Value:    pattern.value,
			duration: pattern.duration,
			path:     pattern.path,
		}
		ret[i] = jsonPattern
	}
	return ret
}

func isDirectory(input string) bool {
	return path.Ext(input) == ""
}

func generateData(benchmarkConfig *BenchmarkConfig, basicFile io.Writer, cyclePattern []uint, gbAmount float64, basicCycles *int) error {
	outDataAmount := int64(0)
	amount := int64(gbAmount * float64(Gigabyte))
	virtualSecond := 0.0
	virtualBasicSecond := 0.0

	ctx, cancel := context.WithCancel(context.TODO())

	basicChan := make(chan []byte, 100)
	go func() {
		for {
			jsonPatterns := PatternsToJsonPatterns(DerivePatternsFromCyclePattern(cyclePattern))

			jsonBytes, err := json.Marshal(&jsonPatterns)
			if err != nil {
				panic(err)
			}
			basicChan <- append(jsonBytes, []byte("\n")...)
			select {
			case <-ctx.Done():
				return
			default:
				continue
			}
		}
	}()

	for {
		if outDataAmount > amount {
			cancel()
			break
		}

		if virtualBasicSecond > benchmarkConfig.Basic.CycleDuration {
			jsonBytes := <-basicChan

			addAmount, err := basicFile.Write(jsonBytes)
			if err != nil {
				cancel()
				return err
			}

			outDataAmount += int64(addAmount)

			*basicCycles += 1

			virtualBasicSecond = 0
		}

		virtualSecond += 1.0
		virtualBasicSecond += 1.0

	}
	return nil
}

func NewDataGeneration(benchmarkConfig *BenchmarkConfig, outPath string, amount float64, compress bool) {
	fmt.Println("Switching into logging mode")

	basicCyclePattern, err := parseCyclePattern(benchmarkConfig.Basic.CyclePattern)
	if err != nil {
		log.Fatalln("Error parsing cycle pattern", err, benchmarkConfig.Basic.CyclePattern)
	}

	if !isDirectory(outPath) {
		log.Fatalln("Given output path for benchmark generation is invalid")
	}

	err = os.MkdirAll(outPath+"/basic", 0700)
	if err != nil && !os.IsExist(err) {
		log.Fatalln("Error during output directory generation", err)
	}

	generalDataPath := "general.json"
	basicDataPath := "basic/basic.json"

	generalDataConfig := NewGeneralDataConfig(benchmarkConfig, basicDataPath)

	generalDataCompletePath := path.Clean(outPath) + "/" + generalDataPath

	generalDataFile, err := os.Create(generalDataCompletePath)

	if err != nil {
		log.Fatalln("Error creating general data file", err)
	}

	generalDataEncoder := json.NewEncoder(generalDataFile)
	generalDataEncoder.SetIndent("", "\t")
	err = generalDataEncoder.Encode(&generalDataConfig)
	if err != nil {
		closeErr := generalDataFile.Close()
		if closeErr != nil {
			log.Println("close error", closeErr)
		}
		log.Fatalln("Error creating and writing general file", err)
	}

	err = generalDataFile.Sync()
	if err != nil {
		log.Fatalln("error syncing file", err)
	}
	err = generalDataFile.Close()
	if err != nil {
		log.Fatalln("error closing file", err)
	}

	basicDataDataPath := "basic/data.bin"
	if compress {
		basicDataDataPath += ".gz"
	}
	basicDataDataFile, err := os.Create(path.Clean(outPath) + "/" + basicDataDataPath)
	if err != nil {
		log.Fatalln(err)
	}

	basicCycles := 0

	buffered := bufio.NewWriter(basicDataDataFile)

	var passingWriter WriterFlusher = buffered

	if compress {
		passingWriter, err = gzip.NewWriterLevel(buffered, gzip.BestCompression)
		if err != nil {
			log.Fatalln("Error creating new compressor", err)
		}
	}

	err = generateData(benchmarkConfig, passingWriter, basicCyclePattern, amount, &basicCycles)
	if err != nil {
		log.Fatalln(err)
	}

	err = passingWriter.Flush()
	if err != nil {
		log.Fatalln(err)
	}

	err = basicDataDataFile.Sync()
	if err != nil {
		log.Fatalln(err)
	}
	err = basicDataDataFile.Close()
	if err != nil {
		log.Fatalln(err)
	}

	basicDataConfigFile, err := os.Create(path.Clean(outPath) + "/" + basicDataPath)
	if err != nil {
		log.Fatalln("Error creating basic data file", err)
	}

	basicDataConfig := NewBasicDataConfig(benchmarkConfig, basicCycles)
	jsonByte, err := json.Marshal(&basicDataConfig)
	if err != nil {
		panic(err)
	}
	_, err = basicDataConfigFile.Write(jsonByte)
	if err != nil {
		log.Fatalln(err)
	}
	err = basicDataConfigFile.Sync()
	if err != nil {
		log.Fatalln(err)
	}
	err = basicDataConfigFile.Close()
	if err != nil {
		log.Fatalln(err)
	}
}
