package main

func main() {
	err := SetFileDescriptorLimit(-1)

	if err != nil {
		panic(err)
	}

	err = InitLimits()
	if err != nil {
		panic(err)
	}

	OperationConfigFromFlags()
}
