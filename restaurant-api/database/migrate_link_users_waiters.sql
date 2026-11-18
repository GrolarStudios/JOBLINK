-- ============================================================
-- KOMANDA: vincular usuarios con perfil waiter y tabla waiters
-- Ejecuta una sola vez sobre la base existente.
-- Haz respaldo antes de importar.
-- ============================================================

-- 1. Agregar relación con users.
ALTER TABLE waiters
  ADD COLUMN user_id BIGINT UNSIGNED NULL AFTER restaurant_id;

-- 2. Evitar que un mismo usuario tenga dos registros de mesero.
ALTER TABLE waiters
  ADD UNIQUE KEY uq_waiters_user_id (user_id);

-- 3. Crear relación referencial.
ALTER TABLE waiters
  ADD CONSTRAINT fk_waiters_user
  FOREIGN KEY (user_id) REFERENCES users(id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;

-- 4. Relacionar registros existentes por restaurante y nombre exacto.
UPDATE waiters w
JOIN users u
  ON u.restaurant_id = w.restaurant_id
 AND u.role = 'waiter'
 AND LOWER(TRIM(u.name)) = LOWER(TRIM(w.name))
SET w.user_id = u.id
WHERE w.user_id IS NULL;

-- 5. Crear registro operativo para usuarios waiter que no lo tengan.
INSERT INTO waiters (
  restaurant_id,
  user_id,
  name,
  active
)
SELECT
  u.restaurant_id,
  u.id,
  u.name,
  u.active
FROM users u
LEFT JOIN waiters w
  ON w.user_id = u.id
WHERE u.role = 'waiter'
  AND w.id IS NULL;

-- 6. Verificación.
SELECT
  u.id AS user_id,
  u.restaurant_id,
  u.username,
  u.name AS user_name,
  u.role,
  u.active AS user_active,
  w.id AS waiter_id,
  w.name AS waiter_name,
  w.active AS waiter_active
FROM users u
LEFT JOIN waiters w
  ON w.user_id = u.id
WHERE u.role = 'waiter'
ORDER BY u.restaurant_id, u.name;
