-- Komanda - pedidos grandes / especificaciones extensas
-- Ejecutar una sola vez sobre la BD de komanda-api-dev.

ALTER TABLE order_item_specifications
  MODIFY COLUMN specification TEXT NOT NULL;

-- Estos índices aceleran lectura/borrado de los renglones de pedidos grandes.
-- Si alguno ya existe, omite únicamente esa sentencia.
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_item_specs_item_id ON order_item_specifications(order_item_id);
