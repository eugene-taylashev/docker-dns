# docker-dns
A simple Docker container to run a DNS server 

## Intro
Brief description:
- The image uses Alpine:3.14.2 and Bind 9.16.20
- The configuration file `named.conf` and all zone files are in the same directory `/var/bind` to simplify volume mapping
- Non-privileged user id `named` (100:101) is used to run the service
- DNS/Bind configuration is not in scope of this document. Check articles like [Implementing DNS server using BIND](https://linuxtechlab.com/configuring-dns-server-using-bind/) , [Deploying DNSSEC](https://blog.apnic.net/2019/05/23/how-to-deploying-dnssec-with-bind-and-ubuntu-server/). 
- Sample configuration and zone files are in the directory `test-conf` for testing purposes.

## Usage

Allocate a volume for the configuration file `named.conf` and all other zone files and keys (ZSK, KSK, etc) if any.

Copy the included test `named.conf` to that volume.

Get the image (optional): `docker pull etaylashev/dns`

### Run
```
docker run -d \
--name dnsforward \
-p 5353:53/udp \
-e VERBOSE=1 \
-v  /conf/dns/dns_master:/var/bind \
etaylashev/dns
```
- Flag **VERBOSE=1** provides more details into Docker logs from `entrypoint.sh`

Check logs: `docker logs dnsforward`

### Test
Perform functionality tests for the image: `./test.sh`
Or simply run the command: `dig -p 5353 -4 @localhost google.com`

### Backup
Backup files from the mounted volume or run the command to backup from the running container:`./backup.sh`
