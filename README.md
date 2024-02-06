# О проекте

Добро пожаловать в удивительный тренажер, предназначенный для демонстрации процессов построения и поддержки непрерывной интеграции и непрерывной доставки (CI/CD) на основе Gitlab CI. Проект также охватывает ключевые принципы DevOps, такие как "Инфраструктура как код" (IaaC) и основные инструменты DevOps, включая Terraform, Argo CD, а также множество других.

![Проект](https://dmitryz.ru/images/frontpage.png)

**Вы сможете прикоснуться к таким инструментам, как:**
- Bash
- Git
- Kubectl
- Helm
- Terraform
- И, конечно же, GUI!

**Дополнительные инструкции и файлы README доступны для:**
- Приложения в `./application`
- Инфраструктуры в `./infrastructure`

## Технологический стек
- **GO lang** - для бэкенд-приложения.
- **VUE framework** - для фронтенд-приложения.
- **Docker containers**
- Оркестрация **Kubernetes**

## Используемые инструменты

- **GitLab CI** - для хранения исходного кода приложения и инфраструктуры, а также выполнения процесса CI/CD.
- **SonarQube** - инструмент для анализа и оценки качества исходного кода.
- **Nexus** - репозиторий артефактов проекта.
- **Yandex Cloud** - для хранения инфраструктуры и приложения проекта.
- **Terraform** - для начального развертывания сред разработки и продукции.
- **Argo CD** - для доставки приложений Kubernetes.
- **Alertmanager/Prometheus/Loki** - система мониторинга и оповещения.
- **Grafana** - визуализатор логов и метрик.
