#!/bin/bash

# Скрипт точки входа для контейнера
# Этот скрипт выполняется при запуске контейнера

set -e  # Прерывать выполнение при любой ошибке

echo "🚀 Запуск OpenAPI Workstation..."
echo "📋 Java version: $(java -version 2>&1 | head -n 1)"
echo "📦 Node.js version: $(node -v)"
echo "🔧 OpenAPI Generator version: $(openapi-generator-cli version)"

# Проверяем наличие скачанной спецификации
if [ -f "/app/openapi.yaml" ]; then
    echo "✅ OpenAPI спецификация найдена: /app/openapi.yaml"
    
    # Генерируем клиентский SDK для TypeScript на основе спецификации
    # -i входной файл спецификации
    # -g генератор (язык/платформа)
    # -o выходная директория
    echo "🛠️ Генерация TypeScript клиента..."
    openapi-generator-cli generate \
        -i /app/openapi.yaml \
        -g typescript-axios \
        -o /app/generated/typescript-client \
        --skip-validate-spec
else
    echo "❌ OpenAPI спецификация не найдена!"
    exit 1
fi

# Запускаем простой HTTP-сервер для просмотра сгенерированной документации
echo "🌐 Запуск HTTP-сервера на порту 8080..."
echo "📖 Доступно по адресу: http://localhost:8080"
echo "⏹️ Для остановки нажмите Ctrl+C"

# Запускаем Node.js сервер
exec node /app/src/server.js