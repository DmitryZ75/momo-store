# Application part of repository

## О проекте

Приложение состоит из 2 микросервисов (frontend и backend), которое деплоится в Yandex Cloud через Managed Service for Kubernetes.

## Структура

Repository structure:
```
application
├── backend - файлы backend микросервиса
│   ├── cmd - исходники приложения
│   ├── internal - исходники приложения для тестов
│   ├── Dockerfile - dockerfile для сборки приложения в образ
│   ├── .gitlab-ci - CI/CD манифесты
│   ├── ... - остальное
├── frontend - файлы frontend приложения
│   ├── public - public сущности
│   ├── src - исходники приложения
│   ├── Dockerfile - dockerfile для сборки приложения в образ
│   ├── .gitlab-ci - CI/CD манифесты
│   ├── ... - остальное