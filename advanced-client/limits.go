package main

import (
	"syscall"
)

var (
	fileDescriptorLimit uint64 = 0
)

func InitLimits() error {
	fLimit, err := getFileDescriptorLimit()

	if err != nil {
		return err
	}

	fileDescriptorLimit = fLimit

	return nil
}

func getFileDescriptorLimit() (uint64, error) {
  var rlimit syscall.Rlimit
  err := syscall.Getrlimit(syscall.RLIMIT_NOFILE, &rlimit)
	if err != nil {
		return 0, err
	}

  // rlimit.Cur == soft limit
	return rlimit.Cur, nil
}

func SetFileDescriptorLimit(newLimit int64) error {
  var oldLimit syscall.Rlimit
  err := syscall.Getrlimit(syscall.RLIMIT_NOFILE, &oldLimit)

  if err != nil {
    return err
  }

  softLimit := uint64(newLimit)

  // NOFILE hard limit cannot be increased
  if newLimit < 0 || softLimit > oldLimit.Max {
    softLimit = oldLimit.Max
  }

  rlimit := syscall.Rlimit { Cur: softLimit, Max: oldLimit.Max }
  err = syscall.Setrlimit(syscall.RLIMIT_NOFILE, &rlimit)

	if err != nil {
		return err
	}

	return nil
}
