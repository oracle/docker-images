FROM mikarinneoracle/confd:0.2

RUN \
    build_pkgs="build-base linux-headers openssl-dev pcre-dev wget zlib-dev" && \
    runtime_pkgs="ca-certificates openssl pcre zlib" && \
    apk --update add ${build_pkgs} ${runtime_pkgs} && \
    cd /tmp && \
    mkdir unzip && \
    wget https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/08a395c66e42.zip && \
    unzip 08a395c66e42.zip -d unzip && \
    wget http://nginx.org/download/nginx-1.10.1.tar.gz && \
    tar xzf nginx-1.10.1.tar.gz && \
    cd /tmp/nginx-1.10.1 && \
    ./configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --user=nobody \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_stub_status_module \
      --with-http_auth_request_module \
      --with-threads \
      --with-stream \
      --with-stream_ssl_module \
      --with-http_slice_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-file-aio \
      --with-http_v2_module \
      --with-ipv6 \
      --add-module=/tmp/unzip/nginx-goodies-nginx-sticky-module-ng-08a395c66e42 \
    && make && \
    make install

# Lay down the configuration templates
ADD confd-files/00-upstream.toml.toml \
    /etc/confd/conf.d/00-upstream.toml.toml
ADD confd-files/00-upstream.toml.template \
    /etc/confd/templates/00-upstream.toml.template
ADD confd-files/00-upstream.template.toml \
    /etc/confd/conf.d/00-upstream.template.toml
ADD confd-files/00-upstream.template.template \
    /etc/confd/templates/00-upstream.template.template

ADD nginx.conf /etc/nginx/nginx.conf
ADD promote-candidate.sh /promote-candidate.sh

RUN mkdir -pv /etc/sv/nginx && \
    chmod 2775 /etc/sv/nginx && \
    ln -sv /etc/sv/nginx /service && \
    mkdir -p /run/nginx /etc/nginx/sites-enabled && \
    chmod +x /promote-candidate.sh

ADD nginx-files/99-app \
    /etc/nginx/sites-enabled/99-app
ADD nginx-files/00-upstream-placeholder \
    /etc/nginx/sites-enabled/00-upstream

ADD nginx.sh /etc/sv/nginx/run

# Override the confd start script
ADD confd.sh /etc/sv/confd/run

# Cleanup unneeded files from upstream confd image
RUN rm /etc/confd/conf.d/hello-world.toml.template \
       /etc/confd/templates/hello-world.conf.template_orig

ENTRYPOINT ["/sbin/runsvdir", "/service"]
