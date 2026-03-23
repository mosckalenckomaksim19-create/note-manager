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
