-- Ejecutar una sola vez sobre grolars1_restaurant después de respaldar.
ALTER TABLE `ticket_settings` ADD COLUMN `plate_label` VARCHAR(40) NOT NULL DEFAULT 'Plato' AFTER `font_weight`;
ALTER TABLE `complements` MODIFY COLUMN `type` VARCHAR(80) COLLATE utf8mb4_unicode_ci NOT NULL;
