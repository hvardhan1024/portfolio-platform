import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Get DB credentials from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME
    )

    cur = conn.cursor()

    # Query the users table
    cur.execute("SELECT * FROM users;")
    rows = cur.fetchall()

    # Print column names
    col_names = [desc[0] for desc in cur.description]
    print(" | ".join(col_names))
    print("-" * 50)

    # Print each row
    for row in rows:
        print(" | ".join(map(str, row)))

    # Close connections
    cur.close()
    conn.close()

except Exception as e:
    print("Error connecting to the database:", e)
