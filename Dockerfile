FROM ubuntu:20.04
RUN apt update \
  && apt upgrade -y \
  && apt install -y bind9 bind9utils p7zip-full wget \
  && rm -r /var/lib/apt/lists/*

#-- Create system user
RUN useradd -M -l -r -s /usr/sbin/nologin named

#-- Create directories
RUN mkdir /var/named
RUN chown named:named /var/named

LABEL maintainer="Eugene Taylashev" \
  url="https://github.com/eugene-taylashev/docker-dns" \
  source="https://hub.docker.com/repository/docker/etaylashev/dns" \
  title="Bind9 DNS server" \
  description="Run a master or slave DNS as a container using the Bind9 name server software on Ubuntu"

#-- ports exposed
EXPOSE 53/tcp
EXPOSE 53/udp

#-- default environment variables
ENV URL_CONF=none
ENV SKEY=none
ENV VERBOSE=0

#-- copy default execution script
COPY --chown=named:named entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
