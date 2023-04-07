Делано на убунте-22 из-под дефолтного юзера ubuntu.

## Готовим консоль управления облачной инфраструктурой


	curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
	yc config profile create final
	yc config set token XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Делаем облачко Final, использоваться будет папка default

	yc config set cloud-id XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	yc config set folder-id XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Делаем там юзера с правами editor — f-editor. Можно лапками через уй, можно через CLI

	yc iam service-account create --name f-editor

Допиливаем права

	yc resource-manager folder add-access-binding --name default --role editor --subject "serviceAccount:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Берём ключик для аккаунта

	yc iam access-key create --service-account-name f-editor --format=json
```
{
  "access_key": {
    "id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "service_account_id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "created_at": "2023-03-31T08:42:06.177992297Z",
    "key_id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  },
  "secret": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}
```
Делаем ведёрко для хранения всего барахла.

	yc storage bucket create --name=final-tf-storage

```
name: final-tf-storage
folder_id: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
anonymous_access_flags:
  read: false
  list: false
default_storage_class: STANDARD
versioning: VERSIONING_DISABLED
acl: {}
created_at: "2023-03-31T08:52:18.133312Z"
```
Качаем и льём терраформ в /usr/local/bin

Делаем воркспейс для терраформа

	terraform workspace new final
	
Пилим main.tf
```
terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
  
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "final-tf-storage"
    region     = "ru-central1"
    key        = "./terraform.tfstate"
    access_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
provider "yandex" {
  token     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  cloud_id  = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  folder_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  zone      = "ru-central1-a"
}
```
Пилим vpc.tf для сеток
```
resource "yandex_vpc_network" "final-network" {
  name = "final-network"
}

resource "yandex_vpc_subnet" "final-subnet1" {
  name           = "final-subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.final-network.id
  v4_cidr_blocks = ["192.168.100.0/24"]
}

resource "yandex_vpc_subnet" "final-subnet2" {
  name           = "final-subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.final-network.id
  v4_cidr_blocks = ["192.168.110.0/24"]
}
```
Делаем terraform init

Делаем прогон terraform plan / terraform apply / terraform destroy с проверкой каждого шага.

Теперь пилим конфиг виртуалок для нашего кластера
```
resource "yandex_compute_instance" "final-cluster" {
  for_each = toset(["master", "woker1", "worker2"])
  name = each.key

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
	  size = "20"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.final-subnet1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "cluster_ips" {
  value = {
    internal = values(yandex_compute_instance.final-cluster)[*].network_interface.0.ip_address
    external = values(yandex_compute_instance.final-cluster)[*].network_interface.0.nat_ip_address
  }
}
```

Можно разнести для пущей HA сетки рандомно, добавив ресурс 
```
resource "random-subnet" "final-subnet-random" {
  input        = [yandex_vpc_subnet.final-subnet1.id, yandex_vpc_subnet.final-subnet2.id]
  result_count = 1
}
```
и скорректировав фрагмент
```
  network_interface {
    subnet_id = random_subnet.final-subnet-random.result[0]
    nat       = true
  }
```

## Пилим кластер Kubernetes

Ставим всякое

	sudo apt-get update
	sudo apt-get install python3 python3-pip git -y

Теперь тащим kubespray с гитхаба
```
  git clone https://github.com/kubernetes-sigs/kubespray.git && cp -rfp kubespray/inventory/sample kubespray/inventory/final
```
Из каталога с кубспреем ставим зависимости
```
  sudo pip3 install -r requirements.txt
```
Пишем inventory.ini к kubespray
```
[all]
master ansible_host=158.160.62.28
worker1 ansible_host=130.193.36.94
worker2 ansible_host=158.160.59.182

[kube_control_plane]
master

[etcd]
master

[kube_node]
worker1
worker2

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
```
Допиливаем inventory/final/group_vars/k8-cluster/k8-cluster.yml и ставим там supplementary address нашего master'a, а то будет невозможно подцепить конфиг от мастера на нашу тачку управления.

Заодно можем скорректировать параметры в inventory/final/group_vars/k8s_cluster/addons.yml — перевести в true параметры ingress_nginx_enabled и ingress_nginx_host_network для дальнейшего деплоя графаны и прочего.

Запускаем кубспрей из его каталога НЕ ИЗ-ПОД РУТА!!!

	ansible-playbook -i inventory/final/inventory.ini cluster.yml -b -v

Ставим на консоль управления kubectl

	sudo apt-get update 
	sudo apt-get install -y apt-transport-https
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl

Тащим конфиг себе

	ssh ubuntu@158.160.62.28
	sudo cat /etc/kubernetes/admin.conf
	
Копируем всё на нашу консоль управления в ~/.kube/config, подставляя IP мастер-ноды в строчку server

Теперь у нас срабатывает kubectl get pods --all-namespaces
```
NAMESPACE       NAME                                      READY   STATUS    RESTARTS   AGE
ingress-nginx   ingress-nginx-controller-2gcdk            1/1     Running   0          19m
ingress-nginx   ingress-nginx-controller-mv6qf            1/1     Running   0          19m
kube-system     calico-kube-controllers-6dfcdfb99-9jsp6   1/1     Running   0          19m
kube-system     calico-node-6rv78                         1/1     Running   0          20m
kube-system     calico-node-c77pn                         1/1     Running   0          20m
kube-system     calico-node-zsr2q                         1/1     Running   0          20m
kube-system     coredns-68868dc95b-28m2g                  1/1     Running   0          18m
kube-system     coredns-68868dc95b-wkk7z                  1/1     Running   0          18m
kube-system     dns-autoscaler-7ccd65764f-5llgn           1/1     Running   0          18m
kube-system     kube-apiserver-master                     1/1     Running   1          22m
kube-system     kube-controller-manager-master            1/1     Running   1          22m
kube-system     kube-proxy-pvrlv                          1/1     Running   0          4m13s
kube-system     kube-proxy-vtxtc                          1/1     Running   0          4m13s
kube-system     kube-proxy-xgvdh                          1/1     Running   0          4m13s
kube-system     kube-scheduler-master                     1/1     Running   1          22m
kube-system     nginx-proxy-worker1                       1/1     Running   0          19m
kube-system     nginx-proxy-worker2                       1/1     Running   0          19m
kube-system     nodelocaldns-kh6lc                        1/1     Running   0          18m
kube-system     nodelocaldns-pdjfs                        1/1     Running   0          18m
kube-system     nodelocaldns-xvht4                        1/1     Running   0          18m
```

