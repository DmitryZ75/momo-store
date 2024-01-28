variable "token" {
  description = "Yandex token"
}

variable "cloud_id" {
  description = "Yandex cloud id"
}

variable "folder_id" {
  description = "Yandex folder id"
}

variable "zone_id" {
  description = "Yandex zone id"
}


variable "s3_bucket_name" {
  description = "Bucket name"
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}


provider "yandex" {
 token       = var.token
 cloud_id    = var.cloud_id
 folder_id   = var.folder_id
 zone        = var.zone_id
} 

# Определение служебной учетной записи IAM (Identity and Access Management):

resource "yandex_iam_service_account" "s3_terraform_backend" {
  name = "s3-terraform-backend"
}

# Назначение роли для учетной записи в папке:

resource "yandex_resourcemanager_folder_iam_member" "s3_terraform_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.s3_terraform_backend.id}"
}

# Создание статического ключа доступа для служебной учетной записи

resource "yandex_iam_service_account_static_access_key" "s3_terraform_static_key" {
  service_account_id = yandex_iam_service_account.s3_terraform_backend.id
  description        = "static access key for object storage"
}

# Создание бакета для объектного хранилища (Object Storage)

resource "yandex_storage_bucket" "terraform-dmitryz-bucket" {
  access_key = yandex_iam_service_account_static_access_key.s3_terraform_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_terraform_static_key.secret_key
  bucket = var.s3_bucket_name

  anonymous_access_flags {
    read = false
    list = false
    config_read = false
  }

  max_size = 104857601
  force_destroy = true
  
}


output "s3-bucket-name" {
  value = var.s3_bucket_name
}

output "s3-access-key" {
  sensitive = true
  value = yandex_iam_service_account_static_access_key.s3_terraform_static_key.access_key
}

output "s3-secret-key" {
  sensitive = true
  value = yandex_iam_service_account_static_access_key.s3_terraform_static_key.secret_key
}

# resource "null_resource" "export_variables" {
#   provisioner "local-exec" {
#     command = <<EOT
#       export AWS_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.s3_terraform_static_key.access_key}"
#       export AWS_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.s3_terraform_static_key.secret_key}"
#     EOT
#   }
# }
