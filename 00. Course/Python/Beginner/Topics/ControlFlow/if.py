
# IF

"""
In Python, the "if" statement is used for conditional execution of code based on a specific condition. It allows you to execute one block of code if a given condition 
is true and another block of code if the condition is false.

# Sintax
if condition:
    # Code to be executed if the condition is true

# with ELSE
if condition:
    # Code to be executed if the condition is true
else:
    # Code to be executed if the condition is false

# with elseif
if condition1:
    # Code to be executed if condition1 is true
elif condition2:
    # Code to be executed if condition2 is true
else:
    # Code to be executed if neither condition1 nor condition2 is true
    
In Python we can do this

edad = -7

if 0 < edad > 100:
    print(edad)
else
    print(edad+1)

"""

# Examples
x = 10
if x > 5:
    print("x is greater than 5")


age = 18
if age >= 18:
    print("You are an adult.")
else:
    print("You are a minor.")


score = 75
if score >= 90:
    print("A grade")
elif score >= 80:
    print("B grade")
elif score >= 70:
    print("C grade")
else:
    print("D grade")


# Exercise 
# 1. Write a Python program that checks if a number is even or odd. You can take the number as user input.
number = int(input("Enter a number: "))

if number % 2 == 0:
    print("The number is even.")
else:
    print("The number is odd.")

# 2. Create a program that takes a year as input and determines if it's a leap year. A leap year is evenly 
# divisible by 4 but not by 100 unless it is divisible by 400.
year = int(input("Enter a year: "))
if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
    print("Leap year")
else:
    print("Not a leap year")
