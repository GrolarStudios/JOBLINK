<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("Ejecuta este archivo desde la terminal de cPanel.\n");
}

$configPath = dirname(__DIR__) . '/config.php';
if (!is_file($configPath)) exit("Falta config.php\n");
$config = require $configPath;
$dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=%s', $config['database']['host'], $config['database']['port'], $config['database']['name'], $config['database']['charset']);
$pdo = new PDO($dsn, $config['database']['user'], $config['database']['password'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

function ask(string $label): string { echo $label; return trim((string)fgets(STDIN)); }
$name = ask('Nombre del restaurante: ');
$slug = ask('Slug (ej. tacos-don-pepe): ');
$username = ask('Usuario administrador: ');
$fullName = ask('Nombre del administrador: ');
$password = ask('Contraseña: ');
if ($name === '' || $slug === '' || $username === '' || $fullName === '' || $password === '') exit("Todos los campos son obligatorios.\n");

$pdo->beginTransaction();
try {
    $pdo->prepare('INSERT INTO restaurants(name,slug,active) VALUES(?,?,1)')->execute([$name,$slug]);
    $restaurantId=(int)$pdo->lastInsertId();
    $pdo->prepare('INSERT INTO users(restaurant_id,username,name,password_hash,role,active) VALUES(?,?,?,?,\'admin\',1)')->execute([$restaurantId,$username,$fullName,password_hash($password,PASSWORD_DEFAULT)]);
    $pdo->commit();
    echo "Restaurante y administrador creados. restaurant_id={$restaurantId}\n";
} catch (Throwable $e) {
    $pdo->rollBack();
    fwrite(STDERR, $e->getMessage()."\n");
    exit(1);
}
