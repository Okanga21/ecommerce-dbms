📘 E-commerce Database Management System (DBMS)
📂 Files

ecommerce_full.sql → Complete MySQL script containing:

Database schema

Constraints & relationships

Sample data (users, products, orders, coupons, etc.)

Triggers (auto update inventory & coupon usage)

Stored procedures (place_order, apply_coupon)

🚀 Setup Instructions

Open a terminal and run:

mysql -u your_user -p < ecommerce_full.sql


Replace your_user with your MySQL username.

Verify that the database was created:

SHOW DATABASES;
USE ecommerce_db;
SHOW TABLES;

🗄️ Database Overview

Users & Profiles → Customers’ accounts and personal info.

Products & Categories → Items for sale.

Inventory → Tracks stock per product variant.

Orders & Order Items → Purchases made by customers.

Payments → Stores payment records (e.g., M-PESA).

Coupons → Discounts applied to orders.

⚙️ Features

Triggers

Auto-deduct inventory when an order is placed.

Auto-increase coupon usage when applied.

Stored Procedures

place_order(user_id, order_number, product_id, variant_id, qty, shipping)
→ Places an order, inserts items, and deducts stock.

apply_coupon(coupon_code, order_id)
→ Validates & applies discount to an order.

🧪 Example Usage
Place an Order
CALL place_order(1, 'ORD2001', 1, 1, 2, 500.00);

Apply a Coupon
CALL apply_coupon('WELCOME10', 1);

Check Updated Inventory
SELECT * FROM inventory;
