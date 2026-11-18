-- Komanda - costo de domicilio y saldo pagado
-- Segura para una base existente: NO crea ni elimina tablas.

SET @db := DATABASE();

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=@db AND TABLE_NAME='orders' AND COLUMN_NAME='delivery_fee') = 0,
  'ALTER TABLE orders ADD COLUMN delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER delivery_address',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=@db AND TABLE_NAME='orders' AND COLUMN_NAME='paid_amount') = 0,
  'ALTER TABLE orders ADD COLUMN paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER change_amount',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Pedidos antiguos que ya estaban cobrados: su saldo aplicado debe partir
-- del total que ya quedó registrado para no volverlos a cobrar.
UPDATE orders
SET paid_amount = total_amount
WHERE is_paid = 1
  AND COALESCE(paid_amount, 0) = 0;
