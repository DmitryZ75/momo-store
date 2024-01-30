# Общее устройство

Пельменная - https://momo-store.dmitryz.ru <br>
ArgoCD - https://argocd.dmitryz.ru <br>
Grafana - https://grafana.dmitryz.ru <br>
Alertmanager - https://alertmanager.dmitryz.ru <br>
Prometheus - https://moonitoring.dmitryz.ru <br>
GitLab - https://gitlab.praktikum-services.ru<br>
Nexus - https://nexus.blackrockdz.synology.me<br>

Сервисы пельменной успешно функционируют в высокотехнологичном k8s-кластере, предоставленном Яндекс Cloud.

Для создания и настройки кластера используется мощный инструмент Terraform, обеспечивающий эффективное управление ресурсами.

Процесс сборки сервисов включает в себя создание Docker-образов, которые затем детально описываются в helm-чарте. Этот чарт представляет собой не только артефакт собранного приложения, но и ключевой компонент для последующего развертывания.

Для управления жизненным циклом приложения в кластере используется ArgoCD, тщательно интегрированный с Gitlab-репозиторием. В этом репозитории хранится helm-чарт приложения, и ArgoCD автоматически разворачивает наши сервисы в k8s, обеспечивая надежность и согласованность всего процесса.

# Развёртывание инфраструктуры и приложения.

- Устанавливаем terraform и проверяем установленную версию
```bash
wget https://hashicorp-releases.yandexcloud.net/terraform/1.5.5/terraform_1.5.5_linux_amd64.zip
unzip terraform_1.5.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -v
```
- Добавим иформацию о Yandex Cloud

```bash
touch ~/.terraformrc
echo 'provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}' > ~/.terraformrc
```
- Устанавливаем Yandex CLI
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
- Инициализируем профиль ``yc init``. 
- Получение данных о профиле - `yc config list`
- Создаём yc токен `yc iam create-token`
- Записываем значение token, cloud_id, folder_id s3_bucket_name в **infrastructure/s3-backend/terraform.tvars** и **infrastructure/main/terraform.tvars**
- Создаём бакет для хранения состояния основного terraform. выполняем `terraform appply` в **infrastructure/s3-backend**
- Проверяем `terraform validate`.
- Прогоняем `terraform plan`.
- Выполняем `terraform apply`.
- Экспортируем переменные командами
```bash
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw s3-secret-key)
export AWS_ACCESS_KEY_ID=$(terraform output -raw s3-access-key)
```
- Поднимаем кластер k8s:выполняем в папке **infrastructure/main/** команду ``terraform init``
- Проверяем `terraform validate`.
- Прогоняем `terraform plan`.
- Выполняем `terraform apply`.
- Устанавилваем kubectl:
```bash 
sudo snap install kubectl --classic
```
- Экспортируем конфигуцрацию кластера:
```bash
yc managed-kubernetes cluster get-credentials momo-store-cluster --external
```
- Получаем адрес Network Balancer для создания DNS-записей:
```bash
yc load-balancer network-load-balancer list --format json | jq -r '.[].id' | xargs -I {} yc load-balancer network-load-balancer get {} --format json | jq -r '.listeners'
```
•	momo-store.dmitryz.ru
•	alertmanager.dmitryz.ru
•	argocd.dmitryz.ru
•	grafana.dmitryz.ru
•	monitoring.dmitryz.ru




- Поднимаем ingress-controller в кластере: выполняем в папке **infrastructure/ingress-nginx/** команду ``kubectl apply -f ingress-deploy.yaml``
- Поднимаем cert-manager в кластере: выполняем в папке **infrastructure/cert-manager/** команду ``kubectl apply -f cert-manager-deploy.yaml``
- Создаем ClusterIssuer для cert-manager: выполняем в папке **infrastructure/cert-manager/** команду ``kubectl apply -f clusterIssuer-deploy.yaml``
- Поднимаем ArgoCD: выполняем в папке **infrastructure/argo-cd/** команду ``kubectl apply -f `` поочередно для namespace-argo-cd.yaml, deploy-argo-cd.yaml, ingress-service-argo-cd.yaml, user.yaml, user-policy.yaml
- Получаем пароль от учетки администратора в ArgoCD: выполняем команду ``kubectl -n argocd get secret argocd-initial-admin-secret -o=jsonpath='{.data.password}' | base64 --decode``. Заходим в эту учетку через UI и меняем пароль.




# Обновления приложения и инфраструктуры
- При внесении изменений в директории "backend" или "frontend" запускается pipeline для формирования helm-чарта и его отправки в nexus.
- Вся инфраструктура описана в коде, при необходимости изменения следует вносить в ***.tf** файлы или ***.yaml** файлы сервисов(**infrastructure**). Далее выполнить ``terraform apply``.