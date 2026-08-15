import sqlite3

def test():
    conn = sqlite3.connect('softinsa_mobile.db')
    cursor = conn.cursor()
    
    # Check tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    print("TABLES:", [row[0] for row in cursor.fetchall()])
    
    # Check perfil table
    try:
        cursor.execute("SELECT * FROM perfil;")
        cols = [description[0] for description in cursor.description]
        rows = cursor.fetchall()
        print("PERFIL COLS:", cols)
        for r in rows:
            print("PERFIL ROW:", dict(zip(cols, r)))
    except Exception as e:
        print("Error reading perfil:", e)
        
    # Check outros_users table
    try:
        cursor.execute("SELECT * FROM outros_users;")
        cols = [description[0] for description in cursor.description]
        rows = cursor.fetchall()
        print("OUTROS_USERS COLS:", cols)
        print("OUTROS_USERS COUNT:", len(rows))
        for r in rows:
            print("OUTROS_USERS ROW:", dict(zip(cols, r)))
    except Exception as e:
        print("Error reading outros_users:", e)
        
    conn.close()

if __name__ == '__main__':
    test()
