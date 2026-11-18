<?php
declare(strict_types=1);

final class Router
{
    private array $routes = [];

    public function add(string $method, string $pattern, callable $handler, bool $auth = true): void
    {
        $this->routes[] = [$method, $pattern, $handler, $auth];
    }

    public function dispatch(PDO $db, array $config): never
    {
        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
        if ($scriptDir !== '' && str_starts_with($path, $scriptDir)) $path = substr($path, strlen($scriptDir));
        $path = '/' . trim($path, '/');

        foreach ($this->routes as [$routeMethod, $pattern, $handler, $requiresAuth]) {
            if ($routeMethod !== $method) continue;
            $regex = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[^/]+)', $pattern);
            if (!preg_match('#^' . $regex . '$#', $path, $matches)) continue;
            $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
            $user = $requiresAuth ? Auth::user($db) : null;
            try {
                $result = $handler($db, $config, $params, $user);
                Http::json($result['status'] ?? 200, $result['body'] ?? ['ok' => true]);
            } catch (PDOException $e) {
                error_log('[Komanda API] Database error at ' . $method . ' ' . $path . ': ' . $e->getMessage());
                $debug = (bool)($config['app']['debug'] ?? false);
                Http::json(500, ['ok' => false, 'message' => 'Error de base de datos', 'detail' => $debug ? $e->getMessage() : null, 'sqlstate' => $e->getCode()]);
            } catch (Throwable $e) {
                $debug = (bool)($config['app']['debug'] ?? false);
                Http::json(500, ['ok' => false, 'message' => 'Error interno', 'detail' => $debug ? $e->getMessage() : null]);
            }
        }
        Http::json(404, ['ok' => false, 'message' => 'Ruta no encontrada', 'path' => $path]);
    }
}
