### siren-discover Docker image

[Alpine Linux](http://www.alpinelinux.org/) + siren-discover

`docker pull anibali/siren-discover`

Major inspiration drawn from Jason Wilder:
["Docker Service Discovery Using Etcd and Haproxy"](http://jasonwilder.com/blog/2014/07/15/docker-service-discovery/)

#### Usage

First start etcd and siren-register.

```sh
$ docker run --name siren-discover -d -e ETCD_ADDR=http://127.0.0.1:2379 \
  --net=host -p 8080:8080 anibali/siren-discover
$ curl localhost:8080/v1/services
$ docker stop siren-discover && docker rm siren-discover
```
