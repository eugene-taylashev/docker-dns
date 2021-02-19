FROM alpine:latest
RUN apk update && apk add  bind bind-tools bind-libs \
	&& chown named:named /var/bind \
	&& touch  /var/bind/named.conf \
	&& chmod +r /var/bind/named.conf

LABEL maintainer="Eugene Taylashev" \
  url="https://github.com/eugene-taylashev/docker-dns" \
  source="https://hub.docker.com/repository/docker/etaylashev/dns" \
  title="Bind9 DNS server" \
  description="Run a simple DNS server as a container using the Bind9 name server software on Alpine"

#-- ports exposed
EXPOSE 53/tcp
EXPOSE 53/udp

#-- Volume with configuration file and zone files
VOLUME "/var/bind"

#-- default environment variables
ENV VERBOSE=1

COPY --chown=named:named entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
