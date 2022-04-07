FROM debian:latest AS builder

RUN apt-get update
RUN apt-get -y install build-essential clang
RUN apt-get -y install cmake ninja-build

RUN mkdir /app
WORKDIR /app
COPY . .

RUN export CC=/usr/bin/clang
RUN mkdir /app/build
WORKDIR /app/build/
RUN cmake -DCMAKE_BUILD_TYPE=Release -G Ninja ..
RUN ninja

FROM debian:latest

EXPOSE 8080

RUN mkdir /app
WORKDIR /app
COPY --from=builder /app/build/C_new /app/C_new

CMD ["/app/C_new"]