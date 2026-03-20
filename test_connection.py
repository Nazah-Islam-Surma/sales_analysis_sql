import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="postgres",
    user="postgres",
    password="123"
)

print("Connected successfully!")
conn.close()