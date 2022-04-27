FROM crystallang/crystal:latest-alpine as builder

WORKDIR /app
COPY . .

RUN shards build --static --no-debug --release --production

FROM alpine:latest

COPY --from=builder /app/bin/server /app/

EXPOSE 8080
CMD ["/app/server"]
