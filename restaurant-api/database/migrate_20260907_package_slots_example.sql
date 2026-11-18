-- =============================================================
-- Paquetes dinámicos por posiciones
-- Ejemplo: 1 Torta + 2 Tacos
-- Compatible con MySQL 5.7
-- =============================================================

START TRANSACTION;

-- 1) Crear el paquete de ejemplo si todavía no existe.
INSERT INTO products
  (restaurant_id, name, category, description, product_kind, pricing_mode, price, available, image_url)
SELECT
  1,
  'Paquete Torta + 2 Tacos',
  'Paquetes',
  'Paquete configurable por posiciones',
  'package',
  'fixed',
  96.00,
  1,
  ''
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1
  FROM products
  WHERE restaurant_id = 1
    AND name = 'Paquete Torta + 2 Tacos'
    AND product_kind = 'package'
);

SET @package_id := (
  SELECT id
  FROM products
  WHERE restaurant_id = 1
    AND name = 'Paquete Torta + 2 Tacos'
    AND product_kind = 'package'
  ORDER BY id
  LIMIT 1
);

-- 2) Este paquete se reconstruye en tres posiciones independientes.
--    No se guarda "Tacos = 2"; se guardan Taco 1 y Taco 2 por separado.
DELETE po
FROM product_options po
INNER JOIN product_option_groups pog ON pog.id = po.group_id
WHERE pog.product_id = @package_id;

DELETE FROM product_option_groups
WHERE product_id = @package_id;

-- Torta 1
INSERT INTO product_option_groups
  (product_id, name, multiple, required_flag, min_selections, max_selections, allow_repeats, catalog_id, sort_order)
VALUES
  (@package_id, 'Torta 1', 0, 1, 1, 1, 0, NULL, 0);
SET @slot_torta := LAST_INSERT_ID();

INSERT INTO product_options
  (group_id, label, complement_id, linked_product_id, default_quantity, extra_price, sort_order)
SELECT
  @slot_torta,
  p.name,
  NULL,
  p.id,
  1,
  0.00,
  (@row_torta := @row_torta + 1)
FROM products p
CROSS JOIN (SELECT @row_torta := -1) vars
WHERE p.restaurant_id = 1
  AND p.category = 'Tortas'
  AND p.product_kind <> 'package'
  AND p.available = 1
ORDER BY p.name, p.id;

-- Taco 1
INSERT INTO product_option_groups
  (product_id, name, multiple, required_flag, min_selections, max_selections, allow_repeats, catalog_id, sort_order)
VALUES
  (@package_id, 'Taco 1', 0, 1, 1, 1, 0, NULL, 1);
SET @slot_taco_1 := LAST_INSERT_ID();

INSERT INTO product_options
  (group_id, label, complement_id, linked_product_id, default_quantity, extra_price, sort_order)
SELECT
  @slot_taco_1,
  p.name,
  NULL,
  p.id,
  1,
  0.00,
  (@row_taco1 := @row_taco1 + 1)
FROM products p
CROSS JOIN (SELECT @row_taco1 := -1) vars
WHERE p.restaurant_id = 1
  AND p.category = 'Tacos'
  AND p.product_kind <> 'package'
  AND p.available = 1
ORDER BY p.name, p.id;

-- Taco 2 (posición separada e independiente)
INSERT INTO product_option_groups
  (product_id, name, multiple, required_flag, min_selections, max_selections, allow_repeats, catalog_id, sort_order)
VALUES
  (@package_id, 'Taco 2', 0, 1, 1, 1, 0, NULL, 2);
SET @slot_taco_2 := LAST_INSERT_ID();

INSERT INTO product_options
  (group_id, label, complement_id, linked_product_id, default_quantity, extra_price, sort_order)
SELECT
  @slot_taco_2,
  p.name,
  NULL,
  p.id,
  1,
  0.00,
  (@row_taco2 := @row_taco2 + 1)
FROM products p
CROSS JOIN (SELECT @row_taco2 := -1) vars
WHERE p.restaurant_id = 1
  AND p.category = 'Tacos'
  AND p.product_kind <> 'package'
  AND p.available = 1
ORDER BY p.name, p.id;

COMMIT;

-- Resultado esperado:
-- Paquete Torta + 2 Tacos
--   Torta 1 -> permite seleccionar una torta y después sus configuraciones.
--   Taco 1  -> permite seleccionar un taco y después sus configuraciones.
--   Taco 2  -> permite seleccionar otro taco y después sus configuraciones.
