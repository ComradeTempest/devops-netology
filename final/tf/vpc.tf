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
