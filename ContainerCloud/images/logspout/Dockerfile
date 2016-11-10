FROM alpine:3.4
VOLUME /mnt/routes
EXPOSE 8000

COPY build.sh /build.sh
RUN /build.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod 744 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
