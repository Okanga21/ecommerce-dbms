-- ecommerce_full.sql
-- Complete E-commerce Database Schema with Sample Data, Triggers, and Procedures

CREATE DATABASE IF NOT EXISTS ecommerce_db
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_general_ci;
USE ecommerce_db;

-- =====================================================
-- TABLES (Schema)
-- =====================================================

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(32),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE user_profiles (
  user_id BIGINT UNSIGNED NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  dob DATE,
  gender ENUM('male','female','other') DEFAULT NULL,
  bio TEXT,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE addresses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(50) NOT NULL,
  recipient_name VARCHAR(200) NOT NULL,
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) NOT NULL,
  phone VARCHAR(32),
  is_default_shipping TINYINT(1) NOT NULL DEFAULT 0,
  is_default_billing TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_addresses_user (user_id),
  CONSTRAINT fk_addresses_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categories (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  slug VARCHAR(180) NOT NULL,
  parent_id INT UNSIGNED DEFAULT NULL,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_slug (slug),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
    REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sku VARCHAR(64) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  sale_price DECIMAL(12,2) DEFAULT NULL CHECK (sale_price >= 0),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_products_sku (sku)
) ENGINE=InnoDB;

CREATE TABLE product_categories (
  product_id BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, category_id),
  INDEX idx_pc_category (category_id),
  CONSTRAINT fk_pc_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pc_category FOREIGN KEY (category_id)
    REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product_variants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(80) NOT NULL,
  variant_name VARCHAR(200),
  additional_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_variant_sku (sku),
  INDEX idx_variant_product (product_id),
  CONSTRAINT fk_variant_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventory (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED DEFAULT NULL,
  quantity INT NOT NULL DEFAULT 0,
  reserved INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_inventory_product (product_id),
  INDEX idx_inventory_variant (variant_id),
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_variant FOREIGN KEY (variant_id)
    REFERENCES product_variants(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE coupons (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(64) NOT NULL,
  description VARCHAR(255),
  discount_type ENUM('fixed','percent') NOT NULL,
  discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
  max_uses INT UNSIGNED DEFAULT NULL,
  used_count INT UNSIGNED NOT NULL DEFAULT 0,
  starts_at DATETIME DEFAULT NULL,
  expires_at DATETIME DEFAULT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_coupons_code (code)
) ENGINE=InnoDB;

CREATE TABLE orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  order_number VARCHAR(64) NOT NULL,
  status ENUM('pending','paid','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  shipping DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (shipping >= 0),
  discount DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (discount >= 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  coupon_id INT UNSIGNED DEFAULT NULL,
  shipping_address_id BIGINT UNSIGNED DEFAULT NULL,
  billing_address_id BIGINT UNSIGNED DEFAULT NULL,
  placed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orders_number (order_number),
  INDEX idx_orders_user (user_id),
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id)
    REFERENCES coupons(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id)
    REFERENCES addresses(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_orders_billing_address FOREIGN KEY (billing_address_id)
    REFERENCES addresses(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED DEFAULT NULL,
  product_name VARCHAR(255) NOT NULL,
  sku VARCHAR(80) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_order_items_order (order_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
    REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_variant FOREIGN KEY (variant_id)
    REFERENCES product_variants(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  payment_provider VARCHAR(100) NOT NULL,
  provider_payment_id VARCHAR(255),
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  currency VARCHAR(10) NOT NULL DEFAULT 'USD',
  status ENUM('initiated','successful','failed','refunded') NOT NULL DEFAULT 'initiated',
  processed_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_payments_order (order_id),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
    REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- SAMPLE DATA
-- =====================================================

INSERT INTO users (email, password_hash, phone) VALUES
('alice@example.com', 'hashed_pw_1', '0712345678'),
('bob@example.com', 'hashed_pw_2', '0722334455');

INSERT INTO user_profiles (user_id, first_name, last_name, gender)
VALUES (1, 'Alice', 'Wanjiku', 'female'),
       (2, 'Bob', 'Omondi', 'male');

INSERT INTO addresses (user_id, label, recipient_name, line1, city, country, phone)
VALUES (1, 'Home', 'Alice Wanjiku', 'Moi Avenue 123', 'Nairobi', 'Kenya', '0712345678'),
       (2, 'Work', 'Bob Omondi', 'Kenyatta Street 45', 'Kisumu', 'Kenya', '0722334455');

INSERT INTO categories (name, slug) VALUES
('Electronics', 'electronics'),
('Fashion', 'fashion');

INSERT INTO products (sku, name, description, price)
VALUES ('ELEC001', 'Smartphone X', 'Latest smartphone with AI features', 30000.00),
       ('FASH001', 'Blue Denim Jeans', 'Stylish slim fit jeans', 2500.00);

INSERT INTO product_categories (product_id, category_id)
VALUES (1, 1), (2, 2);

INSERT INTO product_variants (product_id, sku, variant_name, additional_price)
VALUES (1, 'ELEC001-BLK', 'Black 128GB', 0.00),
       (2, 'FASH001-L', 'Size L', 0.00);

INSERT INTO inventory (product_id, variant_id, quantity)
VALUES (1, 1, 10),
       (2, 2, 25);

INSERT INTO coupons (code, description, discount_type, discount_value, max_uses)
VALUES ('WELCOME10', '10% off for new users', 'percent', 10.00, 100);

INSERT INTO orders (user_id, order_number, subtotal, shipping, discount, total, coupon_id, shipping_address_id, billing_address_id)
VALUES (1, 'ORD1001', 30000.00, 500.00, 3000.00, 27500.00, 1, 1, 1);

INSERT INTO order_items (order_id, product_id, variant_id, product_name, sku, unit_price, quantity, line_total)
VALUES (1, 1, 1, 'Smartphone X', 'ELEC001-BLK', 30000.00, 1, 30000.00);

INSERT INTO payments (order_id, payment_provider, provider_payment_id, amount, currency, status, processed_at)
VALUES (1, 'mpesa', 'MP12345XYZ', 27500.00, 'KES', 'successful', NOW());

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //
CREATE TRIGGER trg_orderitem_inventory AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
  UPDATE inventory
  SET quantity = quantity - NEW.quantity
  WHERE variant_id = NEW.variant_id;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_coupon AFTER INSERT ON orders
FOR EACH ROW
BEGIN
  IF NEW.coupon_id IS NOT NULL THEN
    UPDATE coupons
    SET used_count = used_count + 1
    WHERE id = NEW.coupon_id;
  END IF;
END;
//
DELIMITER ;

-- =====================================================
-- PROCEDURES
-- =====================================================

DELIMITER //
CREATE PROCEDURE apply_coupon(IN p_coupon_code VARCHAR(64), IN p_order_id BIGINT)
BEGIN
  DECLARE v_coupon_id INT;
  DECLARE v_discount_type ENUM('fixed','percent');
  DECLARE v_discount_value DECIMAL(10,2);
  DECLARE v_max_uses INT;
  DECLARE v_used_count INT;

  SELECT id, discount_type, discount_value, max_uses, used_count
  INTO v_coupon_id, v_discount_type, v_discount_value, v_max_uses, v_used_count
  FROM coupons
  WHERE code = p_coupon_code AND is_active = 1
    AND (expires_at IS NULL OR expires_at > NOW())
  LIMIT 1;

  IF v_coupon_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or expired coupon';
  END IF;

  IF v_max_uses IS NOT NULL AND v_used_count >= v_max_uses THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Coupon usage limit reached';
  END IF;

  IF v_discount_type = 'fixed' THEN
    UPDATE orders SET discount = v_discount_value, total = total - v_discount_value, coupon_id = v_coupon_id
    WHERE id = p_order_id;
  ELSE
    UPDATE orders SET discount = subtotal * (v_discount_value / 100),
                      total = total - (subtotal * (v_discount_value / 100)),
                      coupon_id = v_coupon_id
    WHERE id = p_order_id;
  END IF;

  UPDATE coupons SET used_count = used_count + 1 WHERE id = v_coupon_id;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE place_order(
  IN p_user_id BIGINT,
  IN p_order_number VARCHAR(64),
  IN p_product_id BIGINT,
  IN p_variant_id BIGINT,
  IN p_qty INT,
  IN p_shipping DECIMAL(12,2)
)
BEGIN
  DECLARE v_price DECIMAL(12,2);
  DECLARE v_subtotal DECIMAL(12,2);
  DECLARE v_total DECIMAL(12,2);
  DECLARE v_order_id BIGINT;

  SELECT price INTO v_price FROM products WHERE id = p_product_id;

  SET v_subtotal = v_price * p_qty;
  SET v_total = v_subtotal + p_shipping;

  INSERT INTO orders (user_id, order_number, subtotal, shipping, discount, total, placed_at)
  VALUES (p_user_id, p_order_number, v_subtotal, p_shipping, 0.00, v_total, NOW());

  SET v_order_id = LAST_INSERT_ID();

  INSERT INTO order_items (order_id, product_id, variant_id, product_name, sku, unit_price, quantity, line_total)
  SELECT v_order_id, p.id, p_variant_id, p.name, p.sku, v_price, p_qty, v_price * p_qty
  FROM products p WHERE p.id = p_product_id;

  UPDATE inventory SET quantity = quantity - p_qty WHERE variant_id = p_variant_id;
END;
//
DELIMITER ;
