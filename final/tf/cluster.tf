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
