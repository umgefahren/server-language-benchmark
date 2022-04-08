package main

import (
	"context"
)

func main() {
	storage := NewStorage()
	ctx := context.TODO()
	err := NewListener(ctx, storage)
	if err != nil {
		panic(err)
	}
}
