FROM swift:slim AS builder

WORKDIR /usr/src/app

COPY . .

RUN swift build -c release

RUN debian:slim

WORKDIR /usr/bin/

COPY --from=builder /usr/src/app/.build/release/ServerBenchmark /usr/bin/ServerBenchmark

CMD [ "/usr/bin/ServerBenchmark" ]