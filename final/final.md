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

	ssh ubuntu@158.160.62.28 && sudo cat /etc/kubernetes/admin.conf
	
Копируем всё на нашу консоль управления в ~/.kube/config, подставляя IP мастер-ноды в строчку server

Теперь у нас срабатывает kubectl get pods --all-namespaces
```
NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-6dfcdfb99-kfkqg   1/1     Running   0          66m
kube-system   calico-node-4bgbq                         1/1     Running   0          67m
kube-system   calico-node-8gkhr                         1/1     Running   0          67m
kube-system   calico-node-csjb6                         1/1     Running   0          67m
kube-system   coredns-68868dc95b-7gshb                  1/1     Running   0          65m
kube-system   coredns-68868dc95b-txqjc                  1/1     Running   0          65m
kube-system   dns-autoscaler-7ccd65764f-lgjgm           1/1     Running   0          65m
kube-system   kube-apiserver-master                     1/1     Running   1          69m
kube-system   kube-controller-manager-master            1/1     Running   1          69m
kube-system   kube-proxy-27g7s                          1/1     Running   0          6m39s
kube-system   kube-proxy-dfxpx                          1/1     Running   0          6m39s
kube-system   kube-proxy-jpzrs                          1/1     Running   0          6m39s
kube-system   kube-scheduler-master                     1/1     Running   1          69m
kube-system   nginx-proxy-worker1                       1/1     Running   0          66m
kube-system   nginx-proxy-worker2                       1/1     Running   0          67m
kube-system   nodelocaldns-dgzg4                        1/1     Running   0          65m
kube-system   nodelocaldns-gwssf                        1/1     Running   0          65m
kube-system   nodelocaldns-kvrhq                        1/1     Running   0          65m
```

## Создаём приложение для тестирования

Репозиторий с кодом для бестолковейшего приложения тут: https://github.com/ComradeTempest/uselessnginxapp

Собранный образ для докера в докер-хабе: [comradetempest/uselessnginxapp](https://hub.docker.com/r/comradetempest/uselessnginxapp)

## Заливаем мониторинг и деплоим наше приложение

TBD

## Пилим CI/CD

TBD

## Наводим порядок и раскладываем нужное в репозитории

TBD


