# Clinic Service API

Проект на **Ruby on Rails**, тесты — **RSpec**, документация — **Swagger (OpenAPI 3.0.3)** через [rswag](https://github.com/rswag/rswag).

## Сборка контейнера

```bash
docker-compose build
```
## Подготовка базы данных

```bash
docker-compose exec web bash
```

```bash
rails db:migrate
rails db:seed
```
## Запуск

```bash
docker-compose -f docker-compose.yml up -d
```