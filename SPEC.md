# Specification

The server has to implement the basic functionality of a TCP based Redis-like key value store. It is important that the operations happen **in Order** without bad-interleaving.

## Commands

Commands are sent via Tcp. Multiple commands can be issued over one connection. The connection is closed by the client. Every command is delimited by a new line character. Every response is delimited by a new line. Commands and responses are UTF-8 encoded.

Every part of the command has to be checked **in total**. That means validity of keys, values and durations, as well as if the right number of arguments were supplied.

If the sent line is not one of the commands specified, respond with "`invalid command`".

The essential commands are:

* [GET](SPEC.md#get)
* [SET](SPEC.md#set)
* [DEL](SPEC.md#del)
* [GETC](SPEC.md#getc)
* [SETC](SPEC.md#setc)
* [DELC](SEPC.md#delc)

### Parts

#### Key / Value

Every key and has to match **in total** with the following Regex:
```regexp
[a-zA-Z0-9]+
```

#### Duration

Every duration has to match **in total** with the following Regex:
```regexp
([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9][0-9])s
```
The extraction of hours, minutes and seconds should be obvious.

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

The GET command is specified as following

```
GET key
```

where `key` has to follow the [Key / Value convention](SPEC.md#key--value).

The server has to respond with the value formerly associated with this key, if it exists. If the value doesn't exist respond with `not found`.

This command deletes the associated `key` `value` pair if it exists.

### GETC

### SETC

### DELC