# slob-poc
Sticky Load Balancer using DynDNS proof-of-concept.

# Running

Building:
```
docker-compose -f docker-compose.yml build
```

Running:
```
docker-compose -f docker-compose.yml up
```

Usage:

1. Requests to http://localhost/register will be forwarded to the registration container.
```
MacBook-Air:unifyid-dockercon user$ curl -H "id: foobar" http://localhost/register
Request served by 20d00536e37a

HTTP/1.0 GET /foobar

Host: register
Id: foobar
Connection: close
User-Agent: curl/7.51.0
Accept: */*
```
2. A small flask application that is the registration server will register a DNS redirect from all future requests to
   http://<server-name> to http://<id>.<server-name> permanently.

3. This is a sticky load-balancer proof-of-concept, useful if you want a user/device to always be load-balanced to the same server.

