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
