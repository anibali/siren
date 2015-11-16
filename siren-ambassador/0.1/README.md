### siren-ambassador Docker image

[Alpine Linux](http://www.alpinelinux.org/) + siren-ambassador

`docker pull anibali/siren-ambassador`

["Link via an ambassador container"](https://docs.docker.com/engine/articles/ambassador_pattern_linking/)

`siren-ambassador` is a simple TCP relay that connects to `siren-discover`.
Given a Siren group and a port number, `siren-ambassador` will continuously poll
to make sure that it's forwarding all incoming TCP connections on that port to
the same port in a running container of that Siren group.

#### Usage

Firstly, we assume that etcd is running at address `1.2.3.4`.

On one node, run the service that requires `hello-world`, an ambassador for
`hello-world` and `siren-discover`...

```yaml
curl-hello-world:
  image: odise/busybox-curl
  command: sh -c "while true; do curl -s hello-world:80 | sed -rn 's/.*<h3>(.*)<\/h3>.*/\1/p'; sleep 5; done"
  links:
    - hello-world-ambassador:hello-world
hello-world-ambassador:
  image: anibali/siren-ambassador
  command: hello-world 80
  expose:
    - '80'
  ports:
    - '80'
  links:
    - discover
discover:
  image: anibali/siren-discover
  environment:
    - ETCD_ADDR=http://1.2.3.4:2379
```

...and, perhaps on another node, run `hello-world` itself along with
`siren-register`...

```yaml
hello-world:
  image: tutum/hello-world
  environment:
    - _SIREN_GROUP=hello-world
  ports:
    - '80'
register:
  image: anibali/siren-register
  environment:
    - ETCD_ADDR=http://1.2.3.4:2379
  volumes:
    - '/var/run/docker.sock:/var/run/docker.sock'
```

With this setup it is possible to link some service to `hello-world-ambassador`
as though it were `hello-world` directly. The advantage is that `hello-world`
can be stopped, started and moved without needing to relink any dependent
containers. Thanks to service discovery, `hello-world-ambassador` will
automatically swap to relay TCP connections to wherever a container with the
appropriate _SIREN_GROUP (hello-world) and exposed port (80) is running.

To see for yourself, stop and recreate `hello-world`. You should notice that
the dependent `curl-hello-world` service changes to print the response of the
new container. Magic!
