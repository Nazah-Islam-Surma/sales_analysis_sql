import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="sales_analysis",
    user="postgres",
    password="123"
)

cur = conn.cursor()

# See all tables
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
""")

tables = cur.fetchall()
print("=== YOUR TABLES ===")
for table in tables:
    print(f"\n--- {table[0].upper()} ---")
    
    # Show columns of each table
    cur.execute(f"""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = '{table[0]}'
    """)
    columns = cur.fetchall()
    for col in columns:
        print(f"  {col[0]}: {col[1]}")

conn.close()