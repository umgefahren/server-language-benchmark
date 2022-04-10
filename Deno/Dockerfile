# this docker file is a mess because getting a linux/aarch64 version of deno is kind of hard (not officially supported)
# nix provides deno aarch64 linux binaries just as a reliable glibc layer so let's use that

FROM alpine:latest

RUN apk update && apk upgrade && apk add curl xz sudo
RUN adduser -S user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER user
RUN sh <(curl -L https://nixos.org/nix/install) --no-daemon
ENV PATH /home/user/.nix-profile/bin
RUN nix-env -iA nixpkgs.deno

WORKDIR /src/app
COPY mod.ts .
COPY src src
RUN deno cache mod.ts

EXPOSE 8080

CMD [ "deno", "run", "--allow-net", "--allow-read", "--allow-write", "mod.ts" ]
