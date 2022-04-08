# Swift implementation

To execute the Swift implementation just execute `swift run -c=release`. This will start the server on port 8080.


## Running in Docker

To run the server in a docker container, first build the image using

```bash
docker build -t bench-swift .
```

Now you can create a docker container using

```bash
docker create --name bench-swift -p 8080:8080 bench-swift
```

Finally, you can run the server using either

```bash
docker run -dp 8080:8080 bench-swift
```

for running in detached mode, or

```bash
docker run -tp 8080:8080 bench-swift
```

if you want to see the server output.
