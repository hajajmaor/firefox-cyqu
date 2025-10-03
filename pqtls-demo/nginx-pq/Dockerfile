FROM ubuntu:24.04 AS build
ARG NGINX_VERSION=1.28.0
ARG OQS_PROVIDER_REF=main
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git curl ca-certificates pkg-config \
    libpcre2-dev zlib1g-dev cmake ninja-build python3 libssl-dev openssl && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
RUN git clone --depth=1 --branch ${OQS_PROVIDER_REF} https://github.com/open-quantum-safe/oqs-provider.git
WORKDIR /tmp/oqs-provider
RUN ./scripts/fullbuild.sh && cmake --install _build --prefix /opt/oqs
WORKDIR /tmp
RUN curl -fsSLo nginx.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx.tar.gz && cd nginx-${NGINX_VERSION} && \
    ./configure --prefix=/opt/nginx \
      --with-http_ssl_module --with-stream --with-stream_ssl_module \
      --with-stream_ssl_preread_module --with-http_v2_module && \
    make -j"$(nproc)" && make install

FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libpcre2-8-0 zlib1g openssl && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/oqs/lib/ossl-modules/oqsprovider.so /usr/lib/ossl-modules/oqsprovider.so
COPY --from=build /opt/nginx /opt/nginx
ENV PATH="/opt/nginx/sbin:${PATH}"
COPY nginx.conf /opt/nginx/conf/nginx.conf
COPY openssl-oqs.cnf /etc/ssl/openssl-oqs.cnf
RUN mkdir -p /etc/nginx/tls
EXPOSE 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]

