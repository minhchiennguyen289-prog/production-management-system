import mysql.connector
from tabulate import tabulate

# 1. DATABASE CONNECTION
def connect_db():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="123456789", # <-- ĐỔI THÀNH MẬT KHẨU MYSQL CỦA MÀY Ở ĐÂY NHÉ
            database="production_db"
        )
        return conn
    except mysql.connector.Error as err:
        print(f"Connection Error: {err}")
        return None

# 2. FEATURE 1: VIEW PRODUCTION STATUS (VIEW)
def view_production_status(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_ProductionStatus")
    records = cursor.fetchall()
    
    print("\n--- PRODUCTION STATUS REPORT ---")
    headers = ["Order ID", "Product Name", "Plant", "Quantity", "Start Date", "Status"]
    print(tabulate(records, headers=headers, tablefmt="grid"))
    cursor.close()

# 3. FEATURE 2: CALCULATE MATERIAL COST (UDF)
def calculate_material_cost(conn):
    product_id = input("Enter Product ID to calculate cost (e.g., 1): ")
    cursor = conn.cursor()
    
    cursor.execute(f"SELECT ProductName, CalculateMaterialCost({product_id}) FROM Products WHERE ProductID = {product_id}")
    result = cursor.fetchone()
    
    if result:
        print(f"\n=> Material cost to make 1 '{result[0]}' is: ${result[1]}")
    else:
        print("\n[!] Product not found.")
    cursor.close()

# 4. FEATURE 3: CREATE NEW ORDER (PROCEDURE)
def create_order(conn):
    print("\n--- CREATE NEW ORDER ---")
    product_id = input("Enter Product ID: ")
    plant_id = input("Enter Plant ID: ")
    quantity = input("Enter Quantity: ")
    start_date = input("Enter Start Date (YYYY-MM-DD): ")
    
    cursor = conn.cursor()
    try:
        cursor.callproc('CreateProductionOrder', [product_id, plant_id, quantity, start_date])
        conn.commit()
        print("\n[V] Order created successfully! Default status is 'Pending'.")
    except Exception as e:
        print(f"\n[X] Error: {e}")
    cursor.close()

# 5. FEATURE 4: COMPLETE ORDER & UPDATE INVENTORY (TRIGGER)
def complete_order(conn):
    order_id = input("Enter completed Order ID to update inventory (e.g., 1): ")
    cursor = conn.cursor()
    try:
        cursor.execute(f"UPDATE Orders SET Status = 'Completed' WHERE OrderID = {order_id}")
        conn.commit()
        print(f"\n[V] Order {order_id} updated to 'Completed'!")
        print("    -> TRIGGER ACTIVATED: Stock Quantity updated automatically!")
    except Exception as e:
        print(f"\n[X] Error: {e}")
    cursor.close()

# MAIN MENU
def main_menu():
    conn = connect_db()
    if not conn:
        return

    while True:
        print("\n" + "="*40)
        print(" PRODUCTION MANAGEMENT SYSTEM (ERP)")
        print("="*40)
        print("1. View Production Status")
        print("2. Calculate Material Cost")
        print("3. Create New Order")
        print("4. Complete Order & Update Inventory")
        print("5. Exit System")
        print("="*40)
        
        choice = input("Select an option (1-5): ")
        
        if choice == '1':
            view_production_status(conn)
        elif choice == '2':
            calculate_material_cost(conn)
        elif choice == '3':
            create_order(conn)
        elif choice == '4':
            complete_order(conn)
        elif choice == '5':
            print("Exiting system... Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.")
            
    conn.close()

if __name__ == "__main__":
    main_menu()