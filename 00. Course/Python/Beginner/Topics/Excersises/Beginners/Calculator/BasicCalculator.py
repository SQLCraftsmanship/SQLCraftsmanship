
import re

def sum(a,b):
    answer = a + b
    print(str(a) + " + " + str(b) + " = " + str(answer))

def sub(a,b):
    answer = a - b
    print(str(a) + " - " + str(b) + " = " + str(answer))

def mul(a,b):
    answer = a * b
    print(str(a) + " * " + str(b) + " = " + str(answer))

def div(a,b):
    answer = a / b
    print(str(a) + " / " + str(b) + " = " + str(answer))

def CalcularValor():
    
    while True:
        
        print("A. Addition")
        print("B. Subtraction")
        print("C. Multiplication")
        print("D. Division")
        print("E. Exit")
        
        strPattern = r"^[a-zA-Z]"
                      
        v_SelectOption = input("Please select an operation to do: ")
               
        if re.match(strPattern, v_SelectOption):
            if v_SelectOption.upper() == "A":
                print("Addition")
                a = int(input("Imput first number: "))
                b = int(input("Imput second number: "))
                
                if (a != r"^[0-9]$" or b != r"^[0-9]$") == False:
                    print("You have to enter two number to execute the calculation")
                else:
                    sum(a, b)         
            elif v_SelectOption.upper() == "B":
                print("Subtraction")
                a = int(input("Imput first number: "))
                b = int(input("Imput second number: "))
                
                if (a != r"^[0-9]$" or b != r"^[0-9]$") == False:
                    print("You have to enter two number to execute the calculation")
                else:
                    sub(a, b)
            elif v_SelectOption.upper() == "C":
                print("Multiplication")
                a = int(input("Imput first number: "))
                b = int(input("Imput second number: "))
                
                if (a != r"^[0-9]$" or b != r"^[0-9]$") == False:
                    print("You have to enter two number to execute the calculation")
                else:
                    mul(a, b)   
            elif v_SelectOption.upper() == "D":
                print("Division")
                a = int(input("Imput first number: "))
                b = int(input("Imput second number: "))
                
                if (a != r"^[0-9]$" or b != r"^[0-9]$") == False:
                    print("You have to enter two number to execute the calculation")
                else:
                    div(a, b)                    
            elif v_SelectOption.upper() == "E":
                print("Exit")
                quit()
        else:
            print("You can select a letter from A to E, only.")


# ******************************************************************************
# Execute the app
# ******************************************************************************

# Calculate value
CalcularValor()

