FROM alpine:latest

ARG BUILD_DATE
#-- default environment variables
ENV VERBOSE=1

RUN apk update && apk add  bind bind-tools bind-libs \
	&& chown named:named /var/bind \
	&& touch  /var/bind/named.conf \
	&& chmod +r /var/bind/named.conf

LABEL maintainer="Eugene Taylashev" \
    bind-version="9.16.20" \
    alpine-version="3.14.2" \
    build="2021-11-03" \
    org.opencontainers.image.title="alpine-bind" \
    org.opencontainers.image.description="A simple DNS server using Bind 9 on Alpine Linux" \
    org.opencontainers.image.authors="Eugene Taylashev" \
    org.opencontainers.image.version="v9.16.20" \
    org.opencontainers.image.url="https://hub.docker.com/r/etaylashev/dns" \
    org.opencontainers.image.source="https://github.com/eugene-taylashev/docker-dns" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

#-- ports exposed
EXPOSE 53/tcp
EXPOSE 53/udp

#-- Volume with configuration file and zone files
VOLUME "/var/bind"

COPY --chown=named:named functions.sh entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
