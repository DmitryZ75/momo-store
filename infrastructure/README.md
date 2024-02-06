# Общее устройство

Пельменная - <https://momo-store.dmitryz.ru> <br>

внешние сервисы:<br>
GitLab - <https://gitlab.praktikum-services.ru><br>
SonarQube https://sonarqube.praktikum-services.ru/ <br>
Nexus - <https://nexus.blackrockdz.synology.me><br>

создаваемые сервисы:<br>
ArgoCD - <https://argocd.dmitryz.ru> <br>
Alertmanager - <https://alertmanager.dmitryz.ru> <br>
Prometheus - <https://moonitoring.dmitryz.ru> <br>
Grafana - <https://grafana.dmitryz.ru> <br>

Сервисы пельменной успешно функционируют в высокотехнологичном k8s-кластере, предоставленном Яндекс Cloud.

Для создания и настройки кластера используется мощный инструмент Terraform, обеспечивающий эффективное управление ресурсами.

Процесс сборки сервисов включает в себя создание Docker-образов, которые затем детально описываются в helm-чарте. Этот чарт представляет собой не только артефакт собранного приложения, но и ключевой компонент для последующего развертывания.

Для управления жизненным циклом приложения в кластере используется ArgoCD, тщательно интегрированный с Gitlab-репозиторием. В этом репозитории хранится helm-чарт приложения, и ArgoCD автоматически разворачивает наши сервисы в k8s, обеспечивая надежность и согласованность всего процесса.

**Отказ от ответственности: При развертывании системы принимаются определенные компромиссы в области безопасности. Предполагается, что хост на базе Linux, с которого будут осуществляться все действия, не является боевой платформой и создан исключительно для и на время целей развертывания.**

# Развертывание приложения

- Все компоненты приложения находятся в GitLab
- Настроен CI/CD для backend, frontend, И helm-chart
- Добавлены переменные для CI/CD: NEXUS_REPO_BACKEND_NAME, NEXUS_REPO_PASS, NEXUS_REPO_URL_BACK, NEXUS_REPO_URL_FRONT, NEXUS_REPO_URL_HELM, NEXUS_REPO_USER, SONAR_LOGIN_BACKEND, SONAR_LOGIN_FRONT, SONAR_PROJECT_KEY_BACKEND, SONAR_PROJECT_KEY_FRONT, SONAR_PROJECT_NAME_BACKEND, SONAR_PROJECT_NAME_FRONT, SONARQUBE_URL

# Развёртывание инфраструктуры

- Устанавливаем terraform и проверяем установленную версию

```bash
sudo apt-get update && sudo apt-get upgrade -y
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

- Инициализируем профиль
- Получение данных о профиле
- Создаём yc токен

```bash
yc init
yc config list
yc iam create-token
```

- Записываем значение token, cloud_id, folder_id, zone_id:

```bash
nano ~/infrastructure/main/terraform.tfvars
nano ~/infrastructure/s3/terraform.tfvars
```

- Создаём бакет для хранения состояния основного terraform. выполняем `terraform init` в **infrastructure/s3**
- Проверяем `terraform validate`.
- Прогоняем `terraform plan`.
- Выполняем `terraform apply`.

```bash
cd ~/infrastructure/s3/
terraform init
terraform validate
terraform plan
terraform apply
```

- Экспортируем переменные командами

```bash
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw s3-secret-key)
export AWS_ACCESS_KEY_ID=$(terraform output -raw s3-access-key)
```

- Поднимаем кластер k8s:выполняем в папке **infrastructure/main/** команду ``terraform init``
- Проверяем `terraform validate`.
- Прогоняем `terraform plan`.
- Выполняем `terraform apply`.<br>

```bash
cd ~/infrastructure/main/
terraform init
terraform validate
terraform plan
terraform apply
```

- Установка kuberctl/k9s

```bash
sudo snap install kubectl --classic
sudo snap install go --classic
sudo snap install jq
git clone https://github.com/derailed/k9s.git /tmp/k9s
sudo apt install make
cd /tmp/k9s/ && make build
sudo mv /tmp/k9s/execs/k9s /usr/local/bin/
cd ~/infrastructure/
```

- Экспортируем конфигурацию кластера:

```bash
yc managed-kubernetes cluster get-credentials momo-store-cluster --external
```

- Поднимаем ingress-controller в кластере: выполняем в папке **infrastructure/ingress-nginx/**

```bash
cd ~/infrastructure/ingress-nginx/
kubectl apply -f ingress-deploy.yaml

