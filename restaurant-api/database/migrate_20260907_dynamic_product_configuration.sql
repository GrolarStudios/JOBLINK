-- Migración: configuraciones dinámicas de productos, sabores de agua,
-- herencia de configuración en paquetes y prefijos de impresión por categoría.
-- Diseñada para grolars1_devkomanda / MySQL 5.7.

START TRANSACTION;

CREATE TABLE IF NOT EXISTS option_catalogs (
  id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  restaurant_id bigint(20) UNSIGNED NOT NULL,
  name varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  slug varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  active tinyint(1) NOT NULL DEFAULT '1',
  sort_order int(11) NOT NULL DEFAULT '0',
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_option_catalog_restaurant_slug (restaurant_id, slug),
  KEY idx_option_catalog_restaurant (restaurant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS option_catalog_values (
  id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  catalog_id bigint(20) UNSIGNED NOT NULL,
  label varchar(140) COLLATE utf8mb4_unicode_ci NOT NULL,
  complement_id bigint(20) UNSIGNED DEFAULT NULL,
  linked_product_id bigint(20) UNSIGNED DEFAULT NULL,
  default_quantity int(10) UNSIGNED NOT NULL DEFAULT '1',
  extra_price decimal(12,2) NOT NULL DEFAULT '0.00',
  active tinyint(1) NOT NULL DEFAULT '1',
  sort_order int(11) NOT NULL DEFAULT '0',
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_option_catalog_value_label (catalog_id, label),
  KEY idx_catalog_values_catalog (catalog_id),
  KEY idx_catalog_values_complement (complement_id),
  KEY idx_catalog_values_linked_product (linked_product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- MySQL 5.7 no soporta ADD COLUMN IF NOT EXISTS, por eso se usa INFORMATION_SCHEMA.
SET @sql := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'product_option_groups'
        AND COLUMN_NAME = 'catalog_id'
    ),
    'SELECT 1',
    'ALTER TABLE product_option_groups ADD COLUMN catalog_id bigint(20) UNSIGNED DEFAULT NULL AFTER allow_repeats, ADD KEY idx_product_option_groups_catalog (catalog_id)'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'categories'
        AND COLUMN_NAME = 'print_prefix'
    ),
    'SELECT 1',
    'ALTER TABLE categories ADD COLUMN print_prefix varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '''' AFTER name'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Prefijos administrables para impresión. El producto puede seguir llamándose "Blandito" o "Mini".
UPDATE categories SET print_prefix='Taco'  WHERE name='Tacos'  AND print_prefix='';
UPDATE categories SET print_prefix='Torta' WHERE name='Tortas' AND print_prefix='';

-- Catálogos reutilizables base.
INSERT INTO option_catalogs (restaurant_id,name,slug,active,sort_order)
SELECT r.id,'Carnes','carnes',1,10
FROM restaurants r
WHERE NOT EXISTS (
  SELECT 1 FROM option_catalogs c WHERE c.restaurant_id=r.id AND c.slug='carnes'
);

INSERT INTO option_catalogs (restaurant_id,name,slug,active,sort_order)
SELECT r.id,'Rellenos','rellenos',1,20
FROM restaurants r
WHERE NOT EXISTS (
  SELECT 1 FROM option_catalogs c WHERE c.restaurant_id=r.id AND c.slug='rellenos'
);

INSERT INTO option_catalogs (restaurant_id,name,slug,active,sort_order)
SELECT r.id,'Sabores de aguas','sabores-aguas',1,30
FROM restaurants r
WHERE NOT EXISTS (
  SELECT 1 FROM option_catalogs c WHERE c.restaurant_id=r.id AND c.slug='sabores-aguas'
);

-- Copiar carnes y rellenos actuales a los catálogos reutilizables.
INSERT IGNORE INTO option_catalog_values
(catalog_id,label,complement_id,linked_product_id,default_quantity,extra_price,active,sort_order)
SELECT oc.id,c.name,c.id,NULL,1,c.extra_price,c.active,c.sort_order
FROM complements c
JOIN option_catalogs oc
  ON oc.restaurant_id=c.restaurant_id AND oc.slug='carnes'
WHERE c.type='Carne';

INSERT IGNORE INTO option_catalog_values
(catalog_id,label,complement_id,linked_product_id,default_quantity,extra_price,active,sort_order)
SELECT oc.id,c.name,c.id,NULL,1,c.extra_price,c.active,c.sort_order
FROM complements c
JOIN option_catalogs oc
  ON oc.restaurant_id=c.restaurant_id AND oc.slug='rellenos'
WHERE c.type='Relleno';

-- Conversión única de grupos legacy. Después de esta migración el runtime ya no busca nombres ni tipos hardcodeados.
UPDATE product_option_groups g
JOIN products p ON p.id=g.product_id
JOIN option_catalogs oc ON oc.restaurant_id=p.restaurant_id AND oc.slug='carnes'
SET g.catalog_id=oc.id
WHERE LOWER(g.name) LIKE '%carne%';

UPDATE product_option_groups g
JOIN products p ON p.id=g.product_id
JOIN option_catalogs oc ON oc.restaurant_id=p.restaurant_id AND oc.slug='rellenos'
SET g.catalog_id=oc.id
WHERE LOWER(g.name) LIKE '%relleno%';

-- Sabores solicitados para aguas frescas.
INSERT IGNORE INTO option_catalog_values
(catalog_id,label,default_quantity,extra_price,active,sort_order)
SELECT id,'Horchata',1,0.00,1,1 FROM option_catalogs WHERE slug='sabores-aguas';

INSERT IGNORE INTO option_catalog_values
(catalog_id,label,default_quantity,extra_price,active,sort_order)
SELECT id,'Jamaica',1,0.00,1,2 FROM option_catalogs WHERE slug='sabores-aguas';

-- Crear grupo Sabor en Agua Grande y Agua chica si aún no existe.
INSERT INTO product_option_groups
(product_id,name,multiple,required_flag,min_selections,max_selections,allow_repeats,catalog_id,depends_on_option_id,sort_order)
SELECT p.id,'Sabor',0,1,1,1,0,oc.id,NULL,0
FROM products p
JOIN option_catalogs oc ON oc.restaurant_id=p.restaurant_id AND oc.slug='sabores-aguas'
WHERE LOWER(p.name) IN ('agua grande','agua chica')
  AND NOT EXISTS (
    SELECT 1 FROM product_option_groups g WHERE g.product_id=p.id AND LOWER(g.name)='sabor'
  );

-- Si ya existía un grupo Sabor en las aguas, enlazarlo al catálogo nuevo.
UPDATE product_option_groups g
JOIN products p ON p.id=g.product_id
JOIN option_catalogs oc ON oc.restaurant_id=p.restaurant_id AND oc.slug='sabores-aguas'
SET g.catalog_id=oc.id,
    g.required_flag=1,
    g.multiple=0,
    g.min_selections=1,
    g.max_selections=1
WHERE LOWER(p.name) IN ('agua grande','agua chica')
  AND LOWER(g.name)='sabor';

COMMIT;
