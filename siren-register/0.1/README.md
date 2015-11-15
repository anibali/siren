### siren-register Docker image

[Alpine Linux](http://www.alpinelinux.org/) + siren-register

`docker pull anibali/siren-register`

Major inspiration drawn from Jason Wilder:
["Docker Service Discovery Using Etcd and Haproxy"](http://jasonwilder.com/blog/2014/07/15/docker-service-discovery/)

#### Usage

```sh
$ docker run -d -p 2379:2379 --name etcd anibali/etcd
$ docker run --name siren --net=host --rm -it \
  -e HOST_IP=$(ip route get 1 | awk '{print $NF;exit}') \
  -e ETCD_ADDR=http://127.0.0.1:2379 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  anibali/siren-register
$ docker stop etcd && docker rm etcd
```
