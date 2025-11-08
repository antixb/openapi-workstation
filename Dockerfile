# Используем Alpine Linux 3.26 как базовый образ
# Это минималистичный и безопасный дистрибутив
FROM alpine:3.19

# Устанавливаем метаданные для образа
LABEL maintainer="your-email@example.com"
LABEL description="Универсальная OpenAPI Workstation с Node.js 22 и Java 21"
LABEL version="1.0"

# Устанавливаем переменные окружения для удобства maintenance
# JAVA_HOME - путь к установленной Java
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
# PATH - добавляем пути к установленным утилитам
ENV PATH=$JAVA_HOME/bin:/nodejs/bin:/root/.npm/bin:$PATH
# Настраиваем npm глобальные установки без sudo
ENV NPM_CONFIG_PREFIX=/root/.npm

# Устанавливаем необходимые пакеты в один слой (для уменьшения размера образа)
# apk update - обновление индексов пакетов
# apk add - установка пакетов:
#   openjdk21-jre - Java Runtime Environment 21 версии
#   nodejs npm - Node.js 22 и менеджер пакетов npm (в Alpine 3.26 это актуальные версии)
#   wget - утилита для скачивания файлов по HTTP/HTTPS
#   bash - более удобная оболочка чем стандартная ash
RUN apk update && \
    apk add --no-cache \
    openjdk21-jre \
    nodejs \
    npm \
    wget \
    bash

# Создаем симлинк для nodejs -> node (некоторые пакеты ожидают бинарник 'node')
RUN ln -sf /usr/bin/node /usr/bin/nodejs

# Устанавливаем OpenAPI Generator CLI глобально через npm
# Эта утилита будет генерировать клиентские SDK и серверные заглушки
RUN npm install -g @openapitools/openapi-generator-cli

# Создаем рабочую директорию в контейнере
WORKDIR /app

# Копируем скрипты и исходный код в контейнер
# Скрипт точки входа
COPY scripts/entrypoint.sh /entrypoint.sh
# Простой HTTP-сервер на Node.js
COPY src/server.js /app/src/server.js

# Делаем скрипт точки входа исполняемым
RUN chmod +x /entrypoint.sh

# Скачиваем пример OpenAPI спецификации (PetStore)
# Используем стандартный пример от OpenAPI Initiative
RUN wget -O /app/openapi.yaml \
    https://raw.githubusercontent.com/swagger-api/swagger-petstore/master/src/main/resources/openapi.yaml

# Указываем точку входа - скрипт, который запустится при старте контейнера
ENTRYPOINT ["/entrypoint.sh"]