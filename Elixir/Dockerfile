FROM elixir:1.13-alpine

COPY . .

RUN mix local.hex --force

RUN mix deps.get

RUN mix compile

CMD ["mix", "run", "--no-halt"]