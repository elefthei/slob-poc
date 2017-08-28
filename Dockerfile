FROM alpine:3.5

RUN apk add --no-cache --virtual .build-deps nginx-mod-http-lua nginx-lua
RUN mkdir -p /run/nginx
COPY nginx/conf.d/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx/lua/* /var/lib/nginx/

CMD ["nginx", "-g", "daemon off;"]

