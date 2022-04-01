package main

import (
	"context"
	"fmt"
)

func main() {
	fmt.Println("Hello World")
	storage := NewStorage()
	ctx := context.TODO()
	err := NewListener(ctx, storage)
	if err != nil {
		panic(err)
	}
}
