<?php
$title = $title ?? 'Мои заметки';
?>

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($title) ?></title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header h1 { color: #333; }
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
        .btn-danger { background: #e53e3e; }
        .btn-danger:hover { background: #c53030; }
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
        .empty-state {
            text-align: center;
            padding: 60px;
            background: white;
            border-radius: 10px;
            color: #999;
        }
        .empty-state .btn {
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><?= htmlspecialchars($title) ?></h1>
            <a href="/notes/create" class="btn">+ Создать заметку</a>
        </div>

        <?php if (empty($notes)): ?>
            <div class="empty-state">
                <p>У вас пока нет заметок</p>
                <p><a href="/notes/create" class="btn">Создать первую заметку</a></p>
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
    </div>
</body>
</html>
