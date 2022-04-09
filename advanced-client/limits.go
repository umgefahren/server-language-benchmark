package main

import (
	"bufio"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

var (
	fileDescriptorLimit int64 = 0
)

func InitLimits() error {
	fLimit, err := getFileDescriptorLimit()
	if err != nil {
		return err
	}
	fileDescriptorLimit = fLimit

	return nil
}

func getFileDescriptorLimit() (int64, error) {
	ulimitCommand := exec.Command("ulimit", "-Sn")
	ulimitOut, err := ulimitCommand.StdoutPipe()
	if err != nil {
		return 0, err
	}
	err = ulimitCommand.Start()
	if err != nil {
		return 0, err
	}
	reader := bufio.NewReader(ulimitOut)
	outLine, err := reader.ReadString('\n')
	if err != nil {
		return 0, err
	}

	err = ulimitCommand.Wait()
	if err != nil {
		return 0, err
	}

	outLine = strings.TrimSuffix(outLine, "\n")
	softLimit, err := strconv.ParseInt(outLine, 10, 64)
	if err != nil {
		return 0, err
	}
	return softLimit, nil
}

func SetFileDescriptorLimit(newLimit int64) error {
	newLimitString := fmt.Sprint(newLimit)
	if newLimit < 0 {
		newLimitString = "unlimited"
	}

	ulimitCommand := exec.Command("ulimit", "-Sn", newLimitString)
	err := ulimitCommand.Start()
	if err != nil {
		return err
	}
	err = ulimitCommand.Wait()
	if err != nil {
		return err
	}

	return nil
}
