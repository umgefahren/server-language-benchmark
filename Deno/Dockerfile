FROM denoland/deno:alpine AS builder

WORKDIR /src/app
COPY mod.ts .
COPY src src
RUN deno compile -o server --allow-net mod.ts

FROM alpine:latest AS runner

COPY --from=builder /src/app/server /usr/local/bin/
EXPOSE 8080

CMD [ "server" ]