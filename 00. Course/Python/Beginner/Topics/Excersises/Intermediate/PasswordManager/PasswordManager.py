"""
# Script Name: PasswordManager
# Date       : 10/26
# Function   : PasswordManager
# Owner      : LLI
"""

# ===========================================================
# Import section
# ===========================================================


# ===========================================================
# Var section
# ===========================================================


# ===========================================================
# Class section
# ===========================================================

#
def view_passwords():
        with open("passwords.txt", "r") as f:
            for line in f:
                print(line.rstrip())


def add_password():
    name = input("Account name: ")
    pwd = input("Password: ")
    
    with open("passwords.txt", "a") as f:
        f.write(f"{name} | {pwd}\n")


def main():
    while True:
        mode = input("Would you like to add a new password or view existing ones (view, add), press Q to quit? ").lower()
        
        if mode == "q":
            break
        elif mode == "view":
            view_passwords()
        elif mode == "add":
            add_password()
        else:
            print("Invalid mode")
            continue


# ===========================================================
# Main section
# ===========================================================
main()

