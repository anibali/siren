FROM anibali/docker-gen:0.4

RUN apk add --update \
    --repository http://dl-1.alpinelinux.org/alpine/edge/testing/ \
    lua5.2 luarocks5.2 ca-certificates curl unzip \
    && ln -s /usr/bin/lua5.2 /usr/bin/lua \
    && ln -s /usr/bin/luarocks-5.2 /usr/bin/luarocks

RUN apk add --update gcc lua5.2-dev musl-dev git \
    && export C_INCLUDE_PATH=/usr/include/lua5.2/ \
    && luarocks install httpclient \
    && luarocks install lua-cjson \
    && apk del gcc lua5.2-dev musl-dev git \
    && rm -rf /var/cache/apk/*

COPY src /app
COPY start_siren-register.sh /

CMD ["/start_siren-register.sh"]