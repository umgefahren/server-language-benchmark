package main

import "log"

func main() {
	makeSearchRunes()

	err := SetFileDescriptorLimit(-1)

	if err != nil {
		panic(err)
	}

	err = InitLimits()
	if err != nil {
		panic(err)
	}

	operationConf := OperationConfigFromFlags()
	err = PerformOperation(operationConf)
	if err != nil {
		log.Fatalln(err)
	}
}
