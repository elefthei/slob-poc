FROM alpine

####################
# Prerequisites    #
####################
RUN echo http://dl-4.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache --virtual .build-deps \
      alpine-sdk openblas-dev cmake curl readline-dev ncurses ncurses-dev wget \
      git gnuplot unzip libjpeg-turbo-dev libpng-dev gfortran perl openssl-dev \
      imagemagick-dev graphicsmagick-dev fftw-dev zeromq-dev bash && \
    mkdir -p /run/nginx && \
    mkdir -p /etc/nginx/lua

COPY nginx/conf.d/nginx-lua-example.conf /etc/nginx/conf.d/default.conf
COPY nginx/lua/* /var/lib/nginx/

####################
# Torch Dockerfile #
####################

RUN git clone https://github.com/torch/distro.git /usr/src/torch --recursive && \
    cd /usr/src/torch && \
    ./install.sh

RUN wget https://openresty.org/download/openresty-1.11.2.5.tar.gz


RUN apk add --no-cache \
      nginx-mod-http-lua \
      nginx-lua

RUN cd /usr/src/torch && \
    cp -r install/bin/* /usr/bin/ && \
    cp -r install/lib/* /usr/lib/ && \
    cp -r install/include/* /usr/include/

# Docker Build Arguments
ARG RESTY_VERSION="1.11.2.5"
ARG RESTY_OPENSSL_VERSION="1.0.2k"
ARG RESTY_PCRE_VERSION="8.40"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-luajit=/usr/src/torch/install \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"

ENV RESTY_CONFIG_ARGS ${RESTY_CONFIG_OPTIONS} ${_RESTY_CONFIG_DEPS}
# 1) Install apk dependencies
# 2) Download and untar OpenSSL, PCRE, and OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN \
    apk add --no-cache --virtual .build-deps \
        build-base \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
    && apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libxslt \
        zlib \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION}
    #&& ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    #&& make -j${RESTY_J} \
    #&& make -j${RESTY_J} install \
    #&& cd /tmp \
    #&& rm -rf \
    #    openssl-${RESTY_OPENSSL_VERSION} \
    #    openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    #    openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
    #    pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    #&& apk del .build-deps \
    #&& ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    #&& ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

# Lua Path and more.
#env LUA_PATH '/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/torch/share/lua/5.1/?.lua;/torch/share/lua/5.1/?/init.lua;./?.lua;/torch/share/luajit-2.1.0-beta1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
#env LUA_CPATH '/root/.luarocks/lib/lua/5.1/?.so;/torch/lib/?.so;/torch/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
