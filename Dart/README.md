# Dart implementation

## Current supportet requests

- `GET *<key>*`
- `SET *<key>* *<value>*`
- `GETC`
- `SETC`
- `DEL *<key>*`
- All others will result in `invalid command\n`

## Running

To run install the Dart SDK. Then run `dart compile exe bin/server-bench.dart` and then you get the binary at `bin/server-bench.exe`.

## Known Issues

Due to unknown reasons it only works in docker if you want to benchmark with the rust client.
