
# TRY...CATCH

"""
Python provides a variety of mechanisms to handle errors and exceptions. In this guide, I'll cover the basics of error handling in Python, using official information and 
providing examples and exercises to help you understand how to handle errors effectively.

Understanding Exceptions
In Python, errors and unexpected situations are represented as exceptions. Exceptions can occur during the execution of your code when something goes wrong. 
Common exceptions include SyntaxError, TypeError, ZeroDivisionError, and more.

To handle exceptions, you use try and except blocks. Here's the basic structure of a try-except block:

    try:
        # Code that may raise an exception
    except ExceptionType as e:
        # Code to handle the exception

    try block contains the code that might raise an exception.
    except block is executed if an exception of the specified type occurs. You can catch specific exceptions or use a more general except clause to catch any exception.

Handling Exceptions
Catching Specific Exceptions
You can specify the exact exception you want to catch. For example, let's handle a ZeroDivisionError:
"""
try:
    result = 5 / 0
except ZeroDivisionError as e:
    print(f"Caught an exception: {e}")

"""
Using a Generic Exception Handler
You can also use a more generic except block to catch any exception:
"""
try:
    result = 5 / 0
except Exception as e:
    print(f"Caught an exception: {e}")

"""
Using a generic exception handler should be done with caution since it can catch any exception, making it harder to identify and debug issues.

Finally Block
You can include a finally block to execute code whether an exception occurs or not:
The code in the finally block will be executed even if an exception occurs.
"""
try:
    result = 5 / 0
except ZeroDivisionError as e:
    print(f"Caught an exception: {e}")
finally:
    print("This code always runs")


"""
Raising Exceptions
You can also raise your own exceptions using the raise statement. For example:
"""
def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("Division by zero is not allowed")
    return a / b

try:
    result = divide(5, 0)
except ZeroDivisionError as e:
    print(f"Caught an exception: {e}")

"""
Handling Multiple Exceptions
You can handle multiple exceptions in one try-except block:
"""
try:
    a = 10 / 0
except ZeroDivisionError as e:
    print(f"ZeroDivisionError: {e}")
except TypeError as e:
    print(f"TypeError: {e}")

"""    
Exercises
Write a function that takes two numbers as input and divides the first number by the second number. Handle the ZeroDivisionError exception by returning a message if division by zero occurs.

Create a program that reads a user's input and converts it to an integer. Handle the ValueError exception if the user enters something that can't be converted to an integer.

Write a function that takes a list and an index as input and returns the element at the specified index. Handle the IndexError by returning a message if the index is out of bounds.

Implement a program that opens a file specified by the user and handles the FileNotFoundError exception if the file doesn't exist.

These exercises will help you practice error handling in Python.
"""

"""
RAISE
"""
def evaluaEdad(edad):
    if edad<0:
        raise TypeError("No se pueden ingresar valores negativos")
    if edad<20:
        return "eres muy joven ..."
    if edad<40:
        return "eres joven ..."
    if edad<65:
        return "eres maduro ..."
    if edad<100:
        return "Cuidate ..."

print(evaluaEdad(-15))

