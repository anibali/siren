FROM anibali/lua:5.2

# Install required Lua modules
RUN apk add --update gcc lua5.2-dev musl-dev git \
    && export C_INCLUDE_PATH=/usr/include/lua5.2/ \
    && luarocks install httpclient \
    && luarocks install lua-cjson \
    && luarocks install stdlib \
    && apk del gcc lua5.2-dev musl-dev git \
    && rm -rf /var/cache/apk/*

# Install socat
RUN apk add --update socat \
    && rm -rf /var/cache/apk/*

# Copy our scripts into the image
COPY src /app
COPY start_siren-ambassador.sh /

ENTRYPOINT ["/usr/bin/tini", "--", "/start_siren-ambassador.sh"]
