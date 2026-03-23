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
        // Создаем экземпляр рендерера напрямую
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
