FROM alpine:3.4

RUN apk upgrade && apk update && apk add bash wget openjdk8

ENV LOGSTASH_VERSION=2.3.4 \
    LOGSTASH_URL=https://download.elastic.co/logstash/logstash

RUN wget --no-check-certificate \
      -O /tmp/logstash-${LOGSTASH_VERSION}.tar.gz \
      ${LOGSTASH_URL}/logstash-${LOGSTASH_VERSION}.tar.gz

RUN mkdir -p /opt && \
    tar xzf /tmp/logstash-${LOGSTASH_VERSION}.tar.gz -C /opt && \
    ln -s /opt/logstash-${LOGSTASH_VERSION} /opt/logstash && \
    rm /tmp/logstash-${LOGSTASH_VERSION}.tar.gz && \
    apk del wget && \
    rm -rf /var/cache/apk/*

COPY logstash.conf /logstash.conf

EXPOSE 5000 5000/udp

ENTRYPOINT ["/opt/logstash/bin/logstash"]
CMD ["agent", "-f", "/logstash.conf"]

