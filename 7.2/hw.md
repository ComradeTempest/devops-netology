Итак, будем пилить всю благодать на яндекс-клауде.

1.
Создали аккаунт, сделали облако.
Ввели переменную и накидали базовый конфиг терраформа c учётом ввода некоторой инфы из переменной:

terraform apply -var yc_token=<а тут какой-нибудь наш токен>

```
terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  token     = "yc_token"
  cloud_id  = "айдишник_облака"
  folder_id = "айдишник_фолдера"
  zone      = "ru-central1-a"
}
```

2.1 — тут у нас Packer как универсальный инструмент создания рабочих образов для облачки разного рода.

2.2 — а тут у нас будет итоговый базовый конфиг к терраформу, чтобы далеко не ходить:

(последний образ убунты нашли через yc compute image list --folder-id standard-images)

```
terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
provider "yandex" {
  token     = "yc_token"
  cloud_id  = "айдишник_облака"
  folder_id = "айдишник_фолдера"
  zone      = "ru-central1-a"
}

resource "yandex_compute_image" "net-test" {
  name = "netology"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8htuc6bfu35rt5476e"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
```
