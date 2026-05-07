import mysql.connector
from tabulate import tabulate
from datetime import datetime, date, timedelta
import subprocess 
import os         

# ============================================================
#  PROJECT 12: PRODUCTION MANAGEMENT SYSTEM
#  DATCOM Lab - NEU College of Technology
# ============================================================

# ============================================================
# 1. DATABASE CONNECTION
# ============================================================
def connect_db():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="123456789",  # <-- ĐỔI THÀNH MẬT KHẨU MYSQL CỦA MÀY
            database="production__db" # Fix nhẹ: tên db là production__db theo đúng file schema
        )
        return conn
    except mysql.connector.Error as err:
        print(f"[X] Connection Error: {err}")
        return None


# ============================================================
# 2. FEATURE 1: VIEW PRODUCTION STATUS (VIEW 1)
# ============================================================
def view_production_status(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_ProductionStatus")
    records = cursor.fetchall()
    print("\n--- PRODUCTION STATUS REPORT ---")
    headers = ["Order ID", "Product Name", "Plant", "Quantity", "Start Date", "Status"]
    print(tabulate(records, headers=headers, tablefmt="grid"))
    cursor.close()


# ============================================================
# 3. FEATURE 2: VIEW MATERIAL USAGE (VIEW 2)
# ============================================================
def view_material_usage(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_MaterialUsage")
    records = cursor.fetchall()
    print("\n--- MATERIAL USAGE REPORT ---")
    headers = ["Material ID", "Material Name", "Unit", "Supplier",
               "Total Consumed", "Total Cost ($)"]
    print(tabulate(records, headers=headers, tablefmt="grid"))
    cursor.close()


# ============================================================
# 4. FEATURE 3: VIEW SUPPLIER DELIVERIES (VIEW 3)
# ============================================================
def view_supplier_deliveries(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_SupplierDeliveries")
    records = cursor.fetchall()
    print("\n--- SUPPLIER DELIVERY OVERVIEW ---")
    headers = ["Supplier ID", "Supplier Name", "Phone",
               "Materials Supplied", "Total Units Delivered", "Total Value ($)"]
    print(tabulate(records, headers=headers, tablefmt="grid"))
    cursor.close()


# ============================================================
# 5. FEATURE 4: CALCULATE MATERIAL COST (UDF)
# ============================================================
def calculate_material_cost(conn):
    product_id = input("Enter Product ID to calculate cost (e.g., 1): ").strip()
    if not product_id.isdigit():
        print("[!] Invalid input. Please enter a numeric Product ID.")
        return

    cursor = conn.cursor()
    cursor.execute(
        "SELECT ProductName, CalculateMaterialCost(%s) FROM Products WHERE ProductID = %s",
        (product_id, product_id)
    )
    result = cursor.fetchone()
    if result:
        print(f"\n=> Material cost to make 1 '{result[0]}': ${result[1]:.2f}")
    else:
        print("\n[!] Product not found.")
    cursor.close()


# ============================================================
# 6. FEATURE 5: CREATE NEW ORDER (STORED PROCEDURE)
# ============================================================
def create_order(conn):
    print("\n--- CREATE NEW ORDER ---")
    product_id = input("Enter Product ID: ").strip()
    plant_id   = input("Enter Plant ID: ").strip()
    quantity   = input("Enter Quantity: ").strip()
    start_date = input("Enter Start Date (YYYY-MM-DD): ").strip()

    if not (product_id.isdigit() and plant_id.isdigit() and quantity.isdigit()):
        print("[!] Product ID, Plant ID, and Quantity must be numeric.")
        return
    try:
        datetime.strptime(start_date, "%Y-%m-%d")
    except ValueError:
        print("[!] Invalid date format. Use YYYY-MM-DD.")
        return

    cursor = conn.cursor()
    try:
        cursor.callproc('CreateProductionOrder',
                        [int(product_id), int(plant_id), int(quantity), start_date])
        conn.commit()
        print("\n[V] Order created successfully! Default status: 'Pending'.")
    except Exception as e:
        print(f"\n[X] Error: {e}")
    cursor.close()


# ============================================================
# 7. FEATURE 6: COMPLETE ORDER & UPDATE INVENTORY (TRIGGER)
# ============================================================
def complete_order(conn):
    order_id = input("Enter Order ID to mark as Completed: ").strip()
    if not order_id.isdigit():
        print("[!] Invalid input. Please enter a numeric Order ID.")
        return

    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE Orders SET Status = 'Completed' WHERE OrderID = %s",
            (int(order_id),)
        )
        conn.commit()
        if cursor.rowcount == 0:
            print(f"\n[!] No order found with ID {order_id}.")
        else:
            print(f"\n[V] Order {order_id} updated to 'Completed'!")
            print("    -> TRIGGER ACTIVATED: StockQuantity updated automatically!")
    except Exception as e:
        print(f"\n[X] Error: {e}")
    cursor.close()


# ============================================================
# 8. REPORTING MODULE
# ============================================================
def _print_production_report(conn, start_date: str, end_date: str, label: str):
    cursor = conn.cursor()
    cursor.callproc('GetProductionReport', [start_date, end_date])
    rows = []
    for result in cursor.stored_results():
        rows = result.fetchall()

    print(f"\n{'='*60}")
    print(f"  {label}")
    print(f"  Period: {start_date}  →  {end_date}")
    print(f"{'='*60}")
    if rows:
        headers = ["Product", "Plant", "Status",
                   "Total Orders", "Total Units", "Production Value ($)"]
        print(tabulate(rows, headers=headers, tablefmt="grid"))
    else:
        print("  No orders found for this period.")
    cursor.close()

def report_daily(conn):
    today = date.today().strftime("%Y-%m-%d")
    _print_production_report(conn, today, today, "DAILY PRODUCTION REPORT")
    _print_stock_summary(conn)

def report_weekly(conn):
    today = date.today()
    start = (today - timedelta(days=today.weekday())).strftime("%Y-%m-%d")
    end   = today.strftime("%Y-%m-%d")
    _print_production_report(conn, start, end, "WEEKLY PRODUCTION REPORT")
    _print_stock_summary(conn)

def report_monthly(conn):
    today = date.today()
    start = today.replace(day=1).strftime("%Y-%m-%d")
    end   = today.strftime("%Y-%m-%d")
    _print_production_report(conn, start, end, "MONTHLY PRODUCTION REPORT")
    _print_stock_summary(conn)

def report_custom(conn):
    print("\n--- CUSTOM DATE RANGE REPORT ---")
    start_date = input("Enter start date (YYYY-MM-DD): ").strip()
    end_date   = input("Enter end date   (YYYY-MM-DD): ").strip()
    try:
        datetime.strptime(start_date, "%Y-%m-%d")
        datetime.strptime(end_date,   "%Y-%m-%d")
    except ValueError:
        print("[!] Invalid date format. Use YYYY-MM-DD.")
        return
    _print_production_report(conn, start_date, end_date, "CUSTOM PRODUCTION REPORT")
    _print_stock_summary(conn)

def _print_stock_summary(conn):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT ProductID, ProductName, UnitPrice, StockQuantity FROM Products ORDER BY ProductID"
    )
    rows = cursor.fetchall()
    print("\n  --- CURRENT STOCK LEVELS ---")
    headers = ["Product ID", "Product Name", "Unit Price ($)", "Stock Qty"]
    print(tabulate(rows, headers=headers, tablefmt="simple"))
    cursor.close()

def reporting_menu(conn):
    while True:
        print("\n" + "-"*40)
        print("  REPORTING MODULE")
        print("-"*40)
        print("  1. Daily Report   (today)")
        print("  2. Weekly Report  (this week)")
        print("  3. Monthly Report (this month)")
        print("  4. Custom Date Range")
        print("  5. Back to Main Menu")
        print("-"*40)
        choice = input("Select report type (1-5): ").strip()
        if   choice == '1': report_daily(conn)
        elif choice == '2': report_weekly(conn)
        elif choice == '3': report_monthly(conn)
        elif choice == '4': report_custom(conn)
        elif choice == '5': break
        else: print("Invalid choice. Try again.")


# ============================================================
# EXTRA FEATURE: VIEW MATERIAL INVENTORY
# ============================================================
def view_material_inventory(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_MaterialInventory")
    rows = cursor.fetchall()

    print("\n--- MATERIAL INVENTORY ---")
    headers = ["Material ID", "Material Name", "Unit", "Stock Quantity", "Supplier"]
    print(tabulate(rows, headers=headers, tablefmt="grid"))
    cursor.close()

# ============================================================
# EXTRA FEATURE: UPDATE MATERIAL STOCK (MANUAL ADJUSTMENT)
# ============================================================
def update_material_stock(conn):
    material_id = input("Enter Material ID: ").strip()
    quantity = input("Enter quantity to add/remove: ").strip()

    if not (material_id.isdigit() and quantity.lstrip('-').isdigit()):
        print("[!] Invalid input.")
        return

    cursor = conn.cursor()
    try:
        cursor.callproc('UpdateMaterialStock', [int(material_id), int(quantity)])
        conn.commit()
        print("\n[V] Material inventory updated successfully!")
    except Exception as e:
        print(f"\n[X] Error: {e}")
    cursor.close()


# ============================================================
# PURCHASE RAW MATERIALS
# ============================================================
def purchase_material(conn):
    print("\n--- PURCHASE RAW MATERIALS ---")
    supplier_id = input("Enter Supplier ID: ").strip()
    material_id = input("Enter Material ID: ").strip()
    quantity    = input("Enter Quantity to purchase: ").strip()
    total_cost  = input("Enter Total Cost ($): ").strip()
    
    if not (supplier_id.isdigit() and material_id.isdigit() and quantity.isdigit()):
        print("[!] IDs and Quantity must be numeric.")
        return

    try:
        total_cost = float(total_cost)
    except ValueError:
        print("[!] Total cost must be a number.")
        return

    purchase_date = date.today().strftime("%Y-%m-%d")
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO MaterialPurchases (SupplierID, MaterialID, Quantity, PurchaseDate, TotalCost)
               VALUES (%s, %s, %s, %s, %s)""",
            (int(supplier_id), int(material_id), int(quantity), purchase_date, total_cost)
        )
        cursor.execute(
            "UPDATE Materials SET StockQuantity = StockQuantity + %s WHERE MaterialID = %s",
            (int(quantity), int(material_id))
        )
        conn.commit()
        print(f"\n[V] Successfully purchased {quantity} units! MaterialPurchases table & Stock updated.")
    except Exception as e:
        conn.rollback()
        print(f"\n[X] Error during purchase: {e}")
    cursor.close()


# ============================================================
# BACKUP/EXPORT DATABASE
# ============================================================
def backup_database():
    print("\n--- DATABASE BACKUP ---")
    backup_filename = f"production_db_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
    
    db_user = "root"
    db_pass = "123456789"  
    db_name = "production__db"
    dump_cmd = [
        "/opt/homebrew/bin/mysqldump",
        f"-u{db_user}",
        f"-p{db_pass}",
        db_name
    ]

    try:
        with open(backup_filename, "w") as outfile:
            subprocess.run(dump_cmd, stdout=outfile, check=True)
        print(f"[V] Backup successful! File saved as: {backup_filename}")
        print("    (Mở Finder ra là thấy file nằm ngay cùng thư mục code nhé)")
    except FileNotFoundError:
        print("[X] Lỗi: Không tìm thấy lệnh 'mysqldump'.")
        print("    -> Lệnh mysqldump chưa được add vào biến môi trường PATH trên máy Mac của mày.")
        os.remove(backup_filename)
    except subprocess.CalledProcessError as e:
        print(f"[X] Lỗi khi chạy mysqldump: {e}")
        if os.path.exists(backup_filename):
            os.remove(backup_filename)


# ============================================================
# 9. MAIN MENU
# ============================================================
def main_menu():
    conn = connect_db()
    if not conn:
        return

    while True:
        print("\n" + "="*50)
        print("   PRODUCTION MANAGEMENT SYSTEM (ERP)")
        print("   DATCOM Lab - National Economics University")
        print("="*50)
        print("  --- VIEWS ---")
        print("  1.  View Production Status")
        print("  2.  View Material Usage")
        print("  3.  View Supplier Deliveries")
        print("  --- OPERATIONS ---")
        print("  4.  Calculate Material Cost (per unit)")
        print("  5.  Create New Production Order")
        print("  6.  Complete Order & Update Inventory")
        print("  --- MATERIAL MANAGEMENT ---")
        print("  7.  View Material Inventory")
        print("  8.  Purchase Raw Materials (NEW)") 
        print("  9.  Update Material Stock (Manual)")
        print("  --- REPORTS ---")
        print("  10. Reporting Module (Daily / Weekly / Monthly)")
        print("  --- SYSTEM ---")
        print("  11. Backup / Export Database")
        print("  12. Exit System")
        print("="*50)

        choice = input("Select an option (1-12): ").strip()

        if   choice == '1': view_production_status(conn)
        elif choice == '2': view_material_usage(conn)
        elif choice == '3': view_supplier_deliveries(conn)
        elif choice == '4': calculate_material_cost(conn)
        elif choice == '5': create_order(conn)
        elif choice == '6': complete_order(conn)
        elif choice == '7': view_material_inventory(conn)
        elif choice == '8': purchase_material(conn)
        elif choice == '9': update_material_stock(conn)
        elif choice == '10': reporting_menu(conn)
        elif choice == '11': backup_database()
        elif choice == '12':
            print("\nExiting system... Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.")

    conn.close()

if __name__ == "__main__":
    main_menu()