FROM anibali/alpine-tini:3.2

RUN apk add --update \
    --repository http://dl-1.alpinelinux.org/alpine/edge/testing/ \
    lua5.2 luarocks5.2 ca-certificates curl unzip \
    && ln -s /usr/bin/lua5.2 /usr/bin/lua \
    && ln -s /usr/bin/luarocks-5.2 /usr/bin/luarocks

RUN apk add --update gcc lua5.2-dev musl-dev git \
    && export C_INCLUDE_PATH=/usr/include/lua5.2/ \
    && luarocks install httpclient \
    && luarocks install lua-cjson \
    && luarocks install etlua \
    && luarocks install stdlib \
    && apk del gcc lua5.2-dev musl-dev git

RUN apk add --update haproxy \
    && rm -rf /var/cache/apk/*

RUN touch /var/run/haproxy.pid

COPY src /app
COPY start_siren-balancer.sh /

EXPOSE 1936

ENTRYPOINT ["/usr/bin/tini", "--", "/start_siren-balancer.sh"]
