<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/bootstrap.php';
Http::cors($config);
$router = new Router();

function restaurantId(array $user): int
{
    return (int)$user['restaurant_id'];
}

function productPayload(PDO $db, array $product, array $visitedProductIds = []): array
{
    $productId = (int)$product['id'];
    $visitedProductIds[$productId] = true;

    $groupsStmt = $db->prepare(
        'SELECT g.id, g.name, g.multiple, g.required_flag, g.min_selections, g.max_selections,
                g.allow_repeats, g.catalog_id, oc.name AS catalog_name
         FROM product_option_groups g
         LEFT JOIN option_catalogs oc ON oc.id = g.catalog_id AND oc.active = 1
         WHERE g.product_id = ?
         ORDER BY g.sort_order, g.id'
    );
    $groupsStmt->execute([$productId]);

    $groups = [];
    foreach ($groupsStmt->fetchAll() as $group) {
        $catalogId = !empty($group['catalog_id']) ? (int)$group['catalog_id'] : null;

        if ($catalogId !== null) {
            $optionsStmt = $db->prepare(
                'SELECT v.id, v.label, v.extra_price, v.complement_id, v.linked_product_id,
                        v.default_quantity, c.name AS complement_name, c.active AS complement_active,
                        lp.name AS linked_product_name, lp.category AS linked_product_category,
                        lp.price AS linked_product_price, lp.restaurant_id AS linked_restaurant_id,
                        lp.description AS linked_description, lp.available AS linked_available,
                        lp.image_url AS linked_image_url, lp.product_kind AS linked_product_kind,
                        lp.pricing_mode AS linked_pricing_mode
                 FROM option_catalog_values v
                 LEFT JOIN complements c ON c.id = v.complement_id
                 LEFT JOIN products lp ON lp.id = v.linked_product_id
                 WHERE v.catalog_id = ? AND v.active = 1
                 ORDER BY v.sort_order, v.id'
            );
            $optionsStmt->execute([$catalogId]);
        } else {
            $optionsStmt = $db->prepare(
                'SELECT po.id, po.label, po.extra_price, po.complement_id,
                        po.linked_product_id, po.default_quantity,
                        c.name AS complement_name, c.active AS complement_active,
                        lp.name AS linked_product_name, lp.category AS linked_product_category,
                        lp.price AS linked_product_price, lp.restaurant_id AS linked_restaurant_id,
                        lp.description AS linked_description, lp.available AS linked_available,
                        lp.image_url AS linked_image_url, lp.product_kind AS linked_product_kind,
                        lp.pricing_mode AS linked_pricing_mode
                 FROM product_options po
                 LEFT JOIN complements c ON c.id = po.complement_id
                 LEFT JOIN products lp ON lp.id = po.linked_product_id
                 WHERE po.group_id = ?
                 ORDER BY po.sort_order, po.id'
            );
            $optionsStmt->execute([$group['id']]);
        }

        $options = [];
        foreach ($optionsStmt->fetchAll() as $option) {
            // Si una opción está ligada a un complemento agotado/inactivo,
            // no debe aparecer al levantar ni editar pedidos.
            if (!empty($option['complement_id']) && !(bool)($option['complement_active'] ?? false)) {
                continue;
            }

            // Compatibilidad con configuraciones antiguas que guardaban la
            // opción únicamente por label y no por complement_id. Si existe un
            // complemento con el mismo nombre y está agotado, también se oculta.
            if (empty($option['complement_id'])) {
                $label = trim((string)($option['label'] ?? ''));
                if ($label !== '') {
                    $legacyComplementStmt = $db->prepare(
                        'SELECT active FROM complements WHERE restaurant_id=? AND LOWER(name)=LOWER(?) LIMIT 1'
                    );
                    $legacyComplementStmt->execute([(int)$product['restaurant_id'], $label]);
                    $legacyActive = $legacyComplementStmt->fetchColumn();
                    if ($legacyActive !== false && !(bool)$legacyActive) {
                        continue;
                    }
                }
            }

            $linkedProduct = null;
            $linkedId = !empty($option['linked_product_id']) ? (int)$option['linked_product_id'] : null;
            // Un producto agotado tampoco puede seleccionarse como componente
            // interno de un paquete.
            if ($linkedId !== null && !(bool)($option['linked_available'] ?? false)) {
                continue;
            }
            if ($linkedId !== null && empty($visitedProductIds[$linkedId])) {
                $linkedRow = [
                    'id' => $linkedId,
                    'restaurant_id' => (int)($option['linked_restaurant_id'] ?? $product['restaurant_id']),
                    'name' => $option['linked_product_name'] ?? '',
                    'category' => $option['linked_product_category'] ?? '',
                    'price' => (float)($option['linked_product_price'] ?? 0),
                    'description' => $option['linked_description'] ?? '',
                    'available' => (int)($option['linked_available'] ?? 1),
                    'image_url' => $option['linked_image_url'] ?? '',
                    'product_kind' => $option['linked_product_kind'] ?? 'simple',
                    'pricing_mode' => $option['linked_pricing_mode'] ?? 'fixed',
                ];
                $linkedProduct = productPayload($db, $linkedRow, $visitedProductIds);
            }

            $options[] = [
                'id' => (string)$option['id'],
                'label' => $option['label'],
                'extraPrice' => (float)$option['extra_price'],
                'complementId' => $option['complement_id'] ? (string)$option['complement_id'] : '',
                'complementName' => $option['complement_name'] ?? '',
                'linkedProductId' => $linkedId !== null ? (string)$linkedId : '',
                'linkedProductName' => $option['linked_product_name'] ?? '',
                'linkedProductCategory' => $option['linked_product_category'] ?? '',
                'linkedProductPrice' => (float)($option['linked_product_price'] ?? 0),
                'defaultQuantity' => max(1, (int)($option['default_quantity'] ?? 1)),
                'linkedProduct' => $linkedProduct,
            ];
        }

        $groups[] = [
            'id' => (string)$group['id'],
            'name' => $group['name'],
            'multiple' => (bool)$group['multiple'],
            'required' => (bool)$group['required_flag'],
            'minSelections' => (int)$group['min_selections'],
            'maxSelections' => $group['max_selections'] === null ? null : (int)$group['max_selections'],
            'allowRepeats' => (bool)$group['allow_repeats'],
            'catalogId' => $catalogId !== null ? (string)$catalogId : '',
            'catalogName' => $group['catalog_name'] ?? '',
            'options' => $options,
        ];
    }

    $printPrefix = '';
    if (!empty($product['restaurant_id']) && !empty($product['category'])) {
        $prefixStmt = $db->prepare('SELECT print_prefix FROM categories WHERE restaurant_id=? AND name=? LIMIT 1');
        $prefixStmt->execute([(int)$product['restaurant_id'], (string)$product['category']]);
        $printPrefix = (string)($prefixStmt->fetchColumn() ?: '');
    }

    return [
        'id' => (string)$productId,
        'name' => $product['name'],
        'printName' => productPrintName((string)$product['name'], $printPrefix),
        'category' => $product['category'],
        'price' => (float)$product['price'],
        'available' => (bool)$product['available'],
        'description' => $product['description'] ?? '',
        'imageUrl' => $product['image_url'] ?? '',
        'productKind' => $product['product_kind'] ?? 'simple',
        'pricingMode' => $product['pricing_mode'] ?? 'fixed',
        'optionGroups' => $groups,
    ];
}

function productPrintName(string $name, ?string $prefix): string
{
    $name = trim($name);
    $prefix = trim((string)$prefix);
    if ($prefix === '' || $name === '') return $name;
    if (stripos($name, $prefix . ' ') === 0 || strcasecmp($name, $prefix) === 0) return $name;
    return $prefix . ' ' . $name;
}

function orderPayload(PDO $db, array $order): array
{
    $itemsStmt = $db->prepare(
        'SELECT oi.*, p.category AS product_category, c.print_prefix
         FROM order_items oi
         LEFT JOIN products p ON p.id = oi.product_id
         LEFT JOIN categories c ON c.restaurant_id = p.restaurant_id AND c.name = p.category
         WHERE oi.order_id = ?
         ORDER BY oi.id'
    );
    $itemsStmt->execute([$order['id']]);
    $items = [];
    foreach ($itemsStmt->fetchAll() as $item) {
        $specStmt = $db->prepare('SELECT specification FROM order_item_specifications WHERE order_item_id = ? ORDER BY id');
        $specStmt->execute([$item['id']]);
        $items[] = [
            'id' => (string)$item['id'],
            'productId' => $item['product_id'] ? (string)$item['product_id'] : '',
            'name' => productPrintName((string)$item['product_name'], $item['print_prefix'] ?? null),
            'rawName' => $item['product_name'],
            'category' => $item['product_category'] ?? '',
            'quantity' => (int)$item['quantity'],
            'unitPrice' => (float)$item['unit_price'],
            'total' => (float)$item['line_total'],
            'specifications' => array_column($specStmt->fetchAll(), 'specification'),
        ];
    }
    return [
        'id'=>(string)$order['id'],'folio'=>$order['folio'],'table'=>$order['table_name'],
        'isTakeaway'=>(bool)$order['is_takeaway'],'isUrgent'=>(bool)$order['is_urgent'],
        'status'=>$order['status'],'notes'=>$order['notes']??'',
        'waiterId'=>$order['waiter_id']?(string)$order['waiter_id']:'','waiterName'=>$order['waiter_name']??'',
        'subtotal'=>(float)$order['subtotal'],'tipAmount'=>(float)$order['tip_amount'],'tipMode'=>$order['tip_mode'],
        'tipPercentage'=>(float)$order['tip_percentage'],'total'=>(float)$order['total_amount'],'isPaid'=>(bool)$order['is_paid'],
        'paymentMethod'=>$order['payment_method']??'','amountReceived'=>(float)$order['amount_received'],'changeAmount'=>(float)$order['change_amount'],
        'paymentDifference'=>(float)$order['amount_received']-(float)$order['total_amount'],
        'createdAt'=>$order['created_at'],'updatedAt'=>$order['updated_at'],'paidAt'=>$order['paid_at'],
        'deliveredAt'=>$order['delivered_at'],'releasedAt'=>$order['released_at'],
        'preparingAt'=>$order['preparing_at']??null,'readyAt'=>$order['ready_at']??null,
        'orderType'=>$order['order_type']??((bool)$order['is_takeaway']?'TAKEAWAY':'DINE_IN'),
        'customerName'=>$order['customer_name']??'','kitchenName'=>$order['kitchen_name']??'','customerPhone'=>$order['customer_phone']??'','deliveryAddress'=>$order['delivery_address']??'',
        'deliveryFee'=>(float)($order['delivery_fee']??0),'paidAmount'=>(float)($order['paid_amount']??0),
        'createdByUserId'=>$order['created_by_user_id']?(string)$order['created_by_user_id']:'','items'=>$items,
    ];
}

function tableHasColumn(PDO $db, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    $stmt = $db->prepare(
        'SELECT COUNT(*)
         FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = ?
           AND COLUMN_NAME = ?'
    );
    $stmt->execute([$table, $column]);
    return $cache[$key] = ((int)$stmt->fetchColumn() > 0);
}

