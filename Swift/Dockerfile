FROM swift:latest AS builder

WORKDIR /usr/src/app

COPY . .

RUN swift build -c release

FROM swift:slim AS runner

WORKDIR /usr/bin

COPY --from=builder /usr/src/app/.build/release/BenchmarkServer /usr/bin/BenchmarkServer

EXPOSE 8080

CMD [ "/usr/bin/BenchmarkServer" ]
