-- ============================================================
-- PROJECT: Sales Performance Analysis
-- FILE: Advanced SQL Queries
-- ============================================================

-- ─────────────────────────────────────────
-- 1. TRIGGER — Auto log sales changes
-- ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_sales_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.sales_audit_log (row_id, old_sales, new_sales, old_profit, new_profit)
    VALUES (OLD.row_id, OLD.sales, NEW.sales, OLD.profit, NEW.profit);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sales_update_trigger
    AFTER UPDATE ON public.sales_orders
    FOR EACH ROW
    WHEN (OLD.sales IS DISTINCT FROM NEW.sales)
    EXECUTE FUNCTION log_sales_change();

-- ─────────────────────────────────────────
-- 2. WINDOW FUNCTIONS — Sales Ranking
-- ─────────────────────────────────────────

-- Rank customers by total sales within each region
SELECT
    c.customer_name,
    c.segment,
    r.region_name,
    ROUND(SUM(o.sales)::NUMERIC, 2)         AS total_sales,
    ROUND(SUM(o.profit)::NUMERIC, 2)        AS total_profit,
    RANK() OVER (
        PARTITION BY r.region_name
        ORDER BY SUM(o.sales) DESC
    )                                        AS sales_rank_in_region,
    DENSE_RANK() OVER (
        ORDER BY SUM(o.sales) DESC
    )                                        AS overall_rank
FROM public.sales_orders o
JOIN public.customers c  ON o.customer_id = c.customer_id
JOIN public.regions   r  ON c.region_id   = r.region_id
GROUP BY c.customer_name, c.segment, r.region_name
ORDER BY r.region_name, sales_rank_in_region;

-- ─────────────────────────────────────────
-- 3. WINDOW FUNCTIONS — Running Total
-- ─────────────────────────────────────────

-- Monthly running total of sales
SELECT
    DATE_TRUNC('month', order_date)         AS month,
    ROUND(SUM(sales)::NUMERIC, 2)           AS monthly_sales,
    ROUND(SUM(SUM(sales)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
    )::NUMERIC, 2)                          AS running_total
FROM public.sales_orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- ─────────────────────────────────────────
-- 4. WINDOW FUNCTIONS — LAG/LEAD (MoM Growth)
-- ─────────────────────────────────────────

-- Month over month sales growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date)     AS month,
        ROUND(SUM(sales)::NUMERIC, 2)       AS total_sales
    FROM public.sales_orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month)  AS prev_month_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY month))
        / NULLIF(LAG(total_sales) OVER (ORDER BY month), 0) * 100
    , 2)                                    AS growth_pct
FROM monthly_sales
ORDER BY month;

-- ─────────────────────────────────────────
-- 5. CTE — Top Products Per Category
-- ─────────────────────────────────────────

WITH product_sales AS (
    SELECT
        p.category,
        p.sub_category,
        p.product_name,
        ROUND(SUM(o.sales)::NUMERIC, 2)     AS total_sales,
        ROUND(SUM(o.profit)::NUMERIC, 2)    AS total_profit,
        SUM(o.quantity)                     AS total_qty
    FROM public.sales_orders o
    JOIN public.products p ON o.product_id = p.product_id
    GROUP BY p.category, p.sub_category, p.product_name
),
ranked_products AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_sales DESC
        ) AS rank_in_category
    FROM product_sales
)
SELECT *
FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;

-- ─────────────────────────────────────────
-- 6. CTE — Customer RFM Analysis
-- (Recency, Frequency, Monetary)
-- ─────────────────────────────────────────

WITH rfm AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.segment,
        MAX(o.order_date)                           AS last_order_date,
        COUNT(DISTINCT o.order_id)                  AS frequency,
        ROUND(SUM(o.sales)::NUMERIC, 2)             AS monetary,
        CURRENT_DATE - MAX(o.order_date)            AS recency_days
    FROM public.sales_orders o
    JOIN public.customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
),
rfm_scored AS (
    SELECT *,
        CASE
            WHEN recency_days <= 30  THEN 'Active'
            WHEN recency_days <= 90  THEN 'Warm'
            WHEN recency_days <= 180 THEN 'Cooling'
            ELSE                          'Inactive'
        END AS recency_segment,
        CASE
            WHEN monetary >= 5000 THEN 'High Value'
            WHEN monetary >= 1000 THEN 'Mid Value'
            ELSE                       'Low Value'
        END AS value_segment
    FROM rfm
)
SELECT *
FROM rfm_scored
ORDER BY monetary DESC;

-- ─────────────────────────────────────────
-- 7. SUBQUERY — Above Average Sales Orders
-- ─────────────────────────────────────────

SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    o.sales,
    o.profit
FROM public.sales_orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.products  p ON o.product_id  = p.product_id
WHERE o.sales > (
    SELECT AVG(sales) FROM public.sales_orders
)
ORDER BY o.sales DESC
LIMIT 20;

-- ─────────────────────────────────────────
-- 8. CASE WHEN — Profit Segmentation
-- ─────────────────────────────────────────

SELECT
    order_id,
    sales,
    profit,
    discount,
    CASE
        WHEN profit > 500  THEN 'High Profit'
        WHEN profit > 100  THEN 'Medium Profit'
        WHEN profit > 0    THEN 'Low Profit'
        WHEN profit = 0    THEN 'Break Even'
        ELSE                    'Loss'
    END AS profit_category
FROM public.sales_orders
ORDER BY profit DESC;

-- ─────────────────────────────────────────
-- 9. ROLLUP — Regional Sales Summary
-- ─────────────────────────────────────────

SELECT
    r.region_name,
    p.category,
    ROUND(SUM(o.sales)::NUMERIC, 2)     AS total_sales,
    ROUND(SUM(o.profit)::NUMERIC, 2)    AS total_profit
FROM public.sales_orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.regions   r ON c.region_id   = r.region_id
JOIN public.products  p ON o.product_id  = p.product_id
GROUP BY ROLLUP(r.region_name, p.category)
ORDER BY r.region_name, p.category;

-- ─────────────────────────────────────────
-- 10. STORED PROCEDURE — Sales Report
-- ─────────────────────────────────────────

CREATE OR REPLACE PROCEDURE generate_sales_report(
    p_start_date DATE,
    p_end_date   DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Print summary
    RAISE NOTICE 'Sales Report: % to %', p_start_date, p_end_date;

    -- Create temp results
    CREATE TEMP TABLE IF NOT EXISTS temp_sales_report AS
    SELECT
        r.region_name,
        p.category,
        COUNT(DISTINCT o.order_id)          AS total_orders,
        SUM(o.quantity)                     AS total_qty,
        ROUND(SUM(o.sales)::NUMERIC, 2)     AS total_sales,
        ROUND(SUM(o.profit)::NUMERIC, 2)    AS total_profit,
        ROUND(AVG(o.discount)::NUMERIC, 3)  AS avg_discount
    FROM public.sales_orders o
    JOIN public.customers c ON o.customer_id = c.customer_id
    JOIN public.regions   r ON c.region_id   = r.region_id
    JOIN public.products  p ON o.product_id  = p.product_id
    WHERE o.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY r.region_name, p.category
    ORDER BY total_sales DESC;
END;
$$;

-- Call the procedure
CALL generate_sales_report('2016-01-01', '2016-12-31');
SELECT * FROM temp_sales_report;

-- ─────────────────────────────────────────
-- 11. MATERIALIZED VIEW — KPI Dashboard
-- ─────────────────────────────────────────

CREATE MATERIALIZED VIEW public.sales_kpi_dashboard AS
SELECT
    r.region_name,
    p.category,
    EXTRACT(YEAR FROM o.order_date)         AS year,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    COUNT(DISTINCT o.customer_id)           AS unique_customers,
    ROUND(SUM(o.sales)::NUMERIC, 2)         AS total_sales,
    ROUND(SUM(o.profit)::NUMERIC, 2)        AS total_profit,
    ROUND(AVG(o.profit/NULLIF(o.sales,0) * 100)::NUMERIC, 2) AS avg_profit_margin_pct
FROM public.sales_orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.regions   r ON c.region_id   = r.region_id
JOIN public.products  p ON o.product_id  = p.product_id
GROUP BY r.region_name, p.category, EXTRACT(YEAR FROM o.order_date);

-- Query the dashboard
SELECT * FROM public.sales_kpi_dashboard
ORDER BY year, total_sales DESC;

-- ─────────────────────────────────────────
-- 12. INDEX — Query Optimization
-- ─────────────────────────────────────────

-- Add indexes for faster queries
CREATE INDEX idx_orders_date      ON public.sales_orders(order_date);
CREATE INDEX idx_orders_customer  ON public.sales_orders(customer_id);
CREATE INDEX idx_orders_product   ON public.sales_orders(product_id);
CREATE INDEX idx_customers_region ON public.customers(region_id);

-- Check query performance with EXPLAIN
EXPLAIN ANALYZE
SELECT c.customer_name, SUM(o.sales) AS total_sales
FROM public.sales_orders o
JOIN public.customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_sales DESC
LIMIT 10;