function saveGroups(PDO $db, int $productId, array $groups): void
{
    $hasCatalogId = tableHasColumn($db, 'product_option_groups', 'catalog_id');

    foreach ($groups as $groupIndex => $group) {
        $name = trim((string)($group['name'] ?? ''));
        if ($name === '') continue;

        if ($hasCatalogId) {
            $stmt = $db->prepare(
                'INSERT INTO product_option_groups
                 (product_id,name,multiple,required_flag,min_selections,max_selections,allow_repeats,catalog_id,sort_order)
                 VALUES (?,?,?,?,?,?,?,?,?)'
            );
            $stmt->execute([
                $productId,$name,(int)($group['multiple']??0),(int)($group['required']??0),
                (int)($group['minSelections']??0),
                array_key_exists('maxSelections',$group) && $group['maxSelections'] !== null ? (int)$group['maxSelections'] : null,
                (int)($group['allowRepeats']??0),
                !empty($group['catalogId']) ? (int)$group['catalogId'] : null,
                $groupIndex
            ]);
        } else {
            // Compatibilidad con bases anteriores a la migración de catálogos.
            // Los paquetes siguen pudiendo guardar productos enlazados mediante
            // product_options.linked_product_id sin necesitar catalog_id.
            $stmt = $db->prepare(
                'INSERT INTO product_option_groups
                 (product_id,name,multiple,required_flag,min_selections,max_selections,allow_repeats,sort_order)
                 VALUES (?,?,?,?,?,?,?,?)'
            );
            $stmt->execute([
                $productId,$name,(int)($group['multiple']??0),(int)($group['required']??0),
                (int)($group['minSelections']??0),
                array_key_exists('maxSelections',$group) && $group['maxSelections'] !== null ? (int)$group['maxSelections'] : null,
                (int)($group['allowRepeats']??0),
                $groupIndex
            ]);
        }
        $groupId = (int)$db->lastInsertId();
        foreach (($group['options'] ?? []) as $optionIndex => $option) {
            $label = is_array($option) ? trim((string)($option['label'] ?? '')) : trim((string)$option);
            if ($label === '') continue;
            $extraPrice = is_array($option) ? (float)($option['extraPrice'] ?? 0) : 0;
            $complementId = is_array($option) && !empty($option['complementId']) ? (int)$option['complementId'] : null;
            $linkedProductId = is_array($option) && !empty($option['linkedProductId']) ? (int)$option['linkedProductId'] : null;
            $defaultQuantity = is_array($option) ? max(1,(int)($option['defaultQuantity']??1)) : 1;
            $db->prepare(
                'INSERT INTO product_options
                 (group_id,label,complement_id,linked_product_id,default_quantity,extra_price,sort_order)
                 VALUES (?,?,?,?,?,?,?)'
            )->execute([$groupId,$label,$complementId,$linkedProductId,$defaultQuantity,$extraPrice,$optionIndex]);
        }
    }
}

// Salud y autenticación.
$router->add('GET', '/health', static fn(): array => [
    'body' => ['ok' => true, 'service' => 'Komanda API multi-restaurante', 'time' => date(DATE_ATOM)],
], false);

$router->add('POST', '/auth/login', function (PDO $db, array $config): array {
    $body = Http::body();
    Http::requireFields($body, ['username', 'password']);

    $stmt = $db->prepare(
        'SELECT u.*, r.name AS restaurant_name, r.slug AS restaurant_slug
         FROM users u
         JOIN restaurants r ON r.id = u.restaurant_id
         WHERE u.username = ? AND u.active = 1 AND r.active = 1
         LIMIT 1'
    );
    $stmt->execute([trim((string)$body['username'])]);
    $user = $stmt->fetch();

    if (!$user || !password_verify((string)$body['password'], $user['password_hash'])) {
        return ['status' => 401, 'body' => ['ok' => false, 'message' => 'Usuario o contraseña incorrectos']];
    }

    $token = Auth::issue($db, (int)$user['id'], (int)($config['app']['token_days'] ?? 30));
    return ['body' => [
        'ok' => true,
        'token' => $token,
        'user' => [
            'id' => (string)$user['id'],
            'restaurantId' => (string)$user['restaurant_id'],
            'restaurantName' => $user['restaurant_name'],
            'username' => $user['username'],
            'name' => $user['name'],
            'role' => $user['role'],
        ],
    ]];
}, false);

$router->add('POST', '/auth/logout', function (PDO $db): array {
    Auth::logout($db);
    return ['body' => ['ok' => true]];
});


$router->add('GET', '/auth/me', static fn(PDO $db, array $config, array $params, array $user): array => [
    'body' => ['ok' => true, 'user' => [
        'id' => (string)$user['id'],
        'restaurantId' => (string)$user['restaurant_id'],
        'restaurantName' => $user['restaurant_name'],
        'username' => $user['username'],
        'name' => $user['name'],
        'role' => $user['role'],
    ]],
]);

$router->add('PUT', '/auth/me', function (PDO $db, array $config, array $params, array $user): array {
    $body = Http::body();
    Http::requireFields($body, ['name', 'username']);

    $name = trim((string)$body['name']);
    $username = trim((string)$body['username']);

    if ($name === '' || $username === '') {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Nombre y usuario son obligatorios']];
    }

    $duplicate = $db->prepare('SELECT id FROM users WHERE username = ? AND id <> ? LIMIT 1');
    $duplicate->execute([$username, $user['id']]);
    if ($duplicate->fetch()) {
        return ['status' => 409, 'body' => ['ok' => false, 'message' => 'Ese nombre de usuario ya está registrado']];
    }

    $fields = ['name = ?', 'username = ?'];
    $args = [$name, $username];

    $newPassword = (string)($body['newPassword'] ?? '');
    if ($newPassword !== '') {
        $currentPassword = (string)($body['currentPassword'] ?? '');
        if ($currentPassword === '') {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Captura tu contraseña actual']];
        }
        if (strlen($newPassword) < 6) {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'La nueva contraseña debe tener al menos 6 caracteres']];
        }

        $stmt = $db->prepare('SELECT password_hash FROM users WHERE id = ? AND restaurant_id = ? LIMIT 1');
        $stmt->execute([$user['id'], restaurantId($user)]);
        $row = $stmt->fetch();

        if (!$row || !password_verify($currentPassword, (string)$row['password_hash'])) {
            return ['status' => 401, 'body' => ['ok' => false, 'message' => 'La contraseña actual es incorrecta']];
        }

        $fields[] = 'password_hash = ?';
        $args[] = password_hash($newPassword, PASSWORD_DEFAULT);
    }

    $args[] = $user['id'];
    $args[] = restaurantId($user);

    $stmt = $db->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ? AND restaurant_id = ?');
    $stmt->execute($args);

    $stmt = $db->prepare(
        'SELECT u.id, u.restaurant_id, u.username, u.name, u.role, r.name AS restaurant_name
         FROM users u
         JOIN restaurants r ON r.id = u.restaurant_id
         WHERE u.id = ? AND u.restaurant_id = ?
         LIMIT 1'
    );
    $stmt->execute([$user['id'], restaurantId($user)]);
    $updated = $stmt->fetch();

    return ['body' => ['ok' => true, 'user' => [
        'id' => (string)$updated['id'],
        'restaurantId' => (string)$updated['restaurant_id'],
        'restaurantName' => $updated['restaurant_name'],
        'username' => $updated['username'],
        'name' => $updated['name'],
        'role' => $updated['role'],
    ]]];
});

// Restaurante actual.
$router->add('GET', '/restaurant', function (PDO $db, array $config, array $params, array $user): array {
    $stmt = $db->prepare('SELECT id, name, slug, active, created_at FROM restaurants WHERE id = ?');
    $stmt->execute([restaurantId($user)]);
    return ['body' => ['ok' => true, 'data' => $stmt->fetch()]];
});

$router->add('PUT', '/restaurant', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name']);
    $db->prepare('UPDATE restaurants SET name = ? WHERE id = ?')
        ->execute([trim((string)$body['name']), restaurantId($user)]);
    return ['body' => ['ok' => true]];
});

// Usuarios: todos pertenecen al restaurante del usuario autenticado.
$router->add('GET', '/users', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $stmt = $db->prepare(
        'SELECT id, username, name, role, active, created_at
         FROM users
         WHERE restaurant_id = ?
         ORDER BY name'
    );
    $stmt->execute([restaurantId($user)]);
    return ['body' => ['ok' => true, 'data' => $stmt->fetchAll()]];
});

$router->add('POST', '/users', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['username', 'name', 'password']);

    $restaurantId = restaurantId($user);
    $username = trim((string)$body['username']);
    $name = trim((string)$body['name']);
    $role = trim((string)($body['role'] ?? 'order_taker'));
    $allowedRoles = ['admin', 'order_taker', 'chef'];
    if (!in_array($role, $allowedRoles, true)) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Perfil inválido']];
    }
    $active = (int)($body['active'] ?? 1);

    if (strlen((string)$body['password']) < 6) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'La contraseña debe tener al menos 6 caracteres']];
    }

    $db->beginTransaction();
    try {
        $stmt = $db->prepare(
            'INSERT INTO users(restaurant_id, username, name, password_hash, role, active)
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $restaurantId,
            $username,
            $name,
            password_hash((string)$body['password'], PASSWORD_DEFAULT),
            $role,
            $active,
        ]);

        $userId = (int)$db->lastInsertId();
        $waiterId = null;

        if ($role === 'waiter') {
            $waiterStmt = $db->prepare(
                'INSERT INTO waiters(restaurant_id, user_id, name, active)
                 VALUES (?, ?, ?, ?)'
            );
            $waiterStmt->execute([$restaurantId, $userId, $name, $active]);
            $waiterId = (string)$db->lastInsertId();
        }

        $db->commit();
        return [
            'status' => 201,
            'body' => [
                'ok' => true,
                'id' => (string)$userId,
                'waiterId' => $waiterId,
            ],
        ];
    } catch (Throwable $error) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        throw $error;
    }
});

$router->add('PUT', '/users/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name']);

    $updatedRole = trim((string)($body['role'] ?? 'order_taker'));
    $allowedRoles = ['admin', 'order_taker', 'chef'];
    if (!in_array($updatedRole, $allowedRoles, true)) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Perfil inválido']];
    }

    $fields = ['name = ?', 'role = ?', 'active = ?'];
    $args = [trim((string)$body['name']), $updatedRole, (int)($body['active'] ?? 1)];
    if (!empty($body['password'])) {
        $fields[] = 'password_hash = ?';
        $args[] = password_hash((string)$body['password'], PASSWORD_DEFAULT);
    }
    $args[] = $params['id'];
    $args[] = restaurantId($user);

    $stmt = $db->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ? AND restaurant_id = ?');
    $stmt->execute($args);

        $updatedName = trim((string)$body['name']);
    $updatedActive = (int)($body['active'] ?? 1);
    $restaurantId = restaurantId($user);
    $userId = (int)$params['id'];

    if ($updatedRole === 'waiter') {
        $waiterCheck = $db->prepare('SELECT id FROM waiters WHERE user_id = ? AND restaurant_id = ? LIMIT 1');
        $waiterCheck->execute([$userId, $restaurantId]);
        $waiterId = $waiterCheck->fetchColumn();
        if ($waiterId) {
            $db->prepare('UPDATE waiters SET name = ?, active = ? WHERE id = ? AND restaurant_id = ?')
                ->execute([$updatedName, $updatedActive, $waiterId, $restaurantId]);
        } else {
            $db->prepare('INSERT INTO waiters(restaurant_id, user_id, name, active) VALUES (?, ?, ?, ?)')
                ->execute([$restaurantId, $userId, $updatedName, $updatedActive]);
        }
    } else {
        $db->prepare('UPDATE waiters SET active = 0 WHERE user_id = ? AND restaurant_id = ?')
            ->execute([$userId, $restaurantId]);
    }

    return ['body' => ['ok' => true]];
});

// Productos CRUD.
$router->add('GET', '/products', function (PDO $db, array $config, array $params, array $user): array {
    $where = ['restaurant_id = ?'];
    $args = [restaurantId($user)];

    $search = trim((string)Http::query('search', ''));
    if ($search !== '') {
        $where[] = '(name LIKE ? OR category LIKE ? OR description LIKE ?)';
        $query = "%{$search}%";
        array_push($args, $query, $query, $query);
    }
    if (Http::query('available') !== null) {
        $where[] = 'available = ?';
        $args[] = (int)Http::query('available');
    }

    $stmt = $db->prepare('SELECT * FROM products WHERE ' . implode(' AND ', $where) . ' ORDER BY category, name');
    $stmt->execute($args);
    return ['body' => ['ok' => true, 'data' => array_map(
        static fn(array $product): array => productPayload($db, $product),
        $stmt->fetchAll()
    )]];
});

