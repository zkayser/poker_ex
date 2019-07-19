FROM elixir:1.9.0

WORKDIR /app

COPY . .

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force \
  && mix do deps.get, compile \
  && mix release \
  && echo "Compiled release..." \
  && ls _build/prod/rel/poker_ex/bin

CMD ["echo", "Build finished"]