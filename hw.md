1. 
Dockerfile
```
FROM centos:7

RUN yum install -y perl-Digest-SHA && \
    yum install -y java-1.8.0-openjdk.x86_64

RUN groupadd -g 1000 elastic && useradd elastic -u 1000 -g 1000 && \
    mkdir -p /var/lib/elasticsearch && \
    chown -R elastic /var/lib/elasticsearch
	
COPY --chown=elastic:elastic elasticsearch-7.17.4/* /var/lib/elasticsearch/

EXPOSE 9200/tcp
EXPOSE 9300/tcp

USER elastic

ENTRYPOINT ["/var/lib/elasticsearch/bin/elasticsearch"]
```

https://hub.docker.com/repository/docker/comradetempest/netology-elastic

Запускаем

```
version: '3.7'

services:
  elactic:
    container_name: elastic
    image: netology-elastic
    environment: 
      - discovery.type=single-node
      - PATH=/var/lib:$PATH
      - node.name=netology_test
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    expose:
      - 9200
    ports:
      - "9200:9200"
```
Вывод:
```
test@netology:~/elastic$ curl -X GET 'http://localhost:9200/'
{
  "name" : "netology_test",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "BDgPci4FR1i7uL4dsGVuCQ",
  "version" : {
    "number" : "7.17.4",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "79878662c54c886ae89206c685d9f1051a9d6411",
    "build_date" : "2022-05-18T18:04:20.964345128Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
test@netology:~/elastic$
```

2. 
```
test@netology:~/elastic$ curl -X PUT "localhost:9200/ind-1?pretty" -H 'Content-Type: application/json' -d'
> {
>   "settings": {
>     "number_of_shards": 1,
>     "number_of_replicas": 0
>   }
> }
> '
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "ind-1"
}
test@netology:~/elastic$ curl -X PUT "localhost:9200/ind-2?pretty" -H 'Content-Type: application/json' -d'
> {
>   "settings": {
>     "number_of_shards": 2,
>     "number_of_replicas": 1
>   }
> }
> '
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "ind-2"
}
test@netology:~/elastic$ curl -X PUT "localhost:9200/ind-3?pretty" -H 'Content-Type: application/json' -d'
> {
>   "settings": {
>     "number_of_shards": 4,
>     "number_of_replicas": 2
>   }
> }
> '
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "ind-3"
}
test@netology:~/elastic$ curl 'localhost:9200/_cat/indices?v'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases Zuiiv6WaRkCskqthe06SSQ   1   0         40            0     38.1mb         38.1mb
green  open   ind-1            Xid-rAi9QkyQhxvAiR1tUQ   1   0          0            0       226b           226b
yellow open   ind-3            rJ_0GEHgTUiRmwESDHnHVQ   4   2          0            0       904b           904b
yellow open   ind-2            hs8ydK6ITxO2RnTV_zP7gg   2   1          0            0       452b           452b
test@netology:~/elastic$ curl -X GET "localhost:9200/_cluster/health?pretty"
{
  "cluster_name" : "docker-cluster",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 8,
  "active_shards" : 8,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 44.44444444444444
}
test@netology:~/elastic$
```
В общем, состояние у кластера такое, потому что он не кластер, а нода. При размещении в режиме single-node негде уместить примари шард и реплику,
да и копироваться тоже некуда. Вот и болеет система.

3.
Сперва подпилим внутри контейнера конфиг вимом и докинем туда path.repo: usr/share/elasticsearch/snapshots

Потом запускаем вызов к апи:
```
test@netology:~$ curl -X PUT "localhost:9200/_snapshot/netology_backup?pretty" -H 'Content-Type: application/json' -d'
> {
>   "type": "fs",
>   "settings": {
>     "location": "/usr/share/elasticsearch/snapshots",
>     "compress": true
>   }
> }'
{
  "acknowledged" : true
}
test@netology:~$ {"acknowledged":true}
```
Создаём индекс 
```
curl -X PUT "localhost:9200/test?pretty" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}
'

test@netology:~$ curl 'localhost:9200/_cat/indices?v'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases Zuiiv6WaRkCskqthe06SSQ   1   0         40            0     38.1mb         38.1mb
green  open   test             09w_ICzVQU6wWc8wNQDImA   1   0          0            0       226b           226b
test@netology:~$

Бэкапим:

test@netology:~$curl -X PUT "localhost:9200/_snapshot/netology_backup/snapshot_1?wait_for_completion=true&pretty"

Списочек:

test@netology:~$ sudo docker exec -it 6f907e068c87 /bin/sh
[sudo] password for test:
sh-5.0# ls
LICENSE.txt  NOTICE.txt  README.asciidoc  bin  config  data  jdk  lib  logs  modules  plugins  snapshots
sh-5.0# cd snapshots/
sh-5.0# ls
index-0  index.latest  indices  meta-o7pndQ1oRsm5OxmsCF9TkQ.dat  snap-o7pndQ1oRsm5OxmsCF9TkQ.dat

Чистим:

sh-5.0# curl -X DELETE "localhost:9200/test?pretty"
{
  "acknowledged" : true
}

Делаем новый индекс:

sh-5.0# curl -X PUT "localhost:9200/test-2?pretty" -H 'Content-Type: application/json' -d'
> {
>   "settings": {
>     "number_of_shards": 1,
>     "number_of_replicas": 0
>   }
> }
> '
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "test-2"
}

Списочек:

sh-5.0# curl 'localhost:9200/_cat/indices?pretty'
green open .geoip_databases Zuiiv6WaRkCskqthe06SSQ 1 0 40 0 38.1mb 38.1mb
green open test-2           q6aBVl4DToex75VVPOriTA 1 0  0 0   226b   226b
sh-5.0#

Восстанавливаем из снапшота:

sh-5.0# curl -X POST "localhost:9200/_snapshot/netology_backup/snapshot_1/_restore?pretty" -H 'Content-Type: application/json' -d'
{
  "indices": "*",
  "include_global_state": true
}
'
{
  "accepted" : true
}


И вот новый итоговый списочек:

sh-5.0# curl 'localhost:9200/_cat/indices?pretty'
green open .geoip_databases 2fQhlEmaTT6g8XmLlQneBw 1 0 40 0 38.1mb 38.1mb
green open test             Y2T8CjKlT-q5moMLsHlW8A 1 0  0 0   226b   226b
sh-5.0#

```
