FROM alpine:3.5

RUN apk add --no-cache --virtual .build-deps nginx-mod-http-lua nginx-lua

RUN mkdir -p /run/nginx && mkdir -p /etc/nginx/lua

COPY nginx/conf.d/nginx-lua-example.conf /etc/nginx/conf.d/default.conf
# COPY ./lua/* /etc/nginx/lua/

CMD ["nginx", "-g", "daemon off;"]