$router->add('GET', '/products/{id}', function (PDO $db, array $config, array $params, array $user): array {
    $stmt = $db->prepare('SELECT * FROM products WHERE id = ? AND restaurant_id = ?');
    $stmt->execute([$params['id'], restaurantId($user)]);
    $product = $stmt->fetch();
    return $product
        ? ['body' => ['ok' => true, 'data' => productPayload($db, $product)]]
        : ['status' => 404, 'body' => ['ok' => false, 'message' => 'Producto no encontrado']];
});

$router->add('POST', '/products', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name', 'category', 'price']);

    $db->beginTransaction();
    try {
        $stmt = $db->prepare(
            'INSERT INTO products(restaurant_id,name,category,price,available,description,image_url,product_kind,pricing_mode)
             VALUES (?,?,?,?,?,?,?,?,?)'
        );
        $stmt->execute([
            restaurantId($user),
            trim((string)$body['name']),
            trim((string)$body['category']),
            (float)$body['price'],
            (int)($body['available'] ?? 1),
            $body['description'] ?? '',
            $body['imageUrl'] ?? '',
            $body['productKind'] ?? 'simple',
            $body['pricingMode'] ?? 'fixed',
        ]);
        $id = (int)$db->lastInsertId();
        saveGroups($db, $id, $body['optionGroups'] ?? []);
        $db->commit();
        if (isset($folioLock)) { try { $unlock = $db->prepare('SELECT RELEASE_LOCK(?)'); $unlock->execute([$folioLock]); } catch (Throwable $ignored) {} }
        return ['status' => 201, 'body' => ['ok' => true, 'id' => (string)$id]];
    } catch (Throwable $error) {
        $db->rollBack();
        throw $error;
    }
});

$router->add('PUT', '/products/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name', 'category', 'price']);

    $db->beginTransaction();
    try {
        $stmt = $db->prepare(
            'UPDATE products
             SET name=?, category=?, price=?, available=?, description=?, image_url=?, product_kind=?, pricing_mode=?
             WHERE id=? AND restaurant_id=?'
        );
        $stmt->execute([
            trim((string)$body['name']),
            trim((string)$body['category']),
            (float)$body['price'],
            (int)($body['available'] ?? 1),
            $body['description'] ?? '',
            $body['imageUrl'] ?? '',
            $body['productKind'] ?? 'simple',
            $body['pricingMode'] ?? 'fixed',
            $params['id'],
            restaurantId($user),
        ]);
        // MySQL puede devolver rowCount() = 0 cuando el registro existe pero
        // los campos escalares no cambiaron. Eso es normal al editar solamente
        // la composición/opciones de un paquete. Verificamos existencia aparte.
        $existsStmt = $db->prepare(
            'SELECT id FROM products WHERE id = ? AND restaurant_id = ? LIMIT 1'
        );
        $existsStmt->execute([$params['id'], restaurantId($user)]);
        if (!$existsStmt->fetchColumn()) {
            throw new RuntimeException('Producto no encontrado en este restaurante');
        }
        $db->prepare(
            'DELETE po FROM product_options po
             INNER JOIN product_option_groups g ON g.id = po.group_id
             WHERE g.product_id = ?'
        )->execute([$params['id']]);
        $db->prepare('DELETE FROM product_option_groups WHERE product_id = ?')->execute([$params['id']]);
        saveGroups($db, (int)$params['id'], $body['optionGroups'] ?? []);
        $db->commit();
        return ['body' => ['ok' => true]];
    } catch (Throwable $error) {
        $db->rollBack();
        throw $error;
    }
});

$router->add('DELETE', '/products/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $stmt = $db->prepare('DELETE FROM products WHERE id = ? AND restaurant_id = ?');
    $stmt->execute([$params['id'], restaurantId($user)]);
    return ['body' => ['ok' => true]];
});

// Meseros: users con role=waiter es la fuente de verdad.
// Al consultar, se vinculan automáticamente usuarios waiter antiguos que todavía
// no tengan su registro operativo en la tabla waiters.
$router->add('GET', '/waiters', function (PDO $db, array $config, array $params, array $user): array {
    $restaurantId = restaurantId($user);

    // Reconciliación segura para usuarios waiter creados antes de existir user_id
    // en la tabla waiters o creados desde el módulo general de usuarios.
    $sync = $db->prepare(
        "INSERT INTO waiters (restaurant_id, user_id, name, active)
         SELECT u.restaurant_id, u.id, u.name, u.active
         FROM users u
         WHERE u.restaurant_id = ?
           AND u.role = 'waiter'
           AND NOT EXISTS (
               SELECT 1
               FROM waiters w
               WHERE w.restaurant_id = u.restaurant_id
                 AND w.user_id = u.id
           )"
    );
    $sync->execute([$restaurantId]);

    // La lista nace desde users para garantizar que TODO usuario tipo waiter
    // aparezca en Administración de meseros.
    $stmt = $db->prepare(
        "SELECT
            w.id,
            u.id AS user_id,
            u.name,
            u.username,
            u.role,
            u.active,
            u.created_at,
            1 AS linked
         FROM users u
         INNER JOIN waiters w
           ON w.user_id = u.id
          AND w.restaurant_id = u.restaurant_id
         WHERE u.restaurant_id = ?
           AND u.role = 'waiter'
         ORDER BY u.name, u.username"
    );
    $stmt->execute([$restaurantId]);

    return ['body' => ['ok' => true, 'data' => $stmt->fetchAll()]];
});

$router->add('POST', '/waiters', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name', 'username', 'password']);

    $restaurantId = restaurantId($user);
    $name = trim((string)$body['name']);
    $username = trim((string)$body['username']);
    $password = (string)$body['password'];
    $active = (int)($body['active'] ?? 1);

    if (strlen($password) < 6) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'La contraseña debe tener al menos 6 caracteres']];
    }

    $db->beginTransaction();
    try {
        $userStmt = $db->prepare(
            "INSERT INTO users(restaurant_id, username, name, password_hash, role, active)
             VALUES (?, ?, ?, ?, 'waiter', ?)"
        );
        $userStmt->execute([
            $restaurantId,
            $username,
            $name,
            password_hash($password, PASSWORD_DEFAULT),
            $active,
        ]);
        $userId = (int)$db->lastInsertId();

        $waiterStmt = $db->prepare(
            'INSERT INTO waiters(restaurant_id, user_id, name, active)
             VALUES (?, ?, ?, ?)'
        );
        $waiterStmt->execute([$restaurantId, $userId, $name, $active]);
        $waiterId = (int)$db->lastInsertId();

        $db->commit();
        return [
            'status' => 201,
            'body' => [
                'ok' => true,
                'id' => (string)$waiterId,
                'userId' => (string)$userId,
            ],
        ];
    } catch (Throwable $error) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        throw $error;
    }
});

$router->add('PUT', '/waiters/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['name', 'username']);

    $restaurantId = restaurantId($user);
    $waiterId = (int)$params['id'];
    $name = trim((string)$body['name']);
    $username = trim((string)$body['username']);
    $active = (int)($body['active'] ?? 1);

    $find = $db->prepare('SELECT user_id FROM waiters WHERE id = ? AND restaurant_id = ? LIMIT 1');
    $find->execute([$waiterId, $restaurantId]);
    $waiter = $find->fetch();
    if (!$waiter) {
        return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Mesero no encontrado']];
    }

    $db->beginTransaction();
    try {
        $db->prepare('UPDATE waiters SET name = ?, active = ? WHERE id = ? AND restaurant_id = ?')
            ->execute([$name, $active, $waiterId, $restaurantId]);

        $fields = ['name = ?', 'username = ?', "role = 'waiter'", 'active = ?'];
        $args = [$name, $username, $active];
        if (!empty($body['password'])) {
            if (strlen((string)$body['password']) < 6) {
                throw new RuntimeException('La contraseña debe tener al menos 6 caracteres');
            }
            $fields[] = 'password_hash = ?';
            $args[] = password_hash((string)$body['password'], PASSWORD_DEFAULT);
        }
        $args[] = $waiter['user_id'];
        $args[] = $restaurantId;

        $db->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ? AND restaurant_id = ?')
            ->execute($args);

        $db->commit();
        return ['body' => ['ok' => true]];
    } catch (Throwable $error) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        throw $error;
    }
});

$router->add('DELETE', '/waiters/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $restaurantId = restaurantId($user);

    $find = $db->prepare('SELECT user_id FROM waiters WHERE id = ? AND restaurant_id = ? LIMIT 1');
    $find->execute([$params['id'], $restaurantId]);
    $waiter = $find->fetch();
    if (!$waiter) {
        return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Mesero no encontrado']];
    }

    $db->beginTransaction();
    try {
        // Se desactiva en vez de borrar para conservar pedidos históricos.
        $db->prepare('UPDATE waiters SET active = 0 WHERE id = ? AND restaurant_id = ?')
            ->execute([$params['id'], $restaurantId]);
        if (!empty($waiter['user_id'])) {
            $db->prepare('UPDATE users SET active = 0 WHERE id = ? AND restaurant_id = ?')
                ->execute([$waiter['user_id'], $restaurantId]);
        }
        $db->commit();
        return ['body' => ['ok' => true]];
    } catch (Throwable $error) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        throw $error;
    }
});

// Pedidos.
$router->add('GET', '/orders', function (PDO $db, array $config, array $params, array $user): array {
    $where = ['orders.restaurant_id = ?'];
    $args = [restaurantId($user)];

    foreach (['status' => 'status', 'paid' => 'is_paid', 'takeaway' => 'is_takeaway', 'urgent' => 'is_urgent'] as $query => $column) {
        if (Http::query($query) !== null) {
            $where[] = "{$column} = ?";
            $args[] = Http::query($query);
        }
    }

    $table = trim((string)Http::query('table', ''));
    if ($table !== '') {
        $where[] = 'FIND_IN_SET(?, REPLACE(table_name, ", ", ",")) > 0';
        $args[] = $table;
    }

    $search = trim((string)Http::query('search', ''));
    if ($search !== '') {
        $where[] = '(folio LIKE ? OR table_name LIKE ? OR waiter_name LIKE ? OR EXISTS(
            SELECT 1 FROM order_items oi WHERE oi.order_id = orders.id AND oi.product_name LIKE ?
        ))';
        $query = "%{$search}%";
        array_push($args, $query, $query, $query, $query);
    }

    $stmt = $db->prepare('SELECT * FROM orders WHERE ' . implode(' AND ', $where) . ' ORDER BY created_at DESC');
    $stmt->execute($args);
    return ['body' => ['ok' => true, 'data' => array_map(
        static fn(array $order): array => orderPayload($db, $order),
        $stmt->fetchAll()
    )]];
});

