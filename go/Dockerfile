FROM golang:1.18-alpine AS builder

WORKDIR /usr/src/app

COPY . .
RUN go build -v -o /usr/local/bin/app ./...

FROM alpine:latest

WORKDIR /usr/bin/

COPY --from=builder /usr/local/bin/app /usr/bin/app

EXPOSE 8080

CMD [ "/usr/bin/app" ]
