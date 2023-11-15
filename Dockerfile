FROM alpine:latest

ARG BUILD_DATE
#-- default environment variables
ENV VERBOSE=1

RUN apk update && apk add  bind bind-tools bind-libs \
	&& chown named:named /var/bind \
	&& touch  /var/bind/named.conf \
	&& chmod +r /var/bind/named.conf

LABEL maintainer="Eugene Taylashev" \
    bind-version="9.18.19" \
    alpine-version="3.18.4" \
    build="2023-11-15" \
    org.opencontainers.image.title="alpine-bind" \
    org.opencontainers.image.description="A simple DNS server using Bind 9 on Alpine Linux" \
    org.opencontainers.image.authors="Eugene Taylashev" \
    org.opencontainers.image.version="v9.18.19" \
    org.opencontainers.image.url="https://hub.docker.com/r/etaylashev/dns" \
    org.opencontainers.image.source="https://github.com/eugene-taylashev/docker-dns" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

#=== ports exposed
#-- for DNS queries
EXPOSE 53/udp
#-- for DNS zone transfers
EXPOSE 53/tcp
#-- for DNS over TLS
EXPOSE 443/tcp

#-- Volume with configuration file and zone files
VOLUME "/var/bind"

COPY --chown=named:named functions.sh entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
