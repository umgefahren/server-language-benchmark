package main

import (
	"context"
)

func main() {
	storage := NewStorage()
	big, err := NewBigDataStore()
	if err != nil {
		panic(err)
	}
	ctx := context.TODO()
	err = NewListener(ctx, storage, big)
	if err != nil {
		panic(err)
	}
}
