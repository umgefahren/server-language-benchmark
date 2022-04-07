FROM swift:latest AS builder

WORKDIR /usr/src/app

COPY . .

RUN swift build -c release

EXPOSE 8080

CMD [ "/usr/src/app/.build/release/ServerBenchmark" ]
