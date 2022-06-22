Начнём сразу со второго вопроса, так как полноценная работа с терраформом в облаке сейчас невозможна из-за ряда региональных ограничений.

2. server.yaml (Настроен на все подходящие ветки и выдано разрешение на изменения/переназначения/мерж)
```
repos:
- id: github.com/ComradeTempest/*
  branch: /.*/
  apply_requirements: [approved, mergeable]
  workflow: flow_p
  allowed_overrides: [apply_requirements, workflow, delete_source_branch_on_merge]
  allowed_workflows: ["flow_p", "flow_s"]
  allow_custom_workflows: true
  delete_source_branch_on_merge: true
workflows:
  flow_s:
    plan:
      steps:
      - run: terraform workspace select stage
      - init
      - plan
          extra_args: ["-lock=false"]
    apply:
      steps:
      - run: terraform workspace select stage
      - apply
  flow_p:
    plan:
      steps:
      - run: terraform workspace select prod
      - init
      - plan:
          extra_args: ["-lock=false"]
    apply:
      steps:
      - run: terraform workspace select prod
      - apply
```

atlantis.yaml (Настроены планирование и апплай, также настроен автоплан с условием when_modified: ["*.tf"])
```
version: 3
automerge: true
delete_source_branch_on_merge: true
parallel_plan: true
parallel_apply: true
projects:
- name: netology-atlantis
- dir: .
  workspace: stage
  autoplan:
    when_modified: ["*.tf"]
    enabled: true
  apply_requirements: [mergeable, approved]
  workflow: flow_s
- dir: .
  workspace: prod
  autoplan:
    when_modified: ["*.tf"]
    enabled: true
  apply_requirements: [mergeable, approved]
  workflow: flow_p
workflows:
  flow_s:
    plan:
      steps:
      - run: terraform workspace select stage
      - init
      - plan
          extra_args: ["-lock=false"]
    apply:
      steps:
      - run: terraform workspace select stage
      - apply
  flow_p:
    plan:
      steps:
      - run: terraform workspace select prod
      - init
      - plan:
          extra_args: ["-lock=false"]
    apply:
      steps:
      - run: terraform workspace select prod
      - apply
```

3. Тут проблема. Ни клауд терраформа, ни АВС на данный момент недоступны. Да и даже если бы работал терраформ, аналогов амазоновского модуля для него нет.
Так что я решил попробовать простенький конфиг (учитывая, что основные переменные были внесены через terraform apply -var), где просто count виртуалок вручную жёстко установлен на три.
```
terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
    }
  }

provider "yandex" {
  token     = "yc_token"
  cloud_id  = "c_id"
  folder_id = "f_id"
  zone      = "ru-central1-b"
}

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "netology" {
  count = 3
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
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```
