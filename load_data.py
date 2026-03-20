import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# Load CSV
df = pd.read_csv(r'C:\sales analysis\Sample - Superstore.csv\Sample - Superstore.csv', encoding='latin1')
print("CSV loaded:", df.shape)

# Connect to Postgres
conn = psycopg2.connect(host="localhost", database="sales_analysis", user="postgres", password="123")
cur = conn.cursor()

# Load regions
regions = df[['Region']].drop_duplicates().reset_index(drop=True)
regions['region_id'] = regions.index + 1
for _, row in regions.iterrows():
    cur.execute("INSERT INTO regions (region_id, region_name, country) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                (row['region_id'], row['Region'], 'United States'))

# Load products
products = df[['Product ID', 'Product Name', 'Category', 'Sub-Category']].drop_duplicates()
for _, row in products.iterrows():
    cur.execute("INSERT INTO products (product_id, product_name, category, sub_category) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
                (row['Product ID'], row['Product Name'], row['Category'], row['Sub-Category']))

# Load customers
region_map = dict(zip(regions['Region'], regions['region_id']))
customers = df[['Customer ID', 'Customer Name', 'Segment', 'City', 'State', 'Postal Code', 'Region']].drop_duplicates()
for _, row in customers.iterrows():
    cur.execute("INSERT INTO customers (customer_id, customer_name, segment, city, state, postal_code, region_id) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
                (row['Customer ID'], row['Customer Name'], row['Segment'], row['City'], row['State'], str(row['Postal Code']), region_map[row['Region']]))

# Load sales orders
for _, row in df.iterrows():
    cur.execute("INSERT INTO sales_orders (row_id, order_id, order_date, ship_date, ship_mode, customer_id, product_id, sales, quantity, discount, profit) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
                (row['Row ID'], row['Order ID'], row['Order Date'], row['Ship Date'], row['Ship Mode'], row['Customer ID'], row['Product ID'], row['Sales'], row['Quantity'], row['Discount'], row['Profit']))

conn.commit()
conn.close()
print("All data loaded successfully!")