
# FUNCTIONS
"""
Functions are an essential concept in Python, allowing you to encapsulate and reuse code. I'll start with some basic information from the official Python documentation and 
then provide examples and exercises to help you understand functions better.

What is a Function?
In Python, a function is a block of reusable code that performs a specific task. Functions are defined using the def keyword, followed by the function name, a pair of 
parentheses, and a colon. The code inside the function is indented and executed when the function is called.

Here's the basic syntax for defining a function:

def function_name(parameters):
    # Function body
    # Code to perform a specific task
    return result  # Optional, a function can return a value
"""

# Examples
# 1. A function that takes no parameters and prints a message:
def greet():
    print("Hello, world!")

# Call the function
greet()

# 2. A function that takes two parameters and returns their sum:
def add_numbers(a, b):
    result = a + b
    return result

# Call the function
sum_result = add_numbers(3, 4)
print(sum_result)



# ####################################################################################################
# Excercises
# ####################################################################################################

# Function with array argument
def funArray(arr):
    varResult = ''

    for varValue in arr:
        varResult += str(varValue)
    return varResult

arrList = [24, 33, 'Racing Club', 'Python', 4]

print(funArray(arrList))