// Ticket manual: operación atómica por restaurante, con folio diario y cobro.
$router->add('POST', '/orders/manual-ticket', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin', 'waiter', 'order_taker']);
    $body = Http::body();
    $amount = round((float)($body['amount'] ?? 0), 2);
    $received = round((float)($body['amountReceived'] ?? 0), 2);
    $method = strtolower(trim((string)($body['paymentMethod'] ?? 'cash')));
    if (!is_finite($amount) || !is_finite($received) || $amount <= 0 || $amount > 1000000 || !in_array($method, ['cash','card','transfer'], true)) {
        return ['status'=>422,'body'=>['ok'=>false,'message'=>'Importe o método de pago inválido']];
    }
    if ($method === 'cash' && $received < $amount) {
        return ['status'=>422,'body'=>['ok'=>false,'message'=>'El recibido es menor al importe']];
    }
    if ($method !== 'cash') $received = $amount;
    $rid = restaurantId($user);
    $lockName = 'restaurant_folio_' . $rid;
    $lock = $db->prepare('SELECT GET_LOCK(?, 5)');
    $lock->execute([$lockName]);
    if ((int)$lock->fetchColumn() !== 1) {
        return ['status'=>503,'body'=>['ok'=>false,'message'=>'No se pudo reservar el folio']];
    }
    try {
        $db->beginTransaction();
        $next = $db->prepare("SELECT COALESCE(MAX(CASE WHEN folio REGEXP '^[0-9]+$' THEN CAST(folio AS UNSIGNED) ELSE 0 END),0)+1 FROM orders WHERE restaurant_id=? AND folio_date=CURDATE()");
        $next->execute([$rid]);
        $folio = (string)(int)$next->fetchColumn();
        $id = Http::uuid();
        $change = max(0, round($received-$amount, 2));
        $stmt = $db->prepare("INSERT INTO orders (id,restaurant_id,created_by_user_id,folio,folio_date,table_name,is_takeaway,is_urgent,status,notes,subtotal,total_amount,order_type,customer_name,kitchen_name,customer_phone,delivery_address,delivery_fee,paid_amount,is_paid,payment_method,amount_received,change_amount,paid_at) VALUES (?,?,?,?,CURDATE(),'',1,0,'completed','Ticket manual',?,?,'TAKEAWAY','','','','',0,?,1,?,?,?,NOW())");
        $stmt->execute([$id,$rid,(int)$user['id'],$folio,$amount,$amount,$amount,$method,$received,$change]);
        $item = $db->prepare('INSERT INTO order_items(order_id,product_id,product_name,quantity,unit_price,line_total) VALUES (?,NULL,?,1,?,?)');
        $item->execute([$id,'Ticket manual',$amount,$amount]);
        $db->commit();
        $get=$db->prepare('SELECT * FROM orders WHERE id=? AND restaurant_id=?');
        $get->execute([$id,$rid]);
        return ['status'=>201,'body'=>['ok'=>true,'data'=>orderPayload($db,$get->fetch())]];
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    } finally {
        $unlock=$db->prepare('SELECT RELEASE_LOCK(?)');
        $unlock->execute([$lockName]);
    }
});

$router->add('GET', '/orders/{id}', function (PDO $db, array $config, array $params, array $user): array {
    $stmt = $db->prepare('SELECT * FROM orders WHERE id = ? AND restaurant_id = ?');
    $stmt->execute([$params['id'], restaurantId($user)]);
    $order = $stmt->fetch();
    return $order
        ? ['body' => ['ok' => true, 'data' => orderPayload($db, $order)]]
        : ['status' => 404, 'body' => ['ok' => false, 'message' => 'Pedido no encontrado']];
});

/**
 * Normaliza especificaciones opcionales: sin complementos es una lista vacía.
 * Conserva las etiquetas de plato y evita insertar valores vacíos o no escalares.
 */
function normalizedOrderSpecifications($raw): array {
    if ($raw === null || $raw === '') return [];
    if (!is_array($raw)) return [];
    $result = [];
    foreach ($raw as $value) {
        if (!is_string($value) && !is_numeric($value)) continue;
        $spec = trim((string)$value);
        if ($spec === '' || in_array($spec, $result, true)) continue;
        $result[] = $spec;
    }
    return $result;
}

$router->add('POST', '/orders', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin', 'order_taker', 'waiter']);
    $body = Http::body();
    Http::requireFields($body, ['items']);
    if (!is_array($body['items']) || count($body['items']) === 0) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El pedido requiere productos']];
    }

    $restaurantId = restaurantId($user);
    $id = !empty($body['id']) ? (string)$body['id'] : Http::uuid();
    $folio = !empty($body['folio']) ? trim((string)$body['folio']) : '';

    // Folio diario por restaurante: 1, 2, 3... y al cambiar de fecha vuelve a 1.
    // GET_LOCK evita que dos dispositivos reciban el mismo folio al crear a la vez.
    $folioLock = 'restaurant_folio_' . $restaurantId;
    $db->beginTransaction();
    try {
        if ($folio === '') {
            $lockStmt = $db->prepare('SELECT GET_LOCK(?, 5)');
            $lockStmt->execute([$folioLock]);
            if ((int)$lockStmt->fetchColumn() !== 1) {
                throw new RuntimeException('No fue posible reservar el siguiente número de ticket.');
            }
            $folioStmt = $db->prepare("SELECT COALESCE(MAX(CASE WHEN folio REGEXP '^[0-9]+$' THEN CAST(folio AS UNSIGNED) ELSE 0 END), 0) + 1 FROM orders WHERE restaurant_id = ? AND folio_date = CURDATE()");
            $folioStmt->execute([$restaurantId]);
            $folio = (string)((int)$folioStmt->fetchColumn());
        }
        $subtotal = 0.0;
        foreach ($body['items'] as $item) {
            $subtotal += (int)$item['quantity'] * (float)$item['unitPrice'];
        }

        $stmt = $db->prepare(
            'INSERT INTO orders(
                id, restaurant_id, created_by_user_id, folio, folio_date, table_name,
                is_takeaway, is_urgent, status, notes, subtotal, total_amount,
                order_type, customer_name, kitchen_name, customer_phone, delivery_address, delivery_fee, paid_amount
             ) VALUES (?, ?, ?, ?, CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $id,
            $restaurantId,
            (int)$user['id'],
            $folio,
            $body['table'] ?? '',
            (int)($body['isTakeaway'] ?? 0),
            (int)($body['isUrgent'] ?? 0),
            $body['status'] ?? 'pending',
            $body['notes'] ?? '',
            $subtotal,
            $subtotal + max(0, (float)($body['deliveryFee'] ?? 0)),
            $body['orderType'] ?? ((int)($body['isTakeaway'] ?? 0) === 1 ? 'TAKEAWAY' : 'DINE_IN'),
            trim((string)($body['customerName'] ?? '')),
            trim((string)($body['kitchenName'] ?? '')),
            trim((string)($body['customerPhone'] ?? '')),
            trim((string)($body['deliveryAddress'] ?? '')),
            max(0, (float)($body['deliveryFee'] ?? 0)),
            0,
        ]);

        foreach ($body['items'] as $item) {
            $productId = !empty($item['productId']) ? $item['productId'] : null;
            if ($productId !== null) {
                $productCheck = $db->prepare('SELECT id FROM products WHERE id = ? AND restaurant_id = ?');
                $productCheck->execute([$productId, $restaurantId]);
                if (!$productCheck->fetch()) $productId = null;
            }

            $lineTotal = (int)$item['quantity'] * (float)$item['unitPrice'];
            $itemStmt = $db->prepare(
                'INSERT INTO order_items(order_id, product_id, product_name, quantity, unit_price, line_total)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $itemStmt->execute([
                $id,
                $productId,
                $item['name'],
                (int)$item['quantity'],
                (float)$item['unitPrice'],
                $lineTotal,
            ]);
            $itemId = (int)$db->lastInsertId();

            foreach (normalizedOrderSpecifications($item['specifications'] ?? []) as $specification) {
                $db->prepare(
                    'INSERT INTO order_item_specifications(order_item_id, specification) VALUES (?, ?)'
                )->execute([$itemId, $specification]);
            }
        }

        $db->commit();
        try { $unlock = $db->prepare('SELECT RELEASE_LOCK(?)'); $unlock->execute([$folioLock]); } catch (Throwable $ignored) {}
        $query = $db->prepare('SELECT * FROM orders WHERE id = ? AND restaurant_id = ?');
        $query->execute([$id, $restaurantId]);
        return ['status' => 201, 'body' => ['ok' => true, 'data' => orderPayload($db, $query->fetch())]];
    } catch (Throwable $error) {
        if ($db->inTransaction()) $db->rollBack();
        try { $unlock = $db->prepare('SELECT RELEASE_LOCK(?)'); $unlock->execute([$folioLock]); } catch (Throwable $ignored) {}
        throw $error;
    }
});


$updateOrderHandler = function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    Http::requireFields($body, ['items']);
    if (!is_array($body['items']) || count($body['items']) === 0) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El pedido requiere al menos un producto']];
    }
    $restaurantId = restaurantId($user);
    $check = $db->prepare('SELECT * FROM orders WHERE id = ? AND restaurant_id = ?');
    $check->execute([$params['id'], $restaurantId]);
    $currentOrder = $check->fetch();
    if (!$currentOrder) return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Pedido no encontrado']];

    $subtotal = 0.0;
    foreach ($body['items'] as $item) $subtotal += max(1, (int)($item['quantity'] ?? 1)) * max(0, (float)($item['unitPrice'] ?? 0));

    $db->beginTransaction();
    try {
        $deliveryFee = (($body['orderType'] ?? 'DINE_IN') === 'DELIVERY') ? max(0,(float)($body['deliveryFee'] ?? 0)) : 0.0;
        $newTotal = $subtotal + $deliveryFee + max(0,(float)($currentOrder['tip_amount'] ?? 0));
        $paidAmount = max(0,(float)($currentOrder['paid_amount'] ?? 0));
        $isPaid = $paidAmount + 0.009 >= $newTotal ? 1 : 0;
        $db->prepare('UPDATE orders SET table_name=?, is_takeaway=?, is_urgent=?, notes=?, subtotal=?, total_amount=?, order_type=?, customer_name=?, kitchen_name=?, customer_phone=?, delivery_address=?, delivery_fee=?, is_paid=? WHERE id=? AND restaurant_id=?')
            ->execute([
                $body['table'] ?? '', (int)($body['isTakeaway'] ?? 0), (int)($body['isUrgent'] ?? 0), $body['notes'] ?? '',
                $subtotal, $newTotal,
                $body['orderType'] ?? 'DINE_IN', trim((string)($body['customerName'] ?? '')), trim((string)($body['kitchenName'] ?? ($currentOrder['kitchen_name'] ?? ''))), trim((string)($body['customerPhone'] ?? '')), trim((string)($body['deliveryAddress'] ?? '')),
                $deliveryFee, $isPaid,
                $params['id'], $restaurantId
            ]);
        $ids = $db->prepare('SELECT id FROM order_items WHERE order_id=?'); $ids->execute([$params['id']]);
        foreach ($ids->fetchAll(PDO::FETCH_COLUMN) as $itemId) $db->prepare('DELETE FROM order_item_specifications WHERE order_item_id=?')->execute([$itemId]);
        $db->prepare('DELETE FROM order_items WHERE order_id=?')->execute([$params['id']]);
        foreach ($body['items'] as $item) {
            $qty=max(1,(int)($item['quantity']??1)); $price=max(0,(float)($item['unitPrice']??0)); $line=$qty*$price;
            $productId=!empty($item['productId'])?$item['productId']:null;
            $st=$db->prepare('INSERT INTO order_items(order_id,product_id,product_name,quantity,unit_price,line_total) VALUES(?,?,?,?,?,?)');
            $st->execute([$params['id'],$productId,trim((string)($item['name']??'Producto')),$qty,$price,$line]);
            $itemId=(int)$db->lastInsertId();
            foreach (normalizedOrderSpecifications($item['specifications'] ?? []) as $spec) $db->prepare('INSERT INTO order_item_specifications(order_item_id,specification) VALUES(?,?)')->execute([$itemId,$spec]);
        }
        $db->commit();
        $q=$db->prepare('SELECT * FROM orders WHERE id=? AND restaurant_id=?'); $q->execute([$params['id'],$restaurantId]);
        return ['body'=>['ok'=>true,'data'=>orderPayload($db,$q->fetch())]];
    } catch (Throwable $e) { $db->rollBack(); throw $e; }
};
$router->add('PUT', '/orders/{id}', $updateOrderHandler);
$router->add('PATCH', '/orders/{id}', $updateOrderHandler);

