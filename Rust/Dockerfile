FROM rust:1.59 as builder
WORKDIR /usr/src/myapp
COPY . .
RUN sh -c 'if [ $(uname -m) = "aarch64" ]; then rustup target add aarch64-unknown-linux-musl; else rustup target add x86_64-unknown-linux-musl; fi'
RUN sh -c 'if [ $(uname -m) = "aarch64" ]; then cargo install --path . --target aarch64-unknown-linux-musl; else cargo install --path . --target x86_64-unknown-linux-musl; fi'

FROM scratch
COPY --from=builder /usr/local/cargo/bin/server-bench /usr/local/bin/server-bench
EXPOSE 8080
CMD ["server-bench"]
