import os
import re
import pyodbc

conn = pyodbc.connect(os.environ["SQL_DEST_CONN_STR"], autocommit=True)
cur = conn.cursor()

with open("DDL_ITSM_dbo.sql", encoding="utf-8") as f:
    sql = f.read()

lotes = [b.strip() for b in re.split(r"^\s*GO\s*$", sql, flags=re.MULTILINE | re.IGNORECASE) if b.strip()]
for i, lote in enumerate(lotes, 1):
    cur.execute(lote)
    print(f"lote {i}/{len(lotes)} ok")

print("\nTabelas criadas em dbo:")
for (nome,) in cur.execute("SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name"):
    print(" -", nome)
conn.close()