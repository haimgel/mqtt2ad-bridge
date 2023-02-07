FROM ghcr.io/haimgel/mqtt2cmd:v0.1.4 AS mqtt2cmd

FROM alpine:3.17

COPY --from=mqtt2cmd /usr/local/bin/mqtt2cmd /usr/local/bin/mqtt2cmd

RUN apk add --no-cache bash samba-dc \
    && mkdir /app \
    && chown nobody:nobody /app

USER nobody

COPY --chown=nobody ad-command.sh /app/ad-command.sh
WORKDIR /app

CMD ["/usr/local/bin/mqtt2cmd"]
