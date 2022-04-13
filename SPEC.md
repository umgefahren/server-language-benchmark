# Specification

Each server implementation shall provide basic functionality of a TCP based Redis-like key-value store.

## Commands

Commands are sent via TCP. Multiple commands can be issued over one connection. The connection is closed by the client at some point. Every command is delimited by a new line character. Every response is delimited by a new line. Commands and responses are UTF-8 encoded.

Every part of the command has to be validated. That includes command names, keys, values and durations, as well as the number of arguments. However the server shall allow leading and trailing horizontal whitespace, i.e. space (`U+0020`) and tab (`U+0009`).

The commands with arguments shall be checked for the right amount of separating spaces (exactly one between each pair of parts) and shall be rejected otherwise.

If the sent line does not match any of the specified commands, the server shall respond with "`invalid command`".

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

The server shall run the `NEWDUMP` command periodically with a configurable interval (changed by the `DUMPINTERVAL` command) and store the result internally. The initial interval at startup shall be set to 10s. The server shall schedule the first recurring dump immediately after starting up, such that the first dump is performed after the interval has elapsed once.

## Parts

### Key / Value

Every key and every value must match the following Regex completely:
```regexp
[a-zA-Z0-9]+
```

For each argument following this convention, the server **shall verify** that key and value match the format and reject the command otherwise. Note that the verification does not have to be performed with Regex.

### Duration

Every duration must match with the following Regex completely:
```regexp
([0-9][0-9])h-([0-5][0-9])m-([0-5][0-9])s
```
Example: `24h-33m-24s` corresponds to 24 hours, 33 minutes and 24 seconds.

### JSON Encoded DUMP

A dump has a specific format:

At the top level it is a JSON Array, where each element represents a key-value pair in the key-value store. A dump with one entry looks like this:

```json
[{"key":"key","associated_value":{"value":"value","timestamp":"2022-04-07T14:27:41.635779Z"}}]
```

The meaning of key and value should be obvious. The timestamp must be a `ISO 8601` formatted timestamp with 6 fraction digits, i.e. with microsecond precision. The time zone is irrelevant. The timestamp represents the moment the key / value pair was created or when it was overwritten (whichever happened last).

## GET

The server shall respond with the value associated with the given key, if there is one. If there is no value associated with this key, the server shall respond with `not found`.

```
GET key
```

Argument `key` must follow the [Key / Value convention](SPEC.md#key--value).


## SET

The server shall respond with the value formerly associated with the given key if there was one. If there was no value associated with this key before, the server shall respond with `not found`.

Upon receiving this command the server shall store the `value` under the given `key`, replacing the previous value if there was one.

```
SET key value
```

Arguments `key` and `value` must follow the [Key / Value convention](SPEC.md#key--value).

## DEL

The server shall respond with the value formerly associated with this key if there was one. If there was no value associated with this key before, the server shall respond with `not found`.

Upon receiving this command the server shall delete the associated `key`-`value` pair if it exists.

```
DEL key
```

Argument `key` must follow the [Key / Value convention](SPEC.md#key--value).

## GETC

The server shall respond with the number of performed `GET` commands since the startup or the last reset of the server (whichever happened last). The counter should be atomic.

```
GETC
```

## SETC

The server shall respond with the number of performed `SET` commands since the startup or the last reset of the server (whichever happened last). The counter should be atomic.

```
SETC
```

## DELC

The server shall respond with the number of performed `DEL` commands since the startup or the last reset of the server (whichever happened last). The counter should be atomic.

```
DELC
```

## NEWDUMP

The server shall respond with a snapshot of the key-value store as a [JSON Encoded DUMP](SPEC.md#json-encoded-dump). However, the snapshot does not need to be a hard clone of the hash map, it is allowed to walk the hashmap while other operations continue (the Go implementation behaves like this).

```
NEWDUMP
```

### GETDUMP

The server shall respond with the latest snapshot created by the [`NEWDUMP`](SPEC.md#newdump) command or by a [recurring dump](SPEC.md#recurring-dumps) (whichever was created last) as a [JSON Encoded DUMP](SPEC.md#json-encoded-dump). If no dump is present, the server shall perform [`NEWDUMP`](SPEC.md#newdump) and return the result.

```
GETDUMP
```

## DUMPINTERVAL

Upon receiving this command the server shall cancel the next scheduled [recurring dump](#recurring-dumps), change the interval at which the recurring dumps are performed to the given `interval`, and schedule the next recurring dump to happen after the new interval has elapsed once.

```
DUMPINTERVAL interval
```

Argument `interval` must be a duration formatted as specified in the [duration convention](SPEC.md#duration).

## SETTTL

The server shall perform a `SET` command immediately and respond with the answer specified in [SET](#set). After `duration`, the server shall remove the `key`-`value` pair from the hashmap. The timer shall start running immediately after the response of `SET` was send (+/- 1s).

```
SETTTL key value duration
```

Arguments `key` and `value` must follow the [Key / Value convention](#key--value) and argument duration the [duration convention](#duration).

## UPLOAD

This command uploads binary data to the server. It shall be stored in a file named `key` inside a temporary directory, which shall be deleted when the [REMOVE](#remove) command is performed with this `key` or when is the server is shut down (whichever happens first).

```
UPLOAD key size
```

Argument `key` must follow the [Key / Value convention](#key--value) and `size` is an unsigned 64-bit integer.

The `UPLOAD` protocol consists of multiple steps (every message is delimited by a newline):

1. The server shall respond with `READY` as soon it is ready to receive the data.
2. The client streams `size` bytes of binary data to the server.
3. The server shall respond with a [SHA-512](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed in hex.
4. The client answers with either `OK` or `ERROR`. If the response is `OK`, the server should do nothing. If it is `ERROR`, the server shall delete the file just created.

If a file named `key` is already present, the server shall overwrite it.

## DOWNLOAD

This command downloads previously saved binary data from the server.

```
DOWNLOAD key
```

Argument `key` must follow the [Key / Value convention](#key--value).

The `DOWNLOAD` protocol consists of multiple steps (every message is delimited by a newline):

1. If the file named `key` exists, the server shall respond with the size of the file named `key` in bytes and with `not found` otherwise.
2. The client responds with `READY` as soon it is ready to receive the transmission.
3. The server shall stream the binary data from the file named `key` to the client.
4. The client responds with a [SHA-512](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed in hex.
5. If the hash from the client matches with the hash the server calculated, the server shall respond with `OK`. Otherwise it shall respond with `ERROR`.

## REMOVE

If a file named `key` exists, the server shall delete it and respond with `DONE`.
Otherwise, the server shall respond with `not found`

```
REMOVE key
```

Argument `key` must follow the [Key / Value convention](#key--value).

## RESET

The server shall discard any state and reset itself to the state it had when it was started. It shall then respond with `DONE`.

```
RESET
```

In particular, the server has to reset:

- The key-value store
- The dump (stored dump & interval)
- Stored files
- The `GET`, `SET` and `DEL` counters
