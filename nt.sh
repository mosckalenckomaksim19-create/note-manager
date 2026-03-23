# Создаем структуру папок
mkdir -p docker/nginx src/Controllers src/Models templates public storage

# Создаем файлы с содержимым

# composer.json
cat > composer.json << 'EOF'
{
    "name": "note-manager/app",
    "description": "Simple Note Manager Application",
    "type": "project",
    "require": {
        "php": "^8.1",
        "slim/slim": "^4.12",
        "slim/psr7": "^1.6",
        "vlucas/phpdotenv": "^5.5"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
EOF

# public/index.php
cat > public/index.php << 'EOF'
<?php

use App\Controllers\NoteController;
use Slim\Factory\AppFactory;
use Slim\Views\PhpRenderer;

require __DIR__ . '/../vendor/autoload.php';

// Загрузка переменных окружения
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->safeLoad();

// Создание приложения
$app = AppFactory::create();

// Добавление middleware для парсинга JSON
$app->addBodyParsingMiddleware();

// Настройка рендерера шаблонов
$renderer = new PhpRenderer(__DIR__ . '/../templates');

// Маршруты
$app->get('/', [NoteController::class, 'index'])->setName('home');
$app->get('/notes/create', [NoteController::class, 'create'])->setName('notes.create');
$app->post('/notes', [NoteController::class, 'store'])->setName('notes.store');
$app->get('/notes/{id}/edit', [NoteController::class, 'edit'])->setName('notes.edit');
$app->put('/notes/{id}', [NoteController::class, 'update'])->setName('notes.update');
$app->delete('/notes/{id}', [NoteController::class, 'delete'])->setName('notes.delete');

// Запуск приложения
$app->run();
EOF

# src/Models/Note.php
cat > src/Models/Note.php << 'EOF'
<?php

namespace App\Models;

class Note
{
    private $storageFile;
    
    public function __construct()
    {
        $this->storageFile = __DIR__ . '/../../storage/notes.json';
        $this->initializeStorage();
    }
    
    private function initializeStorage()
    {
        if (!file_exists($this->storageFile)) {
            file_put_contents($this->storageFile, json_encode([]));
        }
    }
    
    private function readNotes()
    {
        $content = file_get_contents($this->storageFile);
        return json_decode($content, true) ?: [];
    }
    
    private function writeNotes($notes)
    {
        file_put_contents($this->storageFile, json_encode($notes, JSON_PRETTY_PRINT));
    }
    
    public function getAll()
    {
        return $this->readNotes();
    }
    
    public function find($id)
    {
        $notes = $this->readNotes();
        return $notes[$id] ?? null;
    }
    
    public function create($title, $content)
    {
        $notes = $this->readNotes();
        $id = uniqid();
        $notes[$id] = [
            'id' => $id,
            'title' => $title,
            'content' => $content,
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s')
        ];
        $this->writeNotes($notes);
        return $id;
    }
    
    public function update($id, $title, $content)
    {
        $notes = $this->readNotes();
        if (isset($notes[$id])) {
            $notes[$id]['title'] = $title;
            $notes[$id]['content'] = $content;
            $notes[$id]['updated_at'] = date('Y-m-d H:i:s');
            $this->writeNotes($notes);
            return true;
        }
        return false;
    }
    
    public function delete($id)
    {
        $notes = $this->readNotes();
        if (isset($notes[$id])) {
            unset($notes[$id]);
            $this->writeNotes($notes);
            return true;
        }
        return false;
    }
}
EOF

# src/Controllers/NoteController.php
cat > src/Controllers/NoteController.php << 'EOF'
<?php

namespace App\Controllers;

use App\Models\Note;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Views\PhpRenderer;

class NoteController
{
    private $note;
    private $renderer;
    
    public function __construct()
    {
        $this->note = new Note();
        $this->renderer = new PhpRenderer(__DIR__ . '/../../templates');
    }
    
    public function index(Request $request, Response $response): Response
    {
        $notes = $this->note->getAll();
        return $this->renderer->render($response, 'index.php', [
            'notes' => $notes,
            'title' => 'Мои заметки'
        ]);
    }
    
    public function create(Request $request, Response $response): Response
    {
        return $this->renderer->render($response, 'create.php', [
            'title' => 'Создать заметку'
        ]);
    }
    
    public function store(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();
        
        if (empty($data['title']) || empty($data['content'])) {
            return $response->withHeader('Location', '/notes/create')
                           ->withStatus(302);
        }
        
        $this->note->create($data['title'], $data['content']);
        return $response->withHeader('Location', '/')->withStatus(302);
    }
    
    public function edit(Request $request, Response $response, array $args): Response
    {
        $note = $this->note->find($args['id']);
        
        if (!$note) {
            return $response->withHeader('Location', '/')->withStatus(302);
        }
        
        return $this->renderer->render($response, 'edit.php', [
            'note' => $note,
            'title' => 'Редактировать заметку'
        ]);
    }
    
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        
        $this->note->update($args['id'], $data['title'], $data['content']);
        return $response->withHeader('Location', '/')->withStatus(302);
    }
    
    public function delete(Request $request, Response $response, array $args): Response
    {
        $this->note->delete($args['id']);
        return $response->withHeader('Location', '/')->withStatus(302);
    }
}
EOF

# templates/layout.php
cat > templates/layout.php << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?? 'Note Manager' ?></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            color: #333;
        }
        
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
            font-size: 14px;
        }
        
        .btn:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }
        
        .btn-danger {
            background: #e53e3e;
        }
        
        .btn-danger:hover {
            background: #c53030;
        }
        
        .notes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .note-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }
        
        .note-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        
        .note-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        
        .note-content {
            color: #666;
            margin-bottom: 15px;
            line-height: 1.5;
        }
        
        .note-date {
            font-size: 12px;
            color: #999;
            margin-bottom: 15px;
        }
        
        .note-actions {
            display: flex;
            gap: 10px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .form-group textarea {
            min-height: 150px;
            resize: vertical;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px;
            background: white;
            border-radius: 10px;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="container">
        <?= $content ?>
    </div>
</body>
</html>
EOF

# templates/index.php
cat > templates/index.php << 'EOF'
<?php $this->layout('layout', ['title' => $title]) ?>

<div class="header">
    <h1><?= $title ?></h1>
    <a href="/notes/create" class="btn">+ Создать заметку</a>
</div>

<?php if (empty($notes)): ?>
    <div class="empty-state">
        <p>У вас пока нет заметок</p>
        <p style="margin-top: 10px;">
            <a href="/notes/create" class="btn">Создать первую заметку</a>
        </p>
    </div>
<?php else: ?>
    <div class="notes-grid">
        <?php foreach ($notes as $note): ?>
            <div class="note-card">
                <div class="note-title"><?= htmlspecialchars($note['title']) ?></div>
                <div class="note-content"><?= htmlspecialchars(substr($note['content'], 0, 100)) ?>...</div>
                <div class="note-date">Создано: <?= $note['created_at'] ?></div>
                <div class="note-actions">
                    <a href="/notes/<?= $note['id'] ?>/edit" class="btn">Редактировать</a>
                    <form action="/notes/<?= $note['id'] ?>" method="POST" style="display: inline;">
                        <input type="hidden" name="_METHOD" value="DELETE">
                        <button type="submit" class="btn btn-danger" onclick="return confirm('Удалить заметку?')">Удалить</button>
                    </form>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>
EOF

# templates/create.php
cat > templates/create.php << 'EOF'
<?php $this->layout('layout', ['title' => $title]) ?>

<div class="card">
    <h1><?= $title ?></h1>
    
    <form action="/notes" method="POST" style="margin-top: 20px;">
        <div class="form-group">
            <label for="title">Заголовок</label>
            <input type="text" id="title" name="title" required>
        </div>
        
        <div class="form-group">
            <label for="content">Содержание</label>
            <textarea id="content" name="content" required></textarea>
        </div>
        
        <div style="display: flex; gap: 10px;">
            <button type="submit" class="btn">Сохранить</button>
            <a href="/" class="btn" style="background: #999;">Отмена</a>
        </div>
    </form>
</div>
EOF

# templates/edit.php
cat > templates/edit.php << 'EOF'
<?php $this->layout('layout', ['title' => $title]) ?>

<div class="card">
    <h1><?= $title ?></h1>
    
    <form action="/notes/<?= $note['id'] ?>" method="POST" style="margin-top: 20px;">
        <input type="hidden" name="_METHOD" value="PUT">
        
        <div class="form-group">
            <label for="title">Заголовок</label>
            <input type="text" id="title" name="title" value="<?= htmlspecialchars($note['title']) ?>" required>
        </div>
        
        <div class="form-group">
            <label for="content">Содержание</label>
            <textarea id="content" name="content" required><?= htmlspecialchars($note['content']) ?></textarea>
        </div>
        
        <div style="display: flex; gap: 10px;">
            <button type="submit" class="btn">Обновить</button>
            <a href="/" class="btn" style="background: #999;">Отмена</a>
        </div>
    </form>
</div>
EOF

# Dockerfile
cat > Dockerfile << 'EOF'
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

RUN composer install --no-interaction --optimize-autoloader

EXPOSE 9000
EOF

# docker/nginx/default.conf
cat > docker/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:latest
    container_name: note-manager-nginx
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
    networks:
      - app-network

  php:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: note-manager-php
    volumes:
      - ./:/var/www/html
    networks:
      - app-network
    environment:
      - PHP_IDE_CONFIG=serverName=localhost

networks:
  app-network:
    driver: bridge
EOF

# .env.example
cat > .env.example << 'EOF'
APP_ENV=development
APP_DEBUG=true
EOF

# .gitignore
cat > .gitignore << 'EOF'
vendor/
storage/notes.json
.env
.DS_Store
EOF

# Создаем пустой файл storage/notes.json
echo '[]' > storage/notes.json

# Устанавливаем права на storage
chmod 755 storage
chmod 666 storage/notes.json

echo "✅ Структура проекта успешно создана!"
echo ""
echo "Для запуска выполните:"
echo "cd note-manager"
echo "docker-compose up -d"
echo ""
echo "После запуска откройте http://localhost:8080"
