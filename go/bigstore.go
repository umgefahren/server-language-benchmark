package main

import (
	"bufio"
	"bytes"
	"context"
	"crypto/sha512"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"os/signal"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
)

type BigDataStore struct {
	rootDir         string
	fileIndex       map[string]string
	fileIndexLock   sync.Mutex
	fileCounter     *uint64
	globalIoContext context.Context
	globalCancel    context.CancelFunc
}

func destroyer(sigils <-chan os.Signal, store *BigDataStore) {
	sig := <-sigils

	fmt.Println("Catched signal")
	fmt.Println(sig.String())
	err := store.Cleanup()
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(1)
}

func NewBigDataStore() (*BigDataStore, error) {
	rootDir, err := os.MkdirTemp("", "file-storage")
	if err != nil {
		return nil, err
	}

	counter := uint64(0)

	globalContext, globalCancel := context.WithCancel(context.TODO())

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM, syscall.SIGSEGV, syscall.SIGINT)

	ret := new(BigDataStore)
	ret.rootDir = rootDir
	ret.fileIndex = make(map[string]string)
	ret.fileIndexLock = sync.Mutex{}
	// ret.fileHash = sync.Map{}
	ret.fileCounter = &counter
	ret.globalIoContext = globalContext
	ret.globalCancel = globalCancel
	go destroyer(sigs, ret)
	return ret, nil
}

func (b *BigDataStore) Cleanup() error {
	b.fileIndexLock.Lock()
	defer b.fileIndexLock.Unlock()
	b.globalCancel()
	err := os.RemoveAll(b.rootDir)
	if err != nil {
		return err
	}
	return nil
}

func (b *BigDataStore) Upload(name string, conn io.ReadWriteCloser, size int64) error {
	b.fileIndexLock.Lock()
	current, exists := b.fileIndex[name]
	if exists {
		err := os.Remove(current)
		if err != nil {
			return err
		}
	}
	fileNumber := atomic.AddUint64(b.fileCounter, 1)
	fileName := fmt.Sprintf("%v/%v-%v.bin", b.rootDir, name, fileNumber)

	b.fileIndex[name] = fileName
	newFile, err := os.Create(fileName)
	if err != nil {
		return err
	}
	closed := false
	keep := false
	defer func() {
		if !closed {
			err = newFile.Close()
		}
		if !keep {
			err = os.Remove(newFile.Name())
		}
	}()
	b.fileIndexLock.Unlock()
	_, err = conn.Write([]byte("READY\n"))
	if err != nil {
		return err
	}
	hashValue, err := b.CopySmart(conn, newFile, size)
	if err != nil {
		return err
	}

	closed = true
	err = newFile.Sync()
	if err != nil {
		return err
	}
	err = newFile.Close()
	if err != nil {
		return err
	}
	encoder := base64.NewEncoder(base64.StdEncoding, conn)
	_, err = encoder.Write(hashValue)
	if err != nil {
		return err
	}
	err = encoder.Close()
	if err != nil {
		return err
	}
	_, err = conn.Write([]byte("\n"))
	if err != nil {
		return err
	}
	bufReader := bufio.NewReader(conn)
	clientLine, err := bufReader.ReadString('\n')
	if err != nil {
		return err
	}
	switch clientLine {
	case "OK\n":

		keep = true
		return nil
	case "ERROR\n":
		err := os.Remove(newFile.Name())
		if err != nil {
			return err
		}
		return nil
	}

	return errors.New("unexpected client response")
}

func (b *BigDataStore) CopySmart(conn io.ReadCloser, file io.WriteCloser, size int64) ([]byte, error) {
	fileBuff := bufio.NewWriter(file)
	connBuff := bufio.NewReader(conn)

	hashResult := make(chan []byte, 1)
	errorResult := make(chan error, 1)
	copyDone := make(chan error, 1)

	hasher := sha512.New512_256()
	multiWriter := io.MultiWriter(hasher, fileBuff)
	go func() {
		err := <-copyDone
		if err != nil {
			errorResult <- err
			return
		}
		hashResult <- hasher.Sum(make([]byte, 0))
	}()
	go func() {
		_, err := io.CopyN(multiWriter, connBuff, size)
		copyDone <- err
		return
	}()

	select {
	case err := <-errorResult:
		return nil, err
	case hash := <-hashResult:
		fileBuff.Flush()
		return hash, nil
	case <-b.globalIoContext.Done():
		file.Close()
		conn.Close()
		return nil, nil
	}
}

func (b *BigDataStore) Download(name string, conn io.ReadWriteCloser) error {
	b.fileIndexLock.Lock()
	fileName, exists := b.fileIndex[name]
	if !exists {
		_, err := conn.Write([]byte("not found\n"))
		if err != nil {
			return err
		}
	}
	b.fileIndexLock.Unlock()

	file, err := os.Open(fileName)
	if err != nil {
		return err
	}

	defer file.Close()

	stats, err := file.Stat()

	if err != nil {
		return err
	}

	size := stats.Size()

	_, err = conn.Write([]byte(fmt.Sprintf("%v\n", size)))

	if err != nil {
		return err
	}

	connReader := bufio.NewReader(conn)

	clientLine, err := connReader.ReadString('\n')

	if err != nil {
		return err
	}

	if clientLine != "READY\n" {
		return InvalidCommand
	}

	hash, err := b.CopySmart(file, conn, size)
	if err != nil {
		return err
	}
	_, err = conn.Write([]byte("\n"))
	if err != nil {
		return err
	}
	clientLine, err = connReader.ReadString('\n')
	if err != nil {
		return err
	}
	clientLine = strings.TrimSuffix(clientLine, "\n")

	decoder := base64.StdEncoding
	clientHash, err := decoder.DecodeString(clientLine)
	if err != nil {
		return err
	}
	if bytes.Compare(hash, clientHash) == 0 {
		_, err = conn.Write([]byte("OK\n"))
		if err != nil {
			return err
		}
	} else {
		_, err := conn.Write([]byte("ERROR\n"))
		if err != nil {
			return err
		}
	}
	return nil
}

func (b *BigDataStore) Remove(key string) (string, error) {
	b.fileIndexLock.Lock()
	fileName, exists := b.fileIndex[key]
	defer b.fileIndexLock.Unlock()
	if !exists {
		return "not found", nil
	}
	delete(b.fileIndex, key)
	err := os.Remove(fileName)
	if err != nil {
		return "", err
	}
	return "", nil
}
