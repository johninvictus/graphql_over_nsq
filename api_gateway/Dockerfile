FROM bitwalker/alpine-elixir:1.9.0

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mkdir -p /opt/app/.cache && \
    mkdir -p /opt/app/_build && \
    mkdir -p /opt/app/api_gateway && \
    mkdir -p /opt/app/api_gateway/deps && \
    chmod -R 777 /opt/ && \
    chmod -R 777 /opt/app/_build && \
    chmod -R 777 /opt/app/.cache && \
    chmod -R 777 /opt/app/api_gateway && \
    chmod -R 777 /opt/app/api_gateway/deps

ENV MIX_BUILD_PATH=/opt/app/_build

WORKDIR /opt/app/api_gateway

USER default

ENV ERL_AFLAGS="-kernel shell_history enabled"
ENV PATH="$PATH:/opt/mix"

CMD ["mix", "phx.server"]
