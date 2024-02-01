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
sudo apt install unzip
unzip terraform_1.5.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -v
```
- Устанавливаем Yandex CLI
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
exec -l $SHELL
```
- Инициализируем профиль ``yc init``. 
- Получение данных о профиле - `yc config list`
- Создаём yc токен `yc iam create-token`
- Записываем значение token, cloud_id, folder_id s3_bucket_name:
```bash
nano ~/infrastructure/main/terraform.tfvars
nano ~/infrastructure/s3/terraform.tfvars
```
- Создаём бакет для хранения состояния основного terraform. выполняем `terraform init` в **infrastructure/s3**
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
- Устанавка kubectl:
```bash 
sudo snap install kubectl --classic
```
- Установка k9s
```bash
sudo snap install go --classic
git clone https://github.com/derailed/k9s.git /tmp/k9s
sudo apt install make
cd /tmp/k9s/ && make build
sudo mv /tmp/k9s/execs/k9s /usr/local/bin/
```

- Экспортируем конфигурацию кластера:
```bash
yc managed-kubernetes cluster get-credentials momo-store-cluster --external
```
- Получаем адрес Network Balancer для создания DNS-записей:
```bash
sudo snap install jq
yc load-balancer network-load-balancer list --format json | jq -r '.[].id' | xargs -I {} yc load-balancer network-load-balancer get {} --format json | jq -r '.listeners'
```
•	momo-store.dmitryz.ru
•	alertmanager.dmitryz.ru
•	argocd.dmitryz.ru
•	grafana.dmitryz.ru
•	monitoring.dmitryz.ru


- Поднимаем ingress-controller в кластере: выполняем в папке **infrastructure/ingress-nginx/** 
```bash
cd ~/infrastructure/ingress-nginx/
kubectl apply -f ingress-deploy.yaml
```
- Поднимаем cert-manager в кластере: выполняем в папке **infrastructure/cert-manager/** 
```bash
cd ~/infrastructure/cert-manager/
kubectl apply -f cert-manager-deploy.yaml
kubectl apply -f clusterIssuer-deploy.yaml
```

- Устанока helm
```bash
cd ~/infrastructure/
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```


- Поднимаем ArgoCD: 
```bash
helm install   --namespace argo-cd   --create-namespace   argo-cd ./argo-cd/
cd ~/infrastructure/argo-cd/
kubectl apply -f ingress.yaml
```


- Получаем пароль от учетки администратора в ArgoCD: выполняем команду ``kubectl -n argocd get secret argocd-initial-admin-secret -o=jsonpath='{.data.password}' | base64 --decode``. Заходим в эту учетку через GUI и меняем пароль.

## устанвливаем средства мониторинга

- Инсталируем Loki
```bash

cd ~/infrastructure
chmod 700 loki_install.sh
dmitryz@dz-deploy:~/infrastructure$ ./loki_install.sh
kubectl config set-context --current --namespace=monitoring

```
- инсталируем AlertManager
```bash
helm upgrade --atomic --install alertmanager alertmanager
```
- инсталируем Prometheus
```bash

получить ключи!

helm upgrade --atomic --install prometheus prometheus
```
- инсталируем Grafana
```bash
helm upgrade --atomic --install grafana grafana
```

loki-loki-distributed-query-frontend

# Обновления приложения и инфраструктуры
- При внесении изменений в директории "backend" или "frontend" запускается pipeline для формирования helm-чарта и его отправки в nexus.
- Вся инфраструктура описана в коде, при необходимости изменения следует вносить в ***.tf** файлы или ***.yaml** файлы сервисов(**infrastructure**). Далее выполнить ``terraform apply``.

## дополнительно

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