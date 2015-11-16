### siren-discover Docker image

[Alpine Linux](http://www.alpinelinux.org/) + siren-discover

`docker pull anibali/siren-discover`

Major inspiration drawn from Jason Wilder:
["Docker Service Discovery Using Etcd and Haproxy"](http://jasonwilder.com/blog/2014/07/15/docker-service-discovery/)

siren-discover exposes a HTTP API for listing running services. For example,
`/v1/services/foo` will list all running services with `_SIREN_GROUP=foo`.
It requires etcd and one or more instances of siren-register to be running on
the network to function.

It is intended that siren-discover be accompanied by its consumer on the same
node. For example, you might have a container which contains a load balancer
and polls an instance of siren-discover at regular intervals to update its
configuration.

#### Usage

Please see the examples in /siren/examples for docker-compose files describing
potential configurations.