```

- Получаем адрес Network Balancer для создания DNS-записей:

```bash
yc load-balancer network-load-balancer list --format json | jq -r '.[].id' | xargs -I {} yc load-balancer network-load-balancer get {} --format json | jq -r '.listeners'
```

• momo-store.dmitryz.ru
• alertmanager.dmitryz.ru
• argocd.dmitryz.ru
• grafana.dmitryz.ru
• monitoring.dmitryz.ru

- Поднимаем cert-manager в кластере: выполняем в папке **infrastructure/cert-manager/**

```bash
cd ~/infrastructure/cert-manager/
kubectl apply -f cert-manager-deploy.yaml
sleep 30
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

- Получаем пароль от учетной записи администратора в ArgoCD: выполняем команду

```bash
cd ~/infrastructure/
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Заходим  через GUI и меняем пароль.

- Инсталируем Loki

```bash
cd ~/infrastructure
helm install \
  --namespace monitoring \
  --create-namespace \
  --set loki-distributed.loki.storageConfig.aws.bucketnames=loki-dmitryz-bucket \
  loki ./loki/
kubectl config set-context --current --namespace=monitoring
```

- инсталируем AlertManager

```bash
helm upgrade --atomic --install alertmanager alertmanager
```

- получаем ключ для доспука к yandex.k8s кластеру yandex_cloud_services/service/

```bash
yc iam api-key create --service-account-name momo-store-service-account --description "this API-key is for Prometheus" | grep -oP 'secret:\s*\K\S+'
```

-записываем его в поле bearer_token

```bash
nano ./prometheus/values.yaml
```

- инсталируем Prometheus

```bash
helm upgrade --atomic --install prometheus prometheus
```

- инсталируем Grafana

```bash
helm upgrade --atomic --install grafana grafana
```

# Развертывание приложения

- В приложении <https://argocd.dmitryz.ru> добвьтей искомый репозиторий и созадйте приложение:

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: momo-store
spec:
  destination:
    name: ''
    namespace: momo-store
    server: 'https://kubernetes.default.svc'
  source:
    path: infrastructure/momo-store-chart
    repoURL: 'https://gitlab.praktikum-services.ru/std-021-024/momo-store.git'
    targetRevision: HEAD
  sources: []
  project: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
```

![Запущенное приложение](https://dmitryz.ru/images/agrocd.png)

# настраиваем Grafana

- Настройки источников для garfana:<br>
Loki: **<http://loki-loki-distributed-query-frontend:3100>**<br>
Prometheus: **<http://prometheus:9090>**
- Добавляем dashboard из каталога **infrastructure/main/dashboards**
![Логи](https://dmitryz.ru/images/logs_dashboard.png)
![Loki](https://dmitryz.ru/images/loki_stack_monitoring.png)
![Инфрастуктура](https://dmitryz.ru/images/infrastructure.png)
![Бизнес](https://dmitryz.ru/images/business.png)

# Обновления приложения и инфраструктуры

- Каждое изменение в коде приложения создает новую версию, которая хранится отдельно.
- При внесении изменений в директории "backend" или "frontend" запускается pipeline для формирования артефактов и отправки в nexus, также создаются новые образы docker и помещаются в containet regestry. 
- При внесении изменений в директории "momo-store-chart" запускается pipeline для формирования helm-чарта и его отправки в nexus и исполнения в argo-cd.
- Вся инфраструктура описана в коде, при необходимости изменения следует вносить в ***.tf** файлы или***.yaml** файлы сервисов(**infrastructure**). Далее выполнить ``terraform apply`` (не забыв обновить ключ) или ``kuberctl apply`` или ``helm update``.

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
