# docker-dns
A Docker container to run a DNS server as master or slave

## Intro
Brief description:
- The image uses Ubuntu:20.04 LTS and Bind 9
- The configuration file `named.conf` and all zone files are in the same directory `/var/named` to simplify volume mapping
- Non-privileged user id `named` is used to run the service
- DNS/Bind configuration is not in scope of this document. Check articles like [Implementing DNS server using BIND](https://linuxtechlab.com/configuring-dns-server-using-bind/) , [Deploying DNSSEC](https://blog.apnic.net/2019/05/23/how-to-deploying-dnssec-with-bind-and-ubuntu-server/)

Usage scenarios:
1. Allocate a volume for the configuration file `named.conf` and all other zone files and keys (ZSK, KSK, etc).
2. Pass configuration and zone files to the container as a URL to a 7zip archive with AES encryption

## Usage
To get the image: `docker pull etaylashev/dns`

### Run scenario 1
```
docker run -d \
--name dnsmaster \
-p 53:53/udp -p 53:53/tcp \
-e VERBOSE=1 \
-v  /var/k8s/dns/dns_master:/var/named \
etaylashev/dns
```

- Flag **VERBOSE=1** provides more details into Docker logs from `entrypoint.sh`

### Run scenario 2
```
docker run -d \
--name dnsmaster \
-p 53:53/udp -p 53:53/tcp \
-e VERBOSE=1 \
-e URL_CONF='https://your_configuration_server/dns_master.7z' \
-e SKEY='VeryLongEncryptionPassword' \
etaylashev/dns
```

- `entrypoint.sh` will move all files from the archive to the folder `/var/named`
