-- ============================================================
-- PROJECT: Sales Performance Analysis
-- DATABASE: PostgreSQL
-- AUTHOR: Your Name
-- DATE: 2026
-- DESCRIPTION: End-to-end sales analysis with CRUD + Advanced SQL
-- ============================================================

-- Drop tables if exist (clean start)
DROP TABLE IF EXISTS public.sales_orders CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.regions CASCADE;
DROP TABLE IF EXISTS public.sales_audit_log CASCADE;

-- ─────────────────────────────────────────
-- TABLE 1: regions
-- ─────────────────────────────────────────
CREATE TABLE public.regions (
    region_id   SERIAL PRIMARY KEY,
    region_name VARCHAR(20) NOT NULL UNIQUE,
    country     VARCHAR(50) DEFAULT 'United States'
);

-- ─────────────────────────────────────────
-- TABLE 2: customers
-- ─────────────────────────────────────────
CREATE TABLE public.customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    segment       VARCHAR(20) CHECK (segment IN ('Consumer', 'Corporate', 'Home Office')),
    city          VARCHAR(50),
    state         VARCHAR(50),
    postal_code   VARCHAR(10),
    region_id     INTEGER REFERENCES public.regions(region_id)
);

-- ─────────────────────────────────────────
-- TABLE 3: products
-- ─────────────────────────────────────────
CREATE TABLE public.products (
    product_id    VARCHAR(20) PRIMARY KEY,
    product_name  VARCHAR(200) NOT NULL,
    category      VARCHAR(30) CHECK (category IN ('Furniture', 'Technology', 'Office Supplies')),
    sub_category  VARCHAR(20)
);

-- ─────────────────────────────────────────
-- TABLE 4: sales_orders (FACT TABLE)
-- ─────────────────────────────────────────
CREATE TABLE public.sales_orders (
    row_id       INTEGER PRIMARY KEY,
    order_id     VARCHAR(20) NOT NULL,
    order_date   DATE NOT NULL,
    ship_date    DATE,
    ship_mode    VARCHAR(20) CHECK (ship_mode IN ('Same Day', 'First Class', 'Second Class', 'Standard Class')),
    customer_id  VARCHAR(20) REFERENCES public.customers(customer_id),
    product_id   VARCHAR(20) REFERENCES public.products(product_id),
    sales        DECIMAL(10,4),
    quantity     INTEGER,
    discount     DECIMAL(4,2),
    profit       DECIMAL(10,4)
);

-- ─────────────────────────────────────────
-- TABLE 5: sales_audit_log (for TRIGGER)
-- ─────────────────────────────────────────
CREATE TABLE public.sales_audit_log (
    log_id      SERIAL PRIMARY KEY,
    row_id      INTEGER,
    old_sales   DECIMAL(10,4),
    new_sales   DECIMAL(10,4),
    old_profit  DECIMAL(10,4),
    new_profit  DECIMAL(10,4),
    changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(50) DEFAULT CURRENT_USER
);
