-- ============================================================
-- PROJECT: Sales Performance Analysis
-- FILE: CRUD Operations
-- ============================================================

-- ─────────────────────────────────────────
-- CREATE (INSERT) Operations
-- ─────────────────────────────────────────

-- Add a new customer
INSERT INTO public.customers (customer_id, customer_name, segment, city, state, postal_code, region_id)
VALUES ('NEW-001', 'Raj Kumar', 'Corporate', 'Chennai', 'Tamil Nadu', '600001', 1);

-- Add a new product
INSERT INTO public.products (product_id, product_name, category, sub_category)
VALUES ('TECH-NEW-001', 'Apple MacBook Pro 16', 'Technology', 'Machines');

-- Add a new sales order
INSERT INTO public.sales_orders (row_id, order_id, order_date, ship_date, ship_mode, customer_id, product_id, sales, quantity, discount, profit)
VALUES (9999, 'IN-2026-001', '2026-03-01', '2026-03-05', 'First Class', 'NEW-001', 'TECH-NEW-001', 2499.99, 1, 0.10, 499.99);

-- ─────────────────────────────────────────
-- READ (SELECT) Operations
-- ─────────────────────────────────────────

-- Read all customers
SELECT * FROM public.customers LIMIT 10;

-- Read orders for a specific customer
SELECT 
    o.order_id,
    o.order_date,
    p.product_name,
    p.category,
    o.sales,
    o.profit
FROM public.sales_orders o
JOIN public.products p ON o.product_id = p.product_id
WHERE o.customer_id = 'NEW-001';

-- Read top 10 orders by sales
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    o.sales,
    o.profit
FROM public.sales_orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.products p ON o.product_id = p.product_id
ORDER BY o.sales DESC
LIMIT 10;

-- ─────────────────────────────────────────
-- UPDATE Operations
-- ─────────────────────────────────────────

-- Update customer city
UPDATE public.customers
SET city = 'Bangalore', state = 'Karnataka'
WHERE customer_id = 'NEW-001';

-- Update product discount for an order
UPDATE public.sales_orders
SET discount = 0.15, profit = 450.00
WHERE row_id = 9999;

-- Apply 5% discount to all Technology orders in West region
UPDATE public.sales_orders
SET discount = discount + 0.05
WHERE product_id IN (
    SELECT product_id FROM public.products WHERE category = 'Technology'
)
AND customer_id IN (
    SELECT customer_id FROM public.customers WHERE region_id = (
        SELECT region_id FROM public.regions WHERE region_name = 'West'
    )
);

-- ─────────────────────────────────────────
-- DELETE Operations
-- ─────────────────────────────────────────

-- Delete a specific order
DELETE FROM public.sales_orders
WHERE row_id = 9999;

-- Delete test customer (after removing their orders)
DELETE FROM public.customers
WHERE customer_id = 'NEW-001';

-- Delete test product
DELETE FROM public.products
WHERE product_id = 'TECH-NEW-001';
