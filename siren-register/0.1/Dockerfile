FROM anibali/docker-gen:0.4

# Install Lua and LuaRocks
RUN apk add --update \
    --repository http://dl-1.alpinelinux.org/alpine/edge/testing/ \
    lua5.2 luarocks5.2 ca-certificates curl unzip \
    && rm -rf /var/cache/apk/*

# Create links
RUN ln -s /usr/bin/lua5.2 /usr/bin/lua \
    && ln -s /usr/bin/luarocks-5.2 /usr/bin/luarocks

# Install required Lua modules
RUN apk add --update gcc lua5.2-dev musl-dev git \
    && export C_INCLUDE_PATH=/usr/include/lua5.2/ \
    && luarocks install httpclient \
    && luarocks install lua-cjson \
    && apk del gcc lua5.2-dev musl-dev git \
    && rm -rf /var/cache/apk/*

# Copy our scripts into the image
COPY src /app
COPY start_siren-register.sh /

ENTRYPOINT ["/usr/bin/tini", "--", "/start_siren-register.sh"]
