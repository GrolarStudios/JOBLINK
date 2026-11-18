-- Ejecutar una vez en la base de datos de Komanda antes de probar los pedidos.
-- Evita errores de "Data too long" con configuraciones/complementos extensos.
-- No borra pedidos ni complementos existentes.
ALTER TABLE order_item_specifications
  MODIFY COLUMN specification TEXT NOT NULL;