## Создаём приложение для тестирования

Репозиторий с кодом для бестолковейшего приложения тут: https://github.com/ComradeTempest/uselessnginxapp

Собранный образ для докера в докер-хабе: [comradetempest/uselessnginxapp](https://hub.docker.com/r/comradetempest/uselessnginxapp)

## Заливаем мониторинг и деплоим наше приложение

Для простоты и гармонии возьмём репозиторий kube-prometheus и раскатаем его на кластере.

	git clone https://github.com/prometheus-operator/kube-prometheus.git && kubectl apply --server-side -f kube-prometheus/manifests/setup && \
	kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring && \
	kubectl apply --server-side -f kube-prometheus/manifests/
	
В итоге мониторинг раскатывается прекрасно.

```
ubuntu@final:~$ kubectl get pods -n monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          60s
alertmanager-main-1                    2/2     Running   0          60s
alertmanager-main-2                    2/2     Running   0          60s
blackbox-exporter-6495c95d8f-7jnxn     3/3     Running   0          80s
grafana-795fb69cf-h72s4                1/1     Running   0          78s
kube-state-metrics-fb68f87f9-q64rn     3/3     Running   0          78s
node-exporter-bfmsn                    2/2     Running   0          76s
node-exporter-kkn4l                    2/2     Running   0          76s
node-exporter-nmkf2                    2/2     Running   0          76s
prometheus-adapter-6b88dfd544-h9hdm    1/1     Running   0          75s
prometheus-adapter-6b88dfd544-hgn97    1/1     Running   0          75s
prometheus-k8s-0                       2/2     Running   0          59s
prometheus-k8s-1                       2/2     Running   0          59s
prometheus-operator-584495d569-tzrzw   2/2     Running   0          74s
```

Можно сразу проверить графану:

	kubectl --namespace monitoring port-forward --address="0.0.0.0" svc/grafana 3000

Деплоим NS и наше приложение.

```
apiVersion: v1
kind: Namespace
metadata:
  name: uselessappns
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uselessnginxapp
  namespace: uselessappns
  labels:
    app: uselessappns
spec:
  selector:
    matchLabels:
      app: uselessnginxapp
  replicas: 2
  template:
    metadata:
      labels:
        app: uselessnginxapp
    spec:
      containers:
      - name: uselessnginxapp
        image: comradetempest/uselessnginxapp:1.0.0
        ports:
        - containerPort: 80
          protocol: TCP
```
kubectl create -f ./ns.yml && kubectl create -f ./useless.yml

Пишем сервис к приложению, стартуем через kubectl create

```
apiVersion: v1
kind: Service
metadata:
  name: uselessappservice
  namespace: uselessappns
spec:
  selector:
    app: uselessnginxapp
  ports:
    - name: uselessport
      protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP

```

Проверяем наличие сервисов графаны и нашей приложухи.
```
ubuntu@final:~/k8s$ kubectl get service -A
NAMESPACE      NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                        AGE
default        kubernetes              ClusterIP   10.233.0.1      <none>        443/TCP                        46m
kube-system    coredns                 ClusterIP   10.233.0.3      <none>        53/UDP,53/TCP,9153/TCP         42m
kube-system    kubelet                 ClusterIP   None            <none>        10250/TCP,10255/TCP,4194/TCP   22m
monitoring     alertmanager-main       ClusterIP   10.233.5.116    <none>        9093/TCP,8080/TCP              22m
monitoring     alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP     22m
monitoring     blackbox-exporter       ClusterIP   10.233.57.6     <none>        9115/TCP,19115/TCP             22m
monitoring     grafana                 ClusterIP   10.233.44.159   <none>        3000/TCP                       22m
monitoring     kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP              22m
monitoring     node-exporter           ClusterIP   None            <none>        9100/TCP                       22m
monitoring     prometheus-adapter      ClusterIP   10.233.46.108   <none>        443/TCP                        22m
monitoring     prometheus-k8s          ClusterIP   10.233.39.34    <none>        9090/TCP,8080/TCP              22m
monitoring     prometheus-operated     ClusterIP   None            <none>        9090/TCP                       22m
monitoring     prometheus-operator     ClusterIP   None            <none>        8443/TCP                       22m
uselessappns   uselessappservice       ClusterIP   10.233.7.0      <none>        8080/TCP                       78s
```

Пишем ингресс для нашего приложения
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: uselessappingress
  namespace: uselessappns
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
      - path: "/index.html"
        pathType: Prefix
        backend:
          service:
            name: uselessappservice
            port:
              name: uselessport
```
И пишем ингресс для графаны

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafanaingress
  namespace: monitoring
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 9.1.4
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
      - path: "/"
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```

Проверяем и имеем, что на 80 порту внезапно торчит графана, а с префиксом имеем наше приложение. Чудеса.

### ДОПИЛИТЬ АТЛАНТИС

## Пилим CI/CD

TBD

## Наводим порядок и раскладываем нужное в репозитории

TBD


