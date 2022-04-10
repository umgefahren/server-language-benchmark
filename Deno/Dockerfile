FROM denoland/deno:latest

WORKDIR /src/app
COPY *.ts .
RUN deno cache mod.ts
EXPOSE 8080

CMD [ "deno", "run", "--allow-net", "mod.ts" ]