-- Komanda - migración 2026-08-29
-- Método de pago y domicilio ya existen en tu dump actual; se conservan y se usan desde API/Flutter.
ALTER TABLE orders
  ADD COLUMN preparing_at DATETIME NULL AFTER paid_at,
  ADD COLUMN ready_at DATETIME NULL AFTER preparing_at;

ALTER TABLE ticket_settings
  ADD COLUMN font_scale DECIMAL(4,2) NOT NULL DEFAULT 1.00 AFTER show_tip,
  ADD COLUMN font_weight SMALLINT NOT NULL DEFAULT 400 AFTER font_scale;

-- Normaliza registros viejos que no tenían order_type.
UPDATE orders
SET order_type = CASE WHEN is_takeaway = 1 THEN 'TAKEAWAY' ELSE 'DINE_IN' END
WHERE order_type IS NULL OR order_type = '';