$router->add('PATCH', '/orders/{id}/status', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin', 'chef', 'waiter', 'order_taker', 'cashier']);
    $body = Http::body();
    Http::requireFields($body, ['status']);
    $allowed = ['pending', 'preparing', 'waiting', 'delivering', 'atTable', 'completed', 'cancelled'];
    if (!in_array($body['status'], $allowed, true)) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Estado inválido']];
    }

    $stmt = $db->prepare('SELECT * FROM orders WHERE id = ? AND restaurant_id = ?');
    $stmt->execute([$params['id'], restaurantId($user)]);
    $order = $stmt->fetch();
    if (!$order) return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Pedido no encontrado']];
    if ($body['status'] === 'cancelled' && ((int)$order['is_paid'] === 1 || (float)($order['paid_amount'] ?? 0) > 0)) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Un pedido con pagos registrados requiere devolución antes de cancelar']];
    }

    // No se puede entregar un pedido que todavía no está cobrado.
    if ($body['status'] === 'atTable' && !(bool)$order['is_paid']) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El pedido no se ha cobrado. Favor de cobrar antes de entregarlo.']];
    }
    // Al liberar una mesa pagada se registran las etapas omitidas en una sola
    // actualización, sin necesitar múltiples peticiones ni alterar los pagos.
    if ($body['status'] === 'completed' && !empty($order['table_name']) && !(bool)$order['is_takeaway']) {
        if (!(bool)$order['is_paid']) {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Primero cobra el pedido antes de liberar la mesa.']];
        }
        if (in_array($order['status'], ['completed', 'cancelled'], true)) {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El pedido ya fue finalizado o cancelado.']];
        }
        $db->prepare("UPDATE orders SET status = 'completed',
            preparing_at = COALESCE(preparing_at, NOW()),
            delivered_at = COALESCE(delivered_at, NOW()),
            released_at = COALESCE(released_at, NOW())
            WHERE id = ? AND restaurant_id = ? AND is_paid = 1
              AND status NOT IN ('completed','cancelled')")
            ->execute([$params['id'], restaurantId($user)]);
        return ['body' => ['ok' => true]];
    }
    $extra = '';
    if ($body['status'] === 'preparing') $extra = ', preparing_at = COALESCE(preparing_at, NOW())';
    if ($body['status'] === 'waiting') $extra = ', ready_at = NOW()';
    if ($body['status'] === 'atTable') $extra = ', delivered_at = NOW(), released_at = NULL';
    if (in_array($body['status'], ['completed', 'cancelled'], true)) $extra = ', released_at = COALESCE(released_at, NOW())';
    if (in_array($body['status'], ['pending', 'preparing', 'waiting', 'delivering'], true)) $extra .= ', released_at = NULL';

    $db->prepare("UPDATE orders SET status = ? {$extra} WHERE id = ? AND restaurant_id = ?")
        ->execute([$body['status'], $params['id'], restaurantId($user)]);
    return ['body' => ['ok' => true]];
});

$router->add('PATCH', '/orders/{id}/waiter', function (PDO $db, array $config, array $params, array $user): array {
    $body = Http::body();
    $restaurantId = restaurantId($user);
    $orderId = trim((string)($params['id'] ?? ''));

    // El frontend envía users.id. Se aceptan ambos nombres por compatibilidad.
    $waiterUserId = trim((string)($body['userId'] ?? $body['waiterId'] ?? ''));
    if ($waiterUserId === '') {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Selecciona un mesero válido']];
    }

    // Primero validar que el pedido exista; no usar rowCount() para esto.
    $orderCheck = $db->prepare('SELECT id FROM orders WHERE id = ? AND restaurant_id = ? LIMIT 1');
    $orderCheck->execute([$orderId, $restaurantId]);
    if (!$orderCheck->fetch()) {
        return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Pedido no encontrado', 'details' => ['orderId' => $orderId, 'restaurantId' => $restaurantId]]];
    }

    // Buscar el registro operativo del mesero a partir de waiters.user_id.
    $waiterStmt = $db->prepare(
        "SELECT w.id, w.user_id, w.name
         FROM waiters w
         INNER JOIN users u ON u.id = w.user_id AND u.restaurant_id = w.restaurant_id
         WHERE w.user_id = ?
           AND w.restaurant_id = ?
           AND w.active = 1
           AND u.active = 1
           AND u.role = 'waiter'
         LIMIT 1"
    );
    $waiterStmt->execute([$waiterUserId, $restaurantId]);
    $waiter = $waiterStmt->fetch();

    if (!$waiter) {
        return [
            'status' => 404,
            'body' => [
                'ok' => false,
                'message' => 'Usuario mesero no encontrado, inactivo o sin vínculo en waiters',
                'details' => ['userId' => $waiterUserId, 'restaurantId' => $restaurantId],
            ],
        ];
    }

    // En orders se conserva waiters.id porque es la relación operativa existente.
    $update = $db->prepare('UPDATE orders SET waiter_id = ?, waiter_name = ? WHERE id = ? AND restaurant_id = ?');
    $update->execute([$waiter['id'], $waiter['name'], $orderId, $restaurantId]);

    return [
        'body' => [
            'ok' => true,
            'message' => 'Mesero asignado correctamente',
            'data' => [
                'orderId' => $orderId,
                'waiterId' => (string)$waiter['id'],
                'userId' => (string)$waiter['user_id'],
                'waiterName' => (string)$waiter['name'],
            ],
        ],
    ];
});

$router->add('POST', '/orders/{id}/payment', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin', 'waiter', 'order_taker', 'cashier']);
    $body = Http::body();
    Http::requireFields($body, ['paymentMethod']);

    $stmt = $db->prepare('SELECT * FROM orders WHERE id = ? AND restaurant_id = ?');
    $stmt->execute([$params['id'], restaurantId($user)]);
    $order = $stmt->fetch();
    if (!$order) return ['status' => 404, 'body' => ['ok' => false, 'message' => 'Pedido no encontrado']];

    $tip = max(0, (float)($body['tipAmount'] ?? ($order['tip_amount'] ?? 0)));
    $tipMode = $body['tipMode'] ?? ($order['tip_mode'] ?? ($tip > 0 ? 'manual' : 'none'));
    $tipPercentage = max(0, (float)($body['tipPercentage'] ?? ($order['tip_percentage'] ?? 0)));
    $total = (float)$order['subtotal'] + max(0,(float)($order['delivery_fee'] ?? 0)) + $tip;
    $previousPaid = max(0,(float)($order['paid_amount'] ?? 0));
    $remaining = max(0, $total - $previousPaid);
    $apply = max(0, min($remaining, (float)($body['amountToApply'] ?? $remaining)));
    $received = (float)($body['amountReceived'] ?? $apply);

    if ($apply <= 0) {
        if ($remaining > 0.009) {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El importe a cobrar debe ser mayor a cero', 'remaining' => $remaining]];
        }
        return ['body' => ['ok' => true, 'total' => $total, 'change' => 0, 'paidAmount' => $previousPaid, 'remaining' => 0, 'isPaid' => true]];
    }
    if ($body['paymentMethod'] === 'cash' && $received < $apply) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El monto recibido es menor al saldo por cobrar']];
    }

    $change = max(0, $received - $apply);
    $newPaidAmount = min($total, $previousPaid + $apply);
    $isPaid = $newPaidAmount + 0.009 >= $total ? 1 : 0;
    $db->prepare(
        'UPDATE orders
         SET is_paid = ?, payment_method = ?, amount_received = amount_received + ?, change_amount = ?, paid_at = NOW(),
             paid_amount = ?, tip_amount = ?, tip_mode = ?, tip_percentage = ?, total_amount = ?
         WHERE id = ? AND restaurant_id = ?'
    )->execute([
        $isPaid, $body['paymentMethod'], $received, $change, $newPaidAmount, $tip, $tipMode, $tipPercentage,
        $total, $params['id'], restaurantId($user),
    ]);

    return ['body' => ['ok' => true, 'total' => $total, 'change' => $change, 'paidAmount' => $newPaidAmount, 'remaining' => max(0,$total-$newPaidAmount), 'isPaid' => (bool)$isPaid]];
});

// Llamados al mesero.
$router->add('GET', '/waiter-calls', function (PDO $db, array $config, array $params, array $user): array {
    $where = ['restaurant_id = ?'];
    $args = [restaurantId($user)];
    foreach (['status' => 'status', 'type' => 'type'] as $query => $column) {
        if (Http::query($query) !== null) {
            $where[] = "{$column} = ?";
            $args[] = Http::query($query);
        }
    }
    $stmt = $db->prepare('SELECT * FROM waiter_calls WHERE ' . implode(' AND ', $where) . ' ORDER BY created_at DESC');
    $stmt->execute($args);
    return ['body' => ['ok' => true, 'data' => $stmt->fetchAll()]];
});

$router->add('POST', '/waiter-calls', function (PDO $db, array $config, array $params, array $user): array {
    $body = Http::body();
    Http::requireFields($body, ['table', 'message', 'type']);
    $restaurantId = restaurantId($user);
    $id = !empty($body['id']) ? (string)$body['id'] : Http::uuid();

    if (!empty($body['orderId'])) {
        $orderCheck = $db->prepare('SELECT id FROM orders WHERE id = ? AND restaurant_id = ?');
        $orderCheck->execute([$body['orderId'], $restaurantId]);
        if (!$orderCheck->fetch()) {
            return ['status' => 422, 'body' => ['ok' => false, 'message' => 'El pedido no pertenece a este restaurante']];
        }
    }

    $waiterId = $body['waiterId'] ?? null;
    if ($waiterId !== null && $waiterId !== '') {
        $waiterCheck = $db->prepare('SELECT id FROM waiters WHERE id = ? AND restaurant_id = ?');
        $waiterCheck->execute([$waiterId, $restaurantId]);
        if (!$waiterCheck->fetch()) $waiterId = null;
    }

    $db->prepare(
        'INSERT INTO waiter_calls(
            id, restaurant_id, table_name, message, type, status, order_id, waiter_id, waiter_name
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        $id, $restaurantId, $body['table'], $body['message'], $body['type'], 'pending',
        $body['orderId'] ?? null, $waiterId, $body['waiterName'] ?? '',
    ]);

    return ['status' => 201, 'body' => ['ok' => true, 'id' => $id]];
});

$router->add('PATCH', '/waiter-calls/{id}/status', function (PDO $db, array $config, array $params, array $user): array {
    $body = Http::body();
    Http::requireFields($body, ['status']);
    $db->prepare(
        'UPDATE waiter_calls
         SET status = ?, attended_at = IF(? = "done", NOW(), NULL)
         WHERE id = ? AND restaurant_id = ?'
    )->execute([$body['status'], $body['status'], $params['id'], restaurantId($user)]);
    return ['body' => ['ok' => true]];
});

// Configuración del ticket por restaurante.
$router->add('GET', '/ticket-settings', function (PDO $db, array $config, array $params, array $user): array {
    $restaurantId = restaurantId($user);
    $db->prepare(
        'INSERT IGNORE INTO ticket_settings(restaurant_id, business_name)
         SELECT id, name FROM restaurants WHERE id = ?'
    )->execute([$restaurantId]);
    $stmt = $db->prepare('SELECT * FROM ticket_settings WHERE restaurant_id = ?');
    $stmt->execute([$restaurantId]);
    $settings = $stmt->fetch();
    if (is_array($settings)) {
        $settings['plateLabel'] = $settings['plate_label'] ?? 'Plato';
        $settings['logoBase64'] = '';
        if (!empty($settings['logo_url'])) {
            $logoName = basename((string) parse_url((string)$settings['logo_url'], PHP_URL_PATH));
            $logoPath = __DIR__ . '/uploads/logos/' . $logoName;
            if (is_file($logoPath) && filesize($logoPath) <= 2097152) {
                $logoBytes = file_get_contents($logoPath);
                if ($logoBytes !== false) $settings['logoBase64'] = base64_encode($logoBytes);
            }
        }
    }
    return ['body' => ['ok' => true, 'data' => $settings]];
});

