# Specification

Each server impementation has to provide basic functionality of a TCP based Redis-like key value store.

## Commands

Commands are sent via Tcp. Multiple commands can be issued over one connection. The connection is closed by the client at some point. Every command is delimited by a new line character. Every response is delimited by a new line. Commands and responses are UTF-8 encoded.

Every part of the command has to be validated. That includes command names, keys, values and durations, as well as the number of arguments. However the server should allow leading and trailing whitespace.

The commands with arguments should be checked for the right amount of seperating spaces (one between each pair of parts) and be rejected otherwise.

If the sent line does not match any of the specified commands, the server should respond with "`invalid command`".

Essential commands:

* [GET](SPEC.md#get)
* [SET](SPEC.md#set)
* [DEL](SPEC.md#del)
* [GETC](SPEC.md#getc)
* [SETC](SPEC.md#setc)
* [DELC](SEPC.md#delc)

Dumping commands:

* [NEWDUMP](#newdump)
* [GETDUMP](#getdump)
* [DUMPINTERVAL](#dumpinterval)

Delay commands:

* [SETTTL](#setttl)

Heavy load commands:

* [UPLOAD](#upload)
* [DOWNLOAD](#download)
* [REMOVE](#remove)

Maintenance commands:

* [RESET](#reset)

## Recurring dumps

The server should run the NEWDUMP command in a configurable interval (changed by the `DUMPINTERVAL` command) and store the result internally. The initial interval is 10s. The server should start the interval immediately and make the first dump the first time the interval is reached.

### Parts

#### Key / Value

Every key and has to match the following Regex completely:
```regexp
[a-zA-Z0-9]+
```

The server **has to verify** that key and value match the format and reject the command otherwise. Note that the verification does not have to be performed with Regex.

#### Duration

Every duration has to match with the following Regex completely:
```regexp
([0-9][0-9])h-([0-5][0-9])m-([0-5][0-9])s
```
Example: `24h-33m-24s` corresponds to 24 hours, 33 minutes and 24 seconds.

#### JSON Encoded DUMP

A dump has a specific format:

At the top level it is a JSON Array, where each element represents a key-value pair in the Hash Map. A dump with one entry looks like this:

```json
[{"key":"key","associated_value":{"value":"value","timestamp":"2022-04-07T14:27:41.635779Z"}}]
```

The meaning of key and value should be obvious. The timestamp has to be a ISO 8601 formatted timestamp with 6 fraction digits. The time zone is irrelevant. The timestamp represents the moment the key / value pair was created or when it was overwritten (whatever happend later).

### GET

The server should respond with the value associated with this key, if it exits. If the value does not exist, the server should respond with `not found`.

```
GET key
```

`key` has to follow the [Key / Value convention](SPEC.md#key--value).


### SET

The server should respond with the value formerly associated with this key if it exists. If the value did not exist before, the server should respond with `not found`.

This command stores the `value` under the given `key`.

```
SET key value
```

`key` and `value` have to follow the [Key / Value convention](SPEC.md#key--value).

### DEL

The server should respond with the value formerly associated with this key if it exists. If the value did not exist before, the server should respond with `not found`.

This command deletes the associated `key` `value` pair if it exists.

```
DEL key
```

`key` has to follow the [Key / Value convention](SPEC.md#key--value).

### GETC

Returns the number of performed `GET` commands. (The counter should be atomic)

```
GETC
```

### SETC

Returns the number of performed `SET` commands. (The counter should be atomic)

```
SETC
```

### DELC

Returns the number of performed `DEL` commands. (The counter should be atomic)

```
DELC
```

### NEWDUMP

Returns a snaphsot of the key-value store as a [JSON Encoded DUMP](SPEC.md#json-encoded-dump). However the Snapshot does not need to be a hard clone of the hash map, it is allowed to walk the hashmap while other operations continue (the Go implementation behaves like this).

```
NEWDUMP
```

### GETDUMP

Returns the latest snapshot created by the [`NEWDUMP`](SPEC.md#newdump) command by the [recuring dump](SPEC.md#recurring-dumps). If no dump is present, perform [`NEWDUMP`](SPEC.md#newdump) and return the result.

```
GETDUMP
```

### DUMPINTERVAL

This command changes the interval at which dumps are performed by the [recurring dumper](#recurring-dumps). There should only be one dumper running at any point in time.
Upon receiving `DUMPINTERVAL`, the server should cancel the existing dumping interval and schedule the next recurring dump to happen after the new interval has elapsed once.

```
DUMPINTERVAL interval
```

`interval` is a duration formatted as specified in the [duration convention](SPEC.md#duration).

### SETTTL

The server should perform a `SET` command immediately and respond with the answer specified in [SET](#set). After `duration`, the server should remove the `key-value` pair from the hashmap. The timer should start running immediately after the response of `SET` was send (+/- 1s).

```
SETTTL key value duration
```

`key` and `value` have to follow the [Key / Value conventeion](#key--value) and duration the [duration convention](#duration).

### UPLOAD

This command uploads binary data to the server. It should be stored in a file inside a temporary directory and be removed when the server is shut down.

```
UPLOAD key size
```

`key` has to follow the [Key / Value convention](#key--value) and `size` is an unsigned 64-bit integer.

The `UPLOAD` protocol consists of multiple steps (Every message is delimited by a newline):

1. The server sends with `READY` as soon it is ready to receive the data.
2. The client streams `size` bytes of binary data.
3. The server responds with a [SHA-512](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed in hex.
4. The client awnsers with `OK` or `ERROR`. If the response is `OK`, the server does nothing. If it is `ERROR`, the server should delete the file just created.

If there is already a file present with this key, the server should overwrite it.

### DOWNLOAD

This command downloads previously saved binary data from the server.

```
DOWNLOAD key
```

`key` has to follow the [Key / Value convention](#key--value).

The `DOWNLOAD` protocol consists of multiple steps (Every message is delimited by a newline):

1. If the file `key` exists, the server sends the size of the file stored under `key` in bytes and `not found` otherwise.
2. The client responds with `READY` as soon it is ready to receive the transmission.
3. The server streams the binary data from the file `key` to the client.
4. The client responds with a [SHA-512](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed in hex.
5. If the hash from the client matches with the hash the server calculated, the server responds with `OK` or `ERROR` otherwise.

### REMOVE

If a file named `key` exists, the server should delete it and respond with `DONE`.
Otherwise, the server should respond with `not found`

```
REMOVE key
```

`key` has to follow the [Key / Value convention](#key--value).

### RESET

The server should discard any state and reset itself to the state it had when it was started. It should then respond with `DONE`.

```
RESET
```

In particular, the server has to reset:

- The key-value store
- The dump (stored dump & interval)
- Stored files
- The `GET`, `SET` and `DEL` counters
