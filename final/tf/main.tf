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
    access_key = ""
    secret_key = ""
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
provider "yandex" {
  token     = ""
  cloud_id  = ""
  folder_id = ""
  zone      = "ru-central1-a"
}
