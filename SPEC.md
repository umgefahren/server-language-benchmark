# Specification

The server has to implement the basic functionality of a TCP based Redis-like key value store. It is important that the operations happen **in Order** without bad-interleaving.

## Commands

Commands are sent via Tcp. Multiple commands can be issued over one connection. The connection is closed by the client. Every command is delimited by a new line character. Every response is delimited by a new line. Commands and responses are UTF-8 encoded.

Every part of the command has to be checked **in total**. That means validity of keys, values and durations, as well as if the right number of arguments were supplied. However the server should allow leading and trailing whitespace.

The commands with arguments should be checked for the right amount of seperating spaces (one between parts) and get rejected otherwise.

If the sent line is not one of the commands specified, respond with "`invalid command`".

The essential commands are:

* [GET](SPEC.md#get)
* [SET](SPEC.md#set)
* [DEL](SPEC.md#del)
* [GETC](SPEC.md#getc)
* [SETC](SPEC.md#setc)
* [DELC](SEPC.md#delc)

The dumping commands are:

* [NEWDUMP](#newdump)
* [GETDUMP](#getdump)
* [DUMPINTERVAL](#dumpinterval)

The delayed commands are:

* [SETTTL](#setttl)

The heavy load commans are:

* [UPLOAD](#upload)
* [DOWNLOAD](#download)
* [REMOVE](#remove)

## Recurring dumps

The server should run the NEWDUMP command in a changing interval (changed by the `DUMPINTERVAL` command) and store the result internally. The initial interval is 10s.

### Parts

#### Key / Value

Every key and has to match **in total** with the following Regex:
```regexp
[a-zA-Z0-9]+
```

The server **has to verify** that key and value correspond to the requirenment and reject the command otherwise. Although the verification doesn't have to performed with Regex.

#### Duration

Every duration has to match **in total** with the following Regex:
```regexp
([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9][0-9])s
```
The extraction of hours, minutes and seconds should be obvious.

#### JSON Encoded DUMP

A dump has to be returned in the specified way.

At the top level it has to be a JSON Array, with each element representing a key-value pair in the Hash Map. Each entry has to be formed like the following example:

```json
{"key":"key","associated_value":{"value":"value","timestamp":"2022-04-07T14:27:41.635779Z"}}
```

The definition of key and value should be obvious. The timestamp has to be a ISO 8601 formatted timestamps with at least 10^-6 seconds precision. The time zone is irrelevant. The timestamp represents the moment the key / value pair was created or when it was overwritten (whatever happend later).

### GET

The GET command is specified as following

```
GET key
```

where `key` has to follow the [Key / Value convention](SPEC.md#key--value).

The server has to respond with the value associated with this key, if it exits. If the value doesn't exist respond with `not found`.

### SET

The SET command is specified as following

```
SET key value
```

where `key` and `value` have to follow the [Key / Value convention](SPEC.md#key--value).

The server has to respond with the value formerly associated with this key, if it exists. If the value doesn't exist respond with `not found`.

This command stores the `value` with the corresponding `key`.

### DEL

The DEL command is specified as following

```
DEL key
```

where `key` has to follow the [Key / Value convention](SPEC.md#key--value).

The server has to respond with the value formerly associated with this key, if it exists. If the value doesn't exist respond with `not found`.

This command deletes the associated `key` `value` pair if it exists.

### GETC

The GETC command is specified as following

```
GETC
```

Returns the number of performed `GET` commands. (The counter should be atomic)

### SETC

The SETC command is specified as following

```
SETC
```

Returns the number of performed `SET` commands. (The counter should be atomic)

### DELC

The DELC command is specified as following

```
DELC
```

Returns the number of performed `DEL` commands. (The counter should be atomic)

### NEWDUMP

The NEWDUMP command is specified as following

```
NEWDUMP
```

Returns a snaphsot of the key-value store JSON encoded. However the Snapshot doesn't need to be a hard clone of the hole hash map. It's allowed to walk the hashmap while other operations continue (the Go implementation implements this behaviour).

The return string should be a [JSON Encoded DUMP](SPEC.md#json-encoded-dump) (obviously the just created dump).

### GETDUMP

The GETDUMP command is specified as following

```
GETDUMP
```

Returns the latest snapshot created by the latest [`NEWDUMP`](SPEC.md#newdump) command or a dump created by the [recuring dump](SPEC.md#recurring-dumps). If no dump is present, perform [`NEWDUMP`](SPEC.md#newdump) and return the result.

### DUMPINTERVAL

The DUMPINTERVAL command is specified as following

```
DUMPINTERVAL interval
```

where `interval` is a duration formatted like the standard [duration convention](SPEC.md#duration).

This command changes the interval at which dumps are performed by the [recurring dumper](#recurring-dumps). There should be running **only one dumper** at any point of time.

### SETTTL

The SETTTL command is specified as following

```
SETTTL key value duration
```

where `key` and `value` conform to the [Key / Value conventeion](#key--value) and duration conforms to the [duration convention](#duration).

The server should perform a `SET` command immediatly and respond with the awnsers specified in [SET](#set). After `duration` the server should remove the `key` from the hashmap. The time should start running at about the time (+/- 1s) when the response of `SET` was send.

### UPLOAD

The UPLOAD command is specified as following

```
UPLOAD key size
```

where `key` conforms to the [Key / Value convention](#key--value) and `size` is an unsigned long long (the C type) without leading zeros.

The server should respond with `READY` (with trailing newline) as soon it's ready.

After that the client streams binary data with `size` bytes. `size` always exceeds the amount of memory available to the server, thus a storage in memory is not feasible. Instead a storage in a file is strongly suggested.

After the transmission is completed the server should respond with a base64 encoded [SHA-512/256](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed.

The client now awnsers with `OK` or `ERROR` (with trailing newline). If the response is `OK`, everything is done here. If it's `ERROR` delete the file just created, everything is done here.

If there is already a file present with this key, delete it.

### DOWNLOAD

The DOWNLOAD command is specified as following

```
DOWNLOAD key
```

where `key` conforms to the [Key / Value convention](#key--value).

The server should respond with the size of the file stored under `key` with a trailing newline or with `not found` otherwise.

The client responds with `READY` (with trailing newline) as soon it's ready to receive the transmission.

The server now streams the binary data found at `key` to the client.

The client responds with a base64 encoded [SHA-512/256](https://csrc.nist.gov/publications/detail/fips/180/4/final) hash of the data that was streamed.

If the hash of the client matches up with the hash the server calculated, return `OK`. Return `ERROR` otherwise.


### REMOVE

The REMOVE command is specified as following

```
REMOVE key
```

where `key` conforms to the [Key / Value convention](#key--value).

The server should delete the file associated with `key` if present and return `not found` otherwise.