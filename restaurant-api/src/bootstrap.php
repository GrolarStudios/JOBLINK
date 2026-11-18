<?php
declare(strict_types=1);

$configFile = dirname(__DIR__) . '/config.php';
if (!is_file($configFile)) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => false, 'message' => 'Falta config.php. Copia config.example.php y configura la base de datos.']);
    exit;
}

$config = require $configFile;
date_default_timezone_set($config['app']['timezone'] ?? 'America/Mexico_City');

require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Http.php';
require_once __DIR__ . '/Auth.php';
require_once __DIR__ . '/Router.php';

$db = Database::connect($config['database']);