$router->add('PUT', '/ticket-settings', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body();
    $restaurantId = restaurantId($user);

    $stmt = $db->prepare(
        'INSERT INTO ticket_settings(
            restaurant_id, business_name, address, phone, footer,
            show_folio, show_waiter, show_table, show_date, show_item_specifications, show_tip, font_scale, font_weight, plate_label
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            business_name = VALUES(business_name), address = VALUES(address), phone = VALUES(phone),
            footer = VALUES(footer), show_folio = VALUES(show_folio), show_waiter = VALUES(show_waiter),
            show_table = VALUES(show_table), show_date = VALUES(show_date),
            show_item_specifications = VALUES(show_item_specifications), show_tip = VALUES(show_tip),
            font_scale = VALUES(font_scale), font_weight = VALUES(font_weight),
            plate_label = VALUES(plate_label)'
    );
    $stmt->execute([
        $restaurantId,
        $body['businessName'] ?? $user['restaurant_name'] ?? 'Mi restaurante',
        $body['address'] ?? '',
        $body['phone'] ?? '',
        $body['footer'] ?? 'Gracias por su compra',
        (int)($body['showFolio'] ?? 1),
        (int)($body['showWaiter'] ?? 1),
        (int)($body['showTable'] ?? 1),
        (int)($body['showDate'] ?? 1),
        (int)($body['showItemSpecifications'] ?? 1),
        (int)($body['showTip'] ?? 1),
        min(1.50, max(0.80, (float)($body['fontScale'] ?? 1.0))),
        in_array((int)($body['fontWeight'] ?? 400), [400,700], true) ? (int)$body['fontWeight'] : 400,
        substr(trim((string)($body['plateLabel'] ?? 'Plato')) ?: 'Plato', 0, 40),
    ]);
    return ['body' => ['ok' => true]];
});

$router->add('POST', '/ticket-settings/logo', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    if (!isset($_FILES['logo']) || $_FILES['logo']['error'] !== UPLOAD_ERR_OK) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Selecciona una imagen válida']];
    }

    $file = $_FILES['logo'];
    if ($file['size'] > (int)($config['app']['max_logo_bytes'] ?? 2097152)) {
        return ['status' => 422, 'body' => ['ok' => false, 'message' => 'La imagen excede 2 MB']];
    }

    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    $extension = ['image/png' => 'png', 'image/jpeg' => 'jpg', 'image/webp' => 'webp'][$mime] ?? null;
    if (!$extension) return ['status' => 422, 'body' => ['ok' => false, 'message' => 'Solo PNG, JPG o WEBP']];

    $restaurantId = restaurantId($user);
    $name = "restaurant_{$restaurantId}_logo_" . time() . ".{$extension}";
    $destination = __DIR__ . '/uploads/logos/' . $name;
    if (!move_uploaded_file($file['tmp_name'], $destination)) {
        throw new RuntimeException('No se pudo guardar el logo');
    }

    $url = rtrim($config['app']['base_url'], '/') . '/uploads/logos/' . $name;
    $db->prepare(
        'INSERT INTO ticket_settings(restaurant_id, business_name, logo_url)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE logo_url = VALUES(logo_url)'
    )->execute([$restaurantId, $user['restaurant_name'] ?? 'Mi restaurante', $url]);

    return ['body' => ['ok' => true, 'logoUrl' => $url]];
});

// Dashboard únicamente del restaurante autenticado.
$router->add('GET', '/dashboard', function (PDO $db, array $config, array $params, array $user): array {
    $restaurantId = restaurantId($user);
    $statsStmt = $db->prepare(
        "SELECT
            COUNT(*) total_orders,
            COALESCE(SUM(status NOT IN ('completed','cancelled')),0) active_orders,
            COALESCE(SUM(is_urgent = 1 AND status NOT IN ('completed','cancelled')),0) urgent_orders,
            COALESCE(SUM(is_paid = 1),0) paid_orders,
            COALESCE(SUM(CASE WHEN DATE(paid_at) = CURDATE() THEN total_amount ELSE 0 END),0) sales_today
         FROM orders
         WHERE restaurant_id = ?"
    );
    $statsStmt->execute([$restaurantId]);

    $callsStmt = $db->prepare("SELECT COUNT(*) pending_calls FROM waiter_calls WHERE restaurant_id = ? AND status = 'pending'");
    $callsStmt->execute([$restaurantId]);

    return ['body' => ['ok' => true, 'data' => array_merge($statsStmt->fetch(), $callsStmt->fetch())]];
});


// Categorías del restaurante.
// Complementos reutilizables (Carnes / Rellenos).
// Catálogos reutilizables para configuraciones de producto.
// Ejemplos: Carnes, Rellenos, Sabores de aguas, Tamaños, Salsas, etc.
$router->add('GET', '/option-catalogs', function (PDO $db, array $config, array $params, array $user): array {
    $stmt = $db->prepare('SELECT id,name,slug,active,sort_order FROM option_catalogs WHERE restaurant_id=? ORDER BY sort_order,name,id');
    $stmt->execute([restaurantId($user)]);
    $catalogs = [];
    foreach ($stmt->fetchAll() as $catalog) {
        $v = $db->prepare(
            'SELECT v.id,v.label,v.extra_price,v.complement_id,v.linked_product_id,v.default_quantity,v.active,v.sort_order,
                    c.name AS complement_name,p.name AS linked_product_name,p.category AS linked_product_category
             FROM option_catalog_values v
             LEFT JOIN complements c ON c.id=v.complement_id
             LEFT JOIN products p ON p.id=v.linked_product_id
             WHERE v.catalog_id=? ORDER BY v.sort_order,v.id'
        );
        $v->execute([$catalog['id']]);
        $catalog['values'] = array_map(static fn(array $row): array => [
            'id'=>(string)$row['id'],'label'=>$row['label'],'extraPrice'=>(float)$row['extra_price'],
            'complementId'=>$row['complement_id']?(string)$row['complement_id']:'','complementName'=>$row['complement_name']??'',
            'linkedProductId'=>$row['linked_product_id']?(string)$row['linked_product_id']:'','linkedProductName'=>$row['linked_product_name']??'',
            'linkedProductCategory'=>$row['linked_product_category']??'','defaultQuantity'=>max(1,(int)$row['default_quantity']),
            'active'=>(bool)$row['active'],'sortOrder'=>(int)$row['sort_order'],
        ], $v->fetchAll());
        $catalog['id'] = (string)$catalog['id'];
        $catalog['active'] = (bool)$catalog['active'];
        $catalog['sortOrder'] = (int)$catalog['sort_order'];
        unset($catalog['sort_order']);
        $catalogs[] = $catalog;
    }
    return ['body'=>['ok'=>true,'data'=>$catalogs]];
});

$saveCatalog = function (PDO $db, int $restaurantId, array $body, ?int $catalogId = null): int {
    $name = trim((string)($body['name'] ?? ''));
    if ($name === '') throw new InvalidArgumentException('El nombre del catálogo es obligatorio');
    $slug = trim((string)($body['slug'] ?? ''));
    if ($slug === '') {
        $slug = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', iconv('UTF-8','ASCII//TRANSLIT',$name) ?: $name));
        $slug = trim($slug, '-');
    }
    if ($catalogId === null) {
        $db->prepare('INSERT INTO option_catalogs(restaurant_id,name,slug,active,sort_order) VALUES(?,?,?,?,?)')
           ->execute([$restaurantId,$name,$slug,(int)($body['active']??1),(int)($body['sortOrder']??0)]);
        $catalogId = (int)$db->lastInsertId();
    } else {
        $db->prepare('UPDATE option_catalogs SET name=?,slug=?,active=?,sort_order=? WHERE id=? AND restaurant_id=?')
           ->execute([$name,$slug,(int)($body['active']??1),(int)($body['sortOrder']??0),$catalogId,$restaurantId]);
        $db->prepare('DELETE FROM option_catalog_values WHERE catalog_id=?')->execute([$catalogId]);
    }
    foreach (($body['values'] ?? []) as $i=>$value) {
        $label=trim((string)($value['label']??'')); if ($label==='') continue;
        $db->prepare('INSERT INTO option_catalog_values(catalog_id,label,complement_id,linked_product_id,default_quantity,extra_price,active,sort_order) VALUES(?,?,?,?,?,?,?,?)')
           ->execute([$catalogId,$label,!empty($value['complementId'])?(int)$value['complementId']:null,!empty($value['linkedProductId'])?(int)$value['linkedProductId']:null,max(1,(int)($value['defaultQuantity']??1)),(float)($value['extraPrice']??0),(int)($value['active']??1),(int)($value['sortOrder']??$i)]);
    }
    return $catalogId;
};

$router->add('POST', '/option-catalogs', function (PDO $db, array $config, array $params, array $user) use ($saveCatalog): array {
    Auth::requireRole($user,['admin']); $body=Http::body();
    $db->beginTransaction(); try { $id=$saveCatalog($db,restaurantId($user),$body,null); $db->commit(); }
    catch(Throwable $e){$db->rollBack();throw $e;}
    return ['status'=>201,'body'=>['ok'=>true,'id'=>(string)$id]];
});

$router->add('PUT', '/option-catalogs/{id}', function (PDO $db, array $config, array $params, array $user) use ($saveCatalog): array {
    Auth::requireRole($user,['admin']); $body=Http::body(); $id=(int)$params['id'];
    $db->beginTransaction(); try { $saveCatalog($db,restaurantId($user),$body,$id); $db->commit(); }
    catch(Throwable $e){$db->rollBack();throw $e;}
    return ['body'=>['ok'=>true]];
});

$router->add('DELETE', '/option-catalogs/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user,['admin']);
    $db->prepare('DELETE FROM option_catalogs WHERE id=? AND restaurant_id=?')->execute([(int)$params['id'],restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});


// Endpoints ligeros para Agotar. No actualizan el producto completo y pueden
// ser usados por cocina sin requerir permisos de administración de catálogo.
$router->add('PUT', '/availability/products/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','chef']);
    $body = Http::body();
    $available = (int)($body['available'] ?? 0);
    $stmt = $db->prepare('UPDATE products SET available=? WHERE id=? AND restaurant_id=?');
    $stmt->execute([$available, (int)$params['id'], restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});

$router->add('PUT', '/availability/complements/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','chef']);
    $body = Http::body();
    $active = (int)($body['active'] ?? 0);
    $stmt = $db->prepare('UPDATE complements SET active=? WHERE id=? AND restaurant_id=?');
    $stmt->execute([$active, (int)$params['id'], restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});

$router->add('PUT', '/availability/options/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','chef']);
    $body = Http::body();
    $active = (int)($body['active'] ?? 0);
    $stmt = $db->prepare(
        'UPDATE option_catalog_values v
         INNER JOIN option_catalogs c ON c.id=v.catalog_id
         SET v.active=?
         WHERE v.id=? AND c.restaurant_id=?'
    );
    $stmt->execute([$active, (int)$params['id'], restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});

