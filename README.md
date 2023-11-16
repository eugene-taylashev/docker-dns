# docker-dns
A simple Docker container to run a full-feature DNS server based on [ISC BIND 9](https://www.isc.org/bind/)

## Intro
Brief description:
- The image uses Alpine:3.18.4 and Bind 9.18.19 (re-build to get it up-to-date)
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
--name dns-test \
-p 5353:53/udp \
-p 5354:53/tcp \
-p 8443:443/tcp \
-e VERBOSE=1 \
-v  /conf/dns/dns-test:/var/bind \
etaylashev/dns
```
- Flag **VERBOSE=1** provides more details into Docker logs from `entrypoint.sh`

Check logs: `docker logs dns-test`

### Test
Perform functionality tests for the image assuming configuration files in the test-config directory are used and no `dig` or `update` are installed:
- DNS query: `docker exec dns-test /bin/sh -c "/usr/bin/dig -4 @localhost +short ns1.test.case"`; Result: `1.1.1.31`
- DNS query with DNSSEC: `docker exec dns-test /bin/sh -c "/usr/bin/dig -4 @localhost +dnssec +multiline mail.test.case"`; Result:
```
mail.test.case.         86400 IN A 1.1.1.32
mail.test.case.         86400 IN RRSIG A 13 3 86400 (
                                20231123134539 20231115223824 44435 test.case.
                                438/cC+T2XdxYtotaLASWuAwG1pN15WBYp0Bn+Ez6MSk
                                52Q0KJ7nA4FVBqDAq3douiZrmDhdPWqhlsEl8ZHbvQ== )  
```
- DNS zone transfer: `docker exec dns-test /bin/sh -c "/usr/bin/dig -4 @localhost -k /var/bind/test_update.key axfr test.case"`; Result: many lines with test.case zone info
- DDNS to add an A record "new -> 1.1.1.13": `docker exec dns-test /bin/sh -c "/usr/bin/nsupdate -k /var/bind/test_update.key /var/bind/update_cmd.txt"`
- Verify that the record has been inserted: `docker exec dns-test /bin/sh -c "/usr/bin/dig -4 @localhost +short new.test.case"`; Result: `1.1.1.13`
- DNS-over-TLS query: `docker exec dns-test /bin/sh -c "/usr/bin/dig -4 @localhost +https ns1.test.case"`; Result should contain the line: `;; SERVER: 127.0.0.1#443(localhost) (HTTPS)`

### Backup
Backup files from the mounted volume or run the command to backup from the running container:`./backup.sh`
