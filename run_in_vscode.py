import sqlite3
import pandas as pd
import numpy as np
import math
import re
import datetime
import sys
import os

def load_data():
    conn = sqlite3.connect(":memory:")
    cursor = conn.cursor()
    cursor.executescript("""
    CREATE TABLE supplier (sup_id INTEGER PRIMARY KEY, sup_name TEXT, address TEXT);
    CREATE TABLE categories (cat_id INTEGER PRIMARY KEY, cat_name TEXT);
    CREATE TABLE employees (emp_id INTEGER PRIMARY KEY, emp_name TEXT, hire_date TEXT);
    CREATE TABLE customers (cust_id INTEGER PRIMARY KEY, cust_name TEXT, address TEXT);
    CREATE TABLE products (prod_id INTEGER PRIMARY KEY, prod_name TEXT, sup_id INTEGER, cat_id INTEGER, price REAL);
    CREATE TABLE orders (ord_id INTEGER PRIMARY KEY, cust_id INTEGER, emp_id INTEGER, order_date TEXT);
    CREATE TABLE order_details (ord_detID INTEGER PRIMARY KEY, ord_id INTEGER, prod_id INTEGER, quantity INTEGER, each_price REAL, total_price REAL);
    """)

    import_sql_path = os.path.join(os.path.dirname(__file__), "sql", "03_import_data.sql")
    with open(import_sql_path, "r", encoding="utf-8") as f:
        sql_text = f.read()

    inserts = re.findall(r"(INSERT\s+INTO\s+.*?;)", sql_text, re.DOTALL | re.I)
    for ins in inserts:
        cursor.execute(ins)
    conn.commit()

    # Register MySQL compatible functions
    def str_to_date(val, fmt):
        parts = val.split('/')
        return f"{int(parts[2]):04d}-{int(parts[0]):02d}-{int(parts[1]):02d}"

    def date_format(dt_str, fmt):
        parts = dt_str.split('-')
        return f"{parts[0]}-{parts[1]}"

    def weekday(dt_str):
        parts = dt_str.split('-')
        d = datetime.date(int(parts[0]), int(parts[1]), int(parts[2]))
        return d.weekday()

    conn.create_function("STR_TO_DATE", 2, str_to_date)
    conn.create_function("DATE_FORMAT", 2, date_format)
    conn.create_function("WEEKDAY", 1, weekday)
    conn.create_function("POW", 2, math.pow)
    conn.create_function("SQRT", 1, math.sqrt)
    return conn

def parse_queries():
    analysis_sql_path = os.path.join(os.path.dirname(__file__), "sql", "05_analysis.sql")
    with open(analysis_sql_path, "r", encoding="utf-8") as f:
        analysis_sql = f.read()

    q_blocks = re.findall(
        r"-- Question (\d+\.\d+): (.*?)\n(?:-- Business Context: (.*?)\n)?(?:-- (?:Nuance|Metric|Denominator|Formula): (.*?)\n)?-- Business Question: (.*?)\n-- SQL Query:\n(.*?);",
        analysis_sql,
        re.DOTALL
    )
    queries = {}
    for q_num, title, context, nuance, b_q, query_str in q_blocks:
        queries[q_num] = {
            "q_num": q_num,
            "title": title.strip(),
            "b_q": b_q.strip(),
            "sql": query_str.strip()
        }
    return queries

def print_separator(char="=", length=80):
    print(char * length)

def display_query_result(conn, q_data, max_rows=15):
    print_separator("=")
    print(f"QUESTION {q_data['q_num']}: {q_data['title']}")
    print_separator("-")
    print(f"Business Question: {q_data['b_q']}")
    print("\n--- SQL Query ---")
    print(q_data['sql'])
    print("\n--- Query Output ---")
    try:
        df = pd.read_sql_query(q_data['sql'], conn)
        total_rows = len(df)
        if total_rows == 0:
            print("[Empty Result Set - 0 rows]")
        elif total_rows <= max_rows:
            print(df.to_string(index=False))
        else:
            print(df.head(max_rows).to_string(index=False))
            print(f"\n*... displayed top {max_rows} of {total_rows} total rows ...*")
        print(f"\nStatus: SUCCESS ({total_rows} rows returned)")
    except Exception as e:
        print(f"Execution Error: {e}")
    print_separator("=")
    print()

def main():
    print_separator("=")
    print("GROCERY STORE MANAGEMENT — VS CODE INTERACTIVE SQL RUNNER")
    print_separator("=")
    print("Loading 1,170 records into local engine...")
    conn = load_data()
    queries = parse_queries()
    print(f"Loaded {len(queries)} analytical queries across 6 sections.\n")

    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg.lower() == "all":
            for q_num in sorted(queries.keys(), key=lambda x: [int(p) for p in x.split('.')]):
                display_query_result(conn, queries[q_num])
            return
        elif arg in queries:
            display_query_result(conn, queries[arg])
            return

    # Interactive menu
    while True:
        print("OPTIONS:")
        print("  [1] Run a specific question (e.g. 1.1, 1.4, 2.3, 3.1, 4.4, 5.3, 6.1)")
        print("  [2] Run a section (1 to 6)")
        print("  [3] Run ALL 25 questions sequentially")
        print("  [Q] Exit")
        choice = input("\nEnter choice: ").strip().lower()

        if choice == "q":
            print("Exiting SQL Runner. Happy querying!")
            break
        elif choice == "1":
            q_code = input("Enter Question ID (e.g. 1.4): ").strip()
            if q_code in queries:
                display_query_result(conn, queries[q_code])
            else:
                print(f"Unknown question ID '{q_code}'. Valid IDs: 1.1 to 6.3")
        elif choice == "2":
            sec = input("Enter Section Number (1 to 6): ").strip()
            matched = [q for q in sorted(queries.keys(), key=lambda x: [int(p) for p in x.split('.')]) if q.startswith(sec + ".")]
            if matched:
                for q in matched:
                    display_query_result(conn, queries[q])
            else:
                print(f"No questions found for section {sec}. Valid sections: 1 to 6.")
        elif choice == "3":
            for q_num in sorted(queries.keys(), key=lambda x: [int(p) for p in x.split('.')]):
                display_query_result(conn, queries[q_num])
        else:
            print("Invalid selection. Please try again.")

if __name__ == "__main__":
    main()