$router->add('GET', '/complements', function (PDO $db, array $config, array $params, array $user): array {
    $stmt=$db->prepare('SELECT id,type,name,extra_price,active,created_at,updated_at FROM complements WHERE restaurant_id=? ORDER BY type,sort_order,name');
    $stmt->execute([restaurantId($user)]);
    return ['body'=>['ok'=>true,'data'=>array_map(static fn(array $r):array=>[
        'id'=>(string)$r['id'],'type'=>$r['type'],'name'=>$r['name'],'extraPrice'=>(float)$r['extra_price'],'active'=>(bool)$r['active']
    ],$stmt->fetchAll())]];
});
$router->add('POST', '/complements', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user,['admin']); $b=Http::body(); Http::requireFields($b,['type','name']);
    $db->prepare('INSERT INTO complements(restaurant_id,type,name,extra_price,active) VALUES(?,?,?,?,?)')
       ->execute([restaurantId($user),trim((string)$b['type']),trim((string)$b['name']),(float)($b['extraPrice']??0),(int)($b['active']??1)]);
    return ['status'=>201,'body'=>['ok'=>true,'id'=>(string)$db->lastInsertId()]];
});
$router->add('PUT', '/complements/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user,['admin']); $b=Http::body(); Http::requireFields($b,['type','name']);
    $db->prepare('UPDATE complements SET type=?,name=?,extra_price=?,active=? WHERE id=? AND restaurant_id=?')
       ->execute([trim((string)$b['type']),trim((string)$b['name']),(float)($b['extraPrice']??0),(int)($b['active']??1),(int)$params['id'],restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});
$router->add('DELETE', '/complements/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user,['admin']);
    $db->prepare('DELETE FROM complements WHERE id=? AND restaurant_id=?')->execute([(int)$params['id'],restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});

$router->add('GET', '/categories', function (PDO $db, array $config, array $params, array $user): array {
    $stmt = $db->prepare('SELECT id, name, print_prefix AS printPrefix, active, created_at, updated_at FROM categories WHERE restaurant_id = ? ORDER BY name');
    $stmt->execute([restaurantId($user)]);
    return ['body' => ['ok' => true, 'data' => $stmt->fetchAll()]];
});
$router->add('POST', '/categories', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body(); Http::requireFields($body, ['name']);
    $db->prepare('INSERT INTO categories(restaurant_id,name,print_prefix,active) VALUES(?,?,?,?)')->execute([restaurantId($user), trim((string)$body['name']), trim((string)($body['printPrefix'] ?? '')), (int)($body['active'] ?? 1)]);
    return ['status' => 201, 'body' => ['ok' => true, 'id' => (string)$db->lastInsertId()]];
});
$router->add('PUT', '/categories/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $body = Http::body(); Http::requireFields($body, ['name']);
    $db->prepare('UPDATE categories SET name=?, print_prefix=?, active=? WHERE id=? AND restaurant_id=?')->execute([trim((string)$body['name']), trim((string)($body['printPrefix'] ?? '')), (int)($body['active'] ?? 1), (int)$params['id'], restaurantId($user)]);
    return ['body' => ['ok' => true]];
});
$router->add('DELETE', '/categories/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $db->prepare('DELETE FROM categories WHERE id=? AND restaurant_id=?')->execute([(int)$params['id'], restaurantId($user)]);
    return ['body' => ['ok' => true]];
});

// Mesas configurables.
$router->add('GET', '/tables', function (PDO $db, array $config, array $params, array $user): array {
    $rid = restaurantId($user);
    $stmt=$db->prepare("SELECT t.id,t.name,t.capacity,t.active,t.created_at,t.updated_at,
        CASE WHEN EXISTS(
            SELECT 1 FROM orders o
            WHERE o.restaurant_id=t.restaurant_id
              AND FIND_IN_SET(t.name, REPLACE(o.table_name, ', ', ',')) > 0
              AND UPPER(COALESCE(NULLIF(o.order_type,''), 'DINE_IN'))='DINE_IN'
              AND o.is_takeaway=0
              AND o.status NOT IN ('completed','cancelled')
              AND o.released_at IS NULL
        ) THEN 1 ELSE 0 END AS occupied
        FROM restaurant_tables t WHERE t.restaurant_id=? ORDER BY t.name");
    $stmt->execute([$rid]);
    $rows = array_map(static function(array $row): array {
        $row['occupied'] = (bool)$row['occupied'];
        $row['available'] = (bool)$row['active'] && !$row['occupied'];
        return $row;
    }, $stmt->fetchAll());
    return ['body'=>['ok'=>true,'data'=>$rows]];
});
$router->add('POST', '/tables', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']); $body=Http::body(); Http::requireFields($body,['name']);
    $db->prepare('INSERT INTO restaurant_tables(restaurant_id,name,capacity,active) VALUES(?,?,?,?)')->execute([restaurantId($user),trim((string)$body['name']),(int)($body['capacity']??4),(int)($body['active']??1)]);
    return ['status'=>201,'body'=>['ok'=>true,'id'=>(string)$db->lastInsertId()]];
});
$router->add('PUT', '/tables/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']); $body=Http::body(); Http::requireFields($body,['name']);
    $db->prepare('UPDATE restaurant_tables SET name=?,capacity=?,active=? WHERE id=? AND restaurant_id=?')->execute([trim((string)$body['name']),(int)($body['capacity']??4),(int)($body['active']??1),(int)$params['id'],restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});
$router->add('DELETE', '/tables/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $db->prepare('DELETE FROM restaurant_tables WHERE id=? AND restaurant_id=?')->execute([(int)$params['id'],restaurantId($user)]);
    return ['body'=>['ok'=>true]];
});

// Cobros realizados. Devuelve importes listos para la pantalla de Cobros.
$router->add('GET', '/payments', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier','waiter','order_taker']);
    $rid = restaurantId($user);
    $date = trim((string)Http::query('date', date('Y-m-d')));
    if (!preg_match('/^\\d{4}-\\d{2}-\\d{2}$/', $date)) {
        return ['status'=>422,'body'=>['ok'=>false,'message'=>'Fecha inválida. Usa YYYY-MM-DD']];
    }
    $q=$db->prepare("SELECT id,folio,table_name,waiter_name,total_amount,paid_amount,amount_received,change_amount,payment_method,paid_at,status
        FROM orders WHERE restaurant_id=? AND is_paid=1 AND DATE(paid_at)=? ORDER BY paid_at DESC,id DESC");
    $q->execute([$rid,$date]);
    $rows=array_map(static function(array $r): array {
        $total=(float)$r['total_amount']; $received=(float)$r['amount_received'];
        return [
            'orderId'=>(string)$r['id'],'folio'=>$r['folio'],'table'=>$r['table_name']??'','waiterName'=>$r['waiter_name']??'',
            'total'=>$total,'paidAmount'=>(float)$r['paid_amount'],'amountReceived'=>$received,
            'difference'=>$received-$total,'changeAmount'=>(float)$r['change_amount'],
            'paymentMethod'=>$r['payment_method']??'','paidAt'=>$r['paid_at'],'status'=>$r['status'],
        ];
    },$q->fetchAll());
    return ['body'=>['ok'=>true,'data'=>$rows]];
});

// Rendimiento semanal para no calcular toda la estadística en Flutter.
$router->add('GET', '/performance/weekly', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']);
    $rid=restaurantId($user);
    $start=trim((string)Http::query('start',''));
    if ($start==='' || !preg_match('/^\\d{4}-\\d{2}-\\d{2}$/',$start)) {
        $start=(new DateTimeImmutable('monday this week'))->format('Y-m-d');
    }
    $end=(new DateTimeImmutable($start))->modify('+6 days')->format('Y-m-d');
    $q=$db->prepare("SELECT DATE(paid_at) sale_date, COUNT(*) tickets, COALESCE(SUM(paid_amount),0) sales
        FROM orders WHERE restaurant_id=? AND is_paid=1 AND DATE(paid_at) BETWEEN ? AND ?
        GROUP BY DATE(paid_at) ORDER BY sale_date");
    $q->execute([$rid,$start,$end]);
    $byDate=[]; foreach($q->fetchAll() as $r) $byDate[$r['sale_date']]=$r;
    $days=[]; $total=0.0; $tickets=0;
    for($i=0;$i<7;$i++){
        $date=(new DateTimeImmutable($start))->modify("+$i days")->format('Y-m-d');
        $r=$byDate[$date]??null; $sales=(float)($r['sales']??0); $count=(int)($r['tickets']??0);
        $days[]=['date'=>$date,'sales'=>$sales,'tickets'=>$count]; $total+=$sales; $tickets+=$count;
    }
    usort($days,static fn(array $a,array $b): int => $b['sales'] <=> $a['sales']);
    foreach($days as $i=>&$day) $day['rank']=$i+1; unset($day);
    usort($days,static fn(array $a,array $b): int => strcmp($a['date'],$b['date']));
    return ['body'=>['ok'=>true,'data'=>['start'=>$start,'end'=>$end,'salesTotal'=>$total,'tickets'=>$tickets,'days'=>$days]]];
});

// Resumen diario: se incluyen pedidos no cancelados aunque no se hayan pagado.
$router->add('GET', '/cash-closures/current', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']);
    $rid=restaurantId($user); $date=trim((string)Http::query('date',date('Y-m-d')));
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/',$date)) return ['status'=>422,'body'=>['ok'=>false,'message'=>'Fecha inválida. Usa YYYY-MM-DD']];
    $q=$db->prepare("SELECT COUNT(*) ordersTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 THEN 1 ELSE 0 END),0) paidOrders,
        COALESCE(SUM(CASE WHEN is_paid=0 THEN 1 ELSE 0 END),0) unpaidOrders,
        COALESCE(SUM(CASE WHEN is_paid=0 THEN total_amount ELSE 0 END),0) unpaidTotal,
        COALESCE(SUM(total_amount),0) salesTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='cash' THEN paid_amount ELSE 0 END),0) cashTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='card' THEN paid_amount ELSE 0 END),0) cardTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='transfer' THEN paid_amount ELSE 0 END),0) transferTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 THEN tip_amount ELSE 0 END),0) tipsTotal,
        COALESCE(SUM(CASE WHEN is_paid=1 THEN paid_amount ELSE 0 END),0) expectedTotal
        FROM orders WHERE restaurant_id=? AND status <> 'cancelled' AND DATE(created_at)=?");
    $q->execute([$rid,$date]);
    return ['body'=>['ok'=>true,'data'=>$q->fetch()]];
});

$router->add('GET', '/cash-closures', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']);
    $stmt=$db->prepare('SELECT * FROM cash_closures WHERE restaurant_id=? ORDER BY closed_at DESC LIMIT 200');
    $stmt->execute([restaurantId($user)]);
    return ['body'=>['ok'=>true,'data'=>$stmt->fetchAll()]];
});
$router->add('POST', '/cash-closures', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']); $b=Http::body();
    Http::requireFields($b,['openedAt','closedAt']);
    $rid=restaurantId($user);
    $date=(new DateTimeImmutable((string)$b['openedAt']))->format('Y-m-d');
    $today=date('Y-m-d');
    if ($date>$today) return ['status'=>422,'body'=>['ok'=>false,'message'=>'No se pueden cerrar días futuros']];
    $multiple=($b['allowMultiple']??false)===true;
    $lock='cash_close_'.$rid.'_'.$date;
    $lockStmt=$db->prepare('SELECT GET_LOCK(?,10)'); $lockStmt->execute([$lock]);
    if ((int)$lockStmt->fetchColumn()!==1) return ['status'=>409,'body'=>['ok'=>false,'message'=>'Otro corte está en proceso']];
    try {
        $existing=$db->prepare('SELECT closed_at FROM cash_closures WHERE restaurant_id=? AND DATE(opened_at)=? ORDER BY closed_at DESC LIMIT 1');
        $existing->execute([$rid,$date]); $last=$existing->fetchColumn();
        if ($last!==false && !$multiple) return ['status'=>409,'body'=>['ok'=>false,'message'=>'Ya existe un corte para este día. Activa cortes adicionales para generar otro.']];
        $start=$date.' 00:00:00';
        if ($last!==false && $last>$start) $start=$last;
        $end=$date===$today ? date('Y-m-d H:i:s') : $date.' 23:59:59';
        $q=$db->prepare("SELECT COUNT(*) ordersTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 THEN 1 ELSE 0 END),0) paidOrders,
            COALESCE(SUM(CASE WHEN is_paid=0 THEN 1 ELSE 0 END),0) unpaidOrders,
            COALESCE(SUM(CASE WHEN is_paid=0 THEN total_amount ELSE 0 END),0) unpaidTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='cash' THEN paid_amount ELSE 0 END),0) cashTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='card' THEN paid_amount ELSE 0 END),0) cardTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 AND payment_method='transfer' THEN paid_amount ELSE 0 END),0) transferTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 THEN tip_amount ELSE 0 END),0) tipsTotal,
            COALESCE(SUM(CASE WHEN is_paid=1 THEN paid_amount ELSE 0 END),0) collectedTotal
            FROM orders WHERE restaurant_id=? AND status <> 'cancelled' AND created_at > ? AND created_at <= ?");
        // El primer corte incluye exactamente la medianoche.
        if ($last===false) $start=(new DateTimeImmutable($start))->modify('-1 second')->format('Y-m-d H:i:s');
        $q->execute([$rid,$start,$end]); $v=$q->fetch();
        $cash=(float)$v['cashTotal']; $opening=max(0,(float)($b['openingCash']??0)); $counted=(float)($b['countedCash']??0);
        $notes=trim((string)($b['notes']??''));
        $notes.=($notes!==''?"\n":'').'Pendientes de pago: '.$v['unpaidOrders'].' | Importe: $'.number_format((float)$v['unpaidTotal'],2,'.','');
        $stmt=$db->prepare('INSERT INTO cash_closures(restaurant_id,created_by_user_id,opened_at,closed_at,cash_total,card_total,transfer_total,tips_total,expected_total,counted_cash,difference,paid_orders,notes,opening_cash) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
        $stmt->execute([$rid,(int)$user['id'],$date.' 00:00:00',$end,$cash,(float)$v['cardTotal'],(float)$v['transferTotal'],(float)$v['tipsTotal'],(float)$v['collectedTotal']+$opening,$counted,$counted-($cash+$opening),(int)$v['paidOrders'],$notes,$opening]);
        return ['status'=>201,'body'=>['ok'=>true,'id'=>(string)$db->lastInsertId(),'closedAt'=>$end,'unpaidOrders'=>(int)$v['unpaidOrders'],'unpaidTotal'=>(float)$v['unpaidTotal']]];
    } finally {
        $unlock=$db->prepare('SELECT RELEASE_LOCK(?)'); $unlock->execute([$lock]);
    }
});

// Puestos de cocina configurables. La app ya no necesita nombres hardcodeados.
$router->add('GET', '/kitchen-stations', function (PDO $db, array $config, array $params, array $user): array {
    $rid=restaurantId($user);
    $q=$db->prepare('SELECT id,name,slug,active FROM kitchen_stations WHERE restaurant_id=? ORDER BY name,id'); $q->execute([$rid]);
    $rows=[];
    foreach($q->fetchAll() as $st){
        $c=$db->prepare('SELECT ksc.category_id,c.name category_name FROM kitchen_station_categories ksc INNER JOIN categories c ON c.id=ksc.category_id WHERE ksc.station_id=? AND ksc.active=1'); $c->execute([(int)$st['id']]);
        $pr=$db->prepare('SELECT product_id FROM kitchen_station_products WHERE station_id=? AND active=1'); $pr->execute([(int)$st['id']]);
        $cats=$c->fetchAll(); $st['categoryIds']=array_map('strval',array_column($cats,'category_id')); $st['categoryNames']=array_map(static fn($name) => function_exists('mb_strtolower') ? mb_strtolower((string)$name, 'UTF-8') : strtolower((string)$name), array_values(array_column($cats,'category_name')));
        $st['productIds']=array_map('strval',array_column($pr->fetchAll(),'product_id'));
        $rows[]=$st;
    }
    return ['body'=>['ok'=>true,'data'=>$rows]];
});

// Configuración de cocina: operaciones protegidas y aisladas por restaurante.
// Flutter envía: {name, active, categoryNames: [...], productIds: [...]}.
function kitchenStationInput(PDO $db, array $body, int $restaurantId): array
{
    $name = trim((string)($body['name'] ?? ''));
    if ($name === '' || (function_exists('mb_strlen') ? mb_strlen($name, 'UTF-8') : strlen($name)) > 120) {
        Http::json(422, ['ok' => false, 'message' => 'El nombre del puesto debe tener entre 1 y 120 caracteres']);
    }
    $active = filter_var($body['active'] ?? true, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $categoryNames = $body['categoryNames'] ?? [];
    $productIds = $body['productIds'] ?? [];
    if (!is_array($categoryNames) || !array_is_list($categoryNames) ||
        !is_array($productIds) || !array_is_list($productIds)) {
        Http::json(422, ['ok' => false, 'message' => 'Categorías y productos deben ser listas']);
    }
    if (count($categoryNames) > 200 || count($productIds) > 2000) {
        Http::json(422, ['ok' => false, 'message' => 'Demasiadas categorías o productos']);
    }
    $names = [];
    foreach ($categoryNames as $value) {
        if (!is_string($value) || trim($value) === '') {
            Http::json(422, ['ok' => false, 'message' => 'Nombre de categoría inválido']);
        }
        $names[(function_exists('mb_strtolower') ? mb_strtolower(trim($value), 'UTF-8') : strtolower(trim($value)))] = true;
    }
    $categoryIds = [];
    if ($names) {
        $q = $db->prepare('SELECT id,name FROM categories WHERE restaurant_id=? AND active=1');
        $q->execute([$restaurantId]);
        foreach ($q->fetchAll() as $row) {
            if (isset($names[(function_exists('mb_strtolower') ? mb_strtolower(trim((string)$row['name']), 'UTF-8') : strtolower(trim((string)$row['name'])))])) {
                $categoryIds[] = (int)$row['id'];
                unset($names[(function_exists('mb_strtolower') ? mb_strtolower(trim((string)$row['name']), 'UTF-8') : strtolower(trim((string)$row['name'])))]);
            }
        }
        if ($names) Http::json(422, ['ok' => false, 'message' => 'Una categoría no existe o está inactiva en este restaurante']);
    }
    $ids = [];
    foreach ($productIds as $value) {
        if ((!is_string($value) && !is_int($value)) || !ctype_digit((string)$value) || (int)$value < 1) {
            Http::json(422, ['ok' => false, 'message' => 'ID de producto inválido']);
        }
        $ids[(int)$value] = true;
    }
    if ($ids) {
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $q = $db->prepare("SELECT id FROM products WHERE restaurant_id=? AND id IN ($placeholders)");
        $q->execute(array_merge([$restaurantId], array_keys($ids)));
        if (count($q->fetchAll()) !== count($ids)) {
            Http::json(422, ['ok' => false, 'message' => 'Uno o más productos no pertenecen al restaurante']);
        }
    }
    return [$name, $active, $categoryIds, array_keys($ids)];
}

function kitchenStationSync(PDO $db, int $stationId, array $categoryIds, array $productIds): void
{
    // Se sincronizan dentro de la misma transacción que el puesto.
    $db->prepare('DELETE FROM kitchen_station_categories WHERE station_id=?')->execute([$stationId]);
    $db->prepare('DELETE FROM kitchen_station_products WHERE station_id=?')->execute([$stationId]);
    $cat = $db->prepare('INSERT INTO kitchen_station_categories(station_id,category_id,active) VALUES(?,?,1)');
    foreach ($categoryIds as $id) $cat->execute([$stationId, $id]);
    $prod = $db->prepare('INSERT INTO kitchen_station_products(station_id,product_id,active) VALUES(?,?,1)');
    foreach ($productIds as $id) $prod->execute([$stationId, $id]);
}

$router->add('POST', '/kitchen-stations', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $rid = restaurantId($user);
    [$name, $active, $categories, $products] = kitchenStationInput($db, Http::body(), $rid);
    $db->beginTransaction();
    try {
        // Slug estable y único, independiente del nombre editable.
        $slug = 'puesto-' . bin2hex(random_bytes(12));
        $q = $db->prepare('INSERT INTO kitchen_stations(restaurant_id,name,slug,active) VALUES(?,?,?,?)');
        $q->execute([$rid, $name, $slug, $active]);
        $id = (int)$db->lastInsertId();
        kitchenStationSync($db, $id, $categories, $products);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
    return ['status' => 201, 'body' => ['ok' => true, 'id' => (string)$id]];
});

$router->add('PUT', '/kitchen-stations/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $rid = restaurantId($user);
    $id = filter_var($params['id'], FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if ($id === false) Http::json(422, ['ok' => false, 'message' => 'ID de puesto inválido']);
    [$name, $active, $categories, $products] = kitchenStationInput($db, Http::body(), $rid);
    $db->beginTransaction();
    try {
        $q = $db->prepare('SELECT id FROM kitchen_stations WHERE id=? AND restaurant_id=? FOR UPDATE');
        $q->execute([$id, $rid]);
        if (!$q->fetch()) {
            $db->rollBack();
            Http::json(404, ['ok' => false, 'message' => 'Puesto no encontrado']);
        }
        $db->prepare('UPDATE kitchen_stations SET name=?,active=? WHERE id=? AND restaurant_id=?')
            ->execute([$name, $active, $id, $rid]);
        kitchenStationSync($db, (int)$id, $categories, $products);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
    return ['body' => ['ok' => true, 'id' => (string)$id]];
});

$router->add('DELETE', '/kitchen-stations/{id}', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin']);
    $rid = restaurantId($user);
    $id = filter_var($params['id'], FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if ($id === false) Http::json(422, ['ok' => false, 'message' => 'ID de puesto inválido']);
    // Borrado definitivo: eliminar primero asignaciones y después el puesto.
    // Los pedidos conservan sus propios datos; no se borran ni se modifican.
    $db->beginTransaction();
    try {
        $check = $db->prepare('SELECT id FROM kitchen_stations WHERE id=? AND restaurant_id=? FOR UPDATE');
        $check->execute([$id, $rid]);
        if (!$check->fetch()) {
            $db->rollBack();
            Http::json(404, ['ok' => false, 'message' => 'Puesto no encontrado']);
        }
        $db->prepare('DELETE FROM kitchen_station_categories WHERE station_id=?')->execute([$id]);
        $db->prepare('DELETE FROM kitchen_station_products WHERE station_id=?')->execute([$id]);
        $db->prepare('DELETE FROM kitchen_stations WHERE id=? AND restaurant_id=?')->execute([$id, $rid]);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
    return ['body' => ['ok' => true, 'id' => (string)$id, 'deleted' => true]];
});

// Finanzas: resumen de ventas/gastos y registro de egresos.
$router->add('GET', '/finances/summary', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']); $rid=restaurantId($user);
    $q=$db->prepare("SELECT COALESCE(SUM(CASE WHEN is_paid=1 AND DATE(paid_at)=CURDATE() THEN paid_amount ELSE 0 END),0) salesToday, COALESCE(SUM(CASE WHEN is_paid=1 AND YEAR(paid_at)=YEAR(CURDATE()) AND MONTH(paid_at)=MONTH(CURDATE()) THEN paid_amount ELSE 0 END),0) salesMonth FROM orders WHERE restaurant_id=?"); $q->execute([$rid]); $d=$q->fetch();
    $e=$db->prepare("SELECT COALESCE(SUM(CASE WHEN YEAR(expense_date)=YEAR(CURDATE()) AND MONTH(expense_date)=MONTH(CURDATE()) THEN amount ELSE 0 END),0) expensesMonth FROM expenses WHERE restaurant_id=?"); $e->execute([$rid]); $x=$e->fetch();
    $d['expensesMonth']=$x['expensesMonth']; $d['balanceMonth']=(float)$d['salesMonth']-(float)$x['expensesMonth'];
    return ['body'=>['ok'=>true,'data'=>$d]];
});
$router->add('GET', '/expenses', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']); $q=$db->prepare('SELECT id,concept,amount,expense_date,notes,created_at FROM expenses WHERE restaurant_id=? ORDER BY expense_date DESC,id DESC LIMIT 500'); $q->execute([restaurantId($user)]); return ['body'=>['ok'=>true,'data'=>$q->fetchAll()]];
});
$router->add('POST', '/expenses', function (PDO $db, array $config, array $params, array $user): array {
    Auth::requireRole($user, ['admin','cashier']); $b=Http::body(); Http::requireFields($b,['concept','amount']);
    $q=$db->prepare('INSERT INTO expenses(restaurant_id,created_by_user_id,concept,amount,expense_date,notes) VALUES(?,?,?,?,?,?)');
    $q->execute([restaurantId($user),(int)$user['id'],trim((string)$b['concept']),(float)$b['amount'],$b['expenseDate']??date('Y-m-d'),trim((string)($b['notes']??''))]);
    return ['status'=>201,'body'=>['ok'=>true,'id'=>(string)$db->lastInsertId()]];
});

$router->dispatch($db, $config);
