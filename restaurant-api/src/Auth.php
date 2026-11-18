<?php
declare(strict_types=1);

final class Auth
{
    public static function issue(PDO $db, int $userId, int $days): string
    {
        $plain = bin2hex(random_bytes(32));
        $hash = hash('sha256', $plain);
        $expires = (new DateTimeImmutable("+{$days} days"))->format('Y-m-d H:i:s');
        $stmt = $db->prepare('INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)');
        $stmt->execute([$userId, $hash, $expires]);
        return $plain;
    }

    public static function user(PDO $db): array
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
            Http::json(401, ['ok' => false, 'message' => 'Token requerido']);
        }

        $hash = hash('sha256', trim($m[1]));
        $stmt = $db->prepare(
            'SELECT u.id, u.restaurant_id, u.username, u.name, u.role, u.active,
                    r.name AS restaurant_name, r.slug AS restaurant_slug
             FROM auth_tokens t
             JOIN users u ON u.id = t.user_id
             JOIN restaurants r ON r.id = u.restaurant_id
             WHERE t.token_hash = ?
               AND t.expires_at > NOW()
               AND u.active = 1
               AND r.active = 1
             LIMIT 1'
        );
        $stmt->execute([$hash]);
        $user = $stmt->fetch();

        if (!$user) {
            Http::json(401, ['ok' => false, 'message' => 'Token inválido, vencido o restaurante inactivo']);
        }

        $user['id'] = (string)$user['id'];
        $user['restaurant_id'] = (string)$user['restaurant_id'];
        return $user;
    }

    public static function requireRole(array $user, array $roles): void
    {
        if (!in_array($user['role'] ?? '', $roles, true)) {
            Http::json(403, ['ok' => false, 'message' => 'No tienes permisos para realizar esta acción']);
        }
    }

    public static function logout(PDO $db): void
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
            $stmt = $db->prepare('DELETE FROM auth_tokens WHERE token_hash = ?');
            $stmt->execute([hash('sha256', trim($m[1]))]);
        }
    }
}
