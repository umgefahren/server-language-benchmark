# Implemenentation

Each Server has to follow some basic rules in order to pass the tests.

## General Information

Every implmenentation has to be written in a idiomatic way to the language. The external dependencies should be close to zero and the implementation should only depend on the standard library in order to give a better impression of the language properties. However it is encouraged to sometimes use external dependencies if this differs the result in interesting ways or the package is so significant to the language, that it can be considered part of the standard library. If external dependencies are used and there is an idiomatic way to complete the task without the external dependencies, just make two code basis.

## Port

The TCP Server has to listen to Port 8080.

## Docker

Every implementation has to provide at least one Dockerfile with, if possible, seperated build and runners, statically linked executables. If possible use an Alpine Image.

If there are multiple ways to run the code, like with Python and Pypy, create a seperate Dockerfile for that, because we are interested in that sort of things. If you do so, follow the `Dockerfile-<alt>` naming convention.
