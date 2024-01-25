variable "token" {
  description = "Yandex token"
}

variable "cloud_id" {
  description = "Yandex cloud id"
}

variable "folder_id" {
  description = "Yandex folder id"
}

variable "s3_bucket_name" {
  description = "Yandex s3 backet name"
}

variable "zone_id" {
  description = "Yandex zone id"
}

# locals {
#   cloud_id = var.cloud_id
#   folder_id = var.folder_id
#   image_bucket_name = var.s3_bucket_name
# }

# Создание сети

resource "yandex_vpc_network" "momo-store-network" {
  name = "momo-store-network"
}

# Создание подсети

resource "yandex_vpc_subnet" "momo-store-network-subnet" {
  name = "momo-store-network-subnet"
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = var.zone_id
  network_id     = yandex_vpc_network.momo-store-network.id
}

# Создание сервисного аккаунта

resource "yandex_iam_service_account" "momo-store-service-account" {
  name        = "momo-store-service-account"
}

resource "yandex_iam_service_account_static_access_key" "momo-store-service-account" {
  service_account_id = yandex_iam_service_account.momo-store-service-account.id
  description        = "static access key for object storage"
}

# поднимаем кластер k8s


resource "yandex_kubernetes_cluster" "momo-store-cluster" {
  name = "momo-store-cluster"
  network_id = yandex_vpc_network.momo-store-network.id
  master {
    zonal {
      zone      = yandex_vpc_subnet.momo-store-network-subnet.zone
      subnet_id = yandex_vpc_subnet.momo-store-network-subnet.id
    }
    public_ip = true
    security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
  }
  service_account_id      = yandex_iam_service_account.momo-store-service-account.id
  node_service_account_id = yandex_iam_service_account.momo-store-service-account.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller,
    yandex_resourcemanager_folder_iam_member.encrypterDecrypter
  ]
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
}

# Группа узлов

resource "yandex_kubernetes_node_group" "momo-store-groups-node" {
  cluster_id  = yandex_kubernetes_cluster.momo-store-cluster.id
  name        = "momo-kube-nodes"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.momo-store-network-subnet.id}"]
	  security_group_ids = [
        yandex_vpc_security_group.k8s-public-services.id,
        yandex_vpc_security_group.k8s-public-services.id
      ]
    }

    resources {
      memory = 4
      cores  = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }

  allocation_policy {
    location {
      zone = var.zone_id
    }
  }

  }

# Назначение роли "admin" сервисному аккаунту на уровне папки
resource "yandex_resourcemanager_folder_iam_binding" "admin-binding" {
  folder_id = var.folder_id
  role      = "admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}",
  ]
}

  # Сервисному аккаунту назначается роль "editor".
resource "yandex_resourcemanager_folder_iam_binding" "vpc-public-admin" {
  folder_id = var.folder_id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}"
  ]
}

# Сервисному аккаунту назначается роль "k8s.clusters.agent".
resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}"
}

# Сервисному аккаунту назначается роль "vpc.publicAdmin".
resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}"
}

# Сервисному аккаунту назначается роль "container-registry.images.puller".
resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}"
}

# Сервисному аккаунту назначается роль "kms.keys.encrypterDecrypter".
resource "yandex_resourcemanager_folder_iam_member" "encrypterDecrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.momo-store-service-account.id}"
}

# Ключ Yandex Key Management Service для шифрования важной информации, такой как пароли, OAuth-токены и SSH-ключи.
resource "yandex_kms_symmetric_key" "kms-key" {
  name              = "momo-dmitryz-kube-kms-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год.
}

#  конфигурация security group в облачной инфраструктуре Yandex.Cloud для Kubernetes-кластера

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.momo-store-network.id
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера Managed Service for Kubernetes и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера Managed Service for Kubernetes и сервисов."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.momo-store-network-subnet.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
  egress {
    protocol          = "ANY"
    description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}


# сделаем доступное хранилище для картинок и загрузим их

resource "yandex_iam_service_account" "s3_sa" {
  name = "s3-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "s3_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.s3_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "s3_static_key" {
  service_account_id = yandex_iam_service_account.s3_sa.id
  description        = "static access key for object storage"
}


resource "yandex_storage_bucket" "momo-store-bucket" {
  access_key = yandex_iam_service_account_static_access_key.s3_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_static_key.secret_key
  bucket = var.s3_bucket_name

  anonymous_access_flags {
    read = true
    list = false
    config_read = false
  }
  
  max_size = 104857601
  force_destroy = true
}

resource "yandex_storage_object" "images" {
  access_key = yandex_iam_service_account_static_access_key.s3_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_static_key.secret_key
  for_each = fileset("../images/", "*")
  bucket   = yandex_storage_bucket.momo-store-bucket.id
  key      = each.value
  source   = "../images/${each.value}"
} 

provider "yandex" {
  token       = var.token
  cloud_id    = var.cloud_id
  folder_id   = var.folder_id
  zone        = var.zone_id
}

# Резервирование статического IP адресса для приложения
resource "yandex_vpc_address" "momo-store-address" {
  name = "momo-store-address"
  deletion_protection = "false"
  external_ipv4_address {
  zone_id = var.zone_id
  }
}


output "momo-store-address" {
  sensitive = false
  value = yandex_vpc_address.momo-store-address.external_ipv4_address[*].address
}


# сохранение состояния

terraform {
    required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
  }
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-dmitryz-bucket"
    region     = "ru-central1"
    key        = "terraform.tfstate"


    skip_region_validation      = true
    skip_credentials_validation = true
  }

}
