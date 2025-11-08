// Простой HTTP-сервер для обслуживания статических файлов
// Позволяет просматривать сгенерированную документацию

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const BASE_DIR = '/app';

// Функция для определения MIME-типа файла
function getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const mimeTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.gif': 'image/gif',
        '.yaml': 'text/yaml',
        '.yml': 'text/yaml'
    };
    return mimeTypes[ext] || 'text/plain';
}

// Создаем HTTP сервер
const server = http.createServer((req, res) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    
    // Безопасно формируем путь к файлу
    let filePath = path.join(BASE_DIR, req.url);
    
    // Если запрос к корню, показываем индексный файл
    if (req.url === '/') {
        filePath = path.join(BASE_DIR, 'index.html');
    }
    
    // Проверяем, что файл находится внутри BASE_DIR (безопасность)
    if (!filePath.startsWith(BASE_DIR)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }
    
    // Читаем и отдаем файл
    fs.readFile(filePath, (err, data) => {
        if (err) {
            if (err.code === 'ENOENT') {
                // Файл не найден - показываем список доступных файлов
                showDirectoryListing(req.url, res);
            } else {
                res.writeHead(500);
                res.end('Server Error');
            }
        } else {
            // Успешно отдаем файл
            res.writeHead(200, {
                'Content-Type': getMimeType(filePath),
                'Access-Control-Allow-Origin': '*'
            });
            res.end(data);
        }
    });
});

// Функция для показа списка файлов в директории
function showDirectoryListing(url, res) {
    const dirPath = path.join(BASE_DIR, url);
    
    fs.readdir(dirPath, (err, files) => {
        if (err) {
            res.writeHead(404);
            res.end('File not found');
            return;
        }
        
        let html = `
            <html>
                <head>
                    <title>OpenAPI Workstation - ${url}</title>
                    <style>
                        body { font-family: Arial, sans-serif; margin: 40px; }
                        li { margin: 10px 0; }
                        a { text-decoration: none; color: #0366d6; }
                    </style>
                </head>
                <body>
                    <h1>📁 OpenAPI Workstation</h1>
                    <h2>Директория: ${url}</h2>
                    <ul>
        `;
        
        // Добавляем ссылку на родительскую директорию
        if (url !== '/') {
            const parentDir = path.dirname(url);
            html += `<li><a href="${parentDir}">../</a></li>`;
        }
        
        // Добавляем файлы и папки
        files.forEach(file => {
            const filePath = path.join(url, file);
            const isDir = fs.statSync(path.join(BASE_DIR, filePath)).isDirectory();
            const icon = isDir ? '📁' : '📄';
            html += `<li>${icon} <a href="${filePath}">${file}${isDir ? '/' : ''}</a></li>`;
        });
        
        html += `
                    </ul>
                    <hr>
                    <p><small>OpenAPI Workstation Container</small></p>
                </body>
            </html>
        `;
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
    });
}

// Запускаем сервер
server.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ HTTP сервер запущен на порту ${PORT}`);
    console.log(`📁 Рабочая директория: ${BASE_DIR}`);
    console.log(`🛠️ Сгенерированные файлы: ${BASE_DIR}/generated/`);
});

// Обработка graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Остановка сервера...');
    process.exit(0);
});