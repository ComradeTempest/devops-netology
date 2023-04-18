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
    access_key = "YCAJEHr7wXiARHd64LhrPc0U2"
    secret_key = "YCNy-ltLnlFjUXbM-daWq5dz7XnA5SLbALJesLBP"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
provider "yandex" {
  token     = "AQAAAABf4qNTAATuwSozT1SSNUrSplnNk943h48"
  cloud_id  = "b1gpd73ealtdsf16uniu"
  folder_id = "b1gvgevkn6e5fincv69b"
  zone      = "ru-central1-a"
}
