
"""
Lambdas in Python are a way to create small, anonymous functions without the need to explicitly name them. They are often used for short, simple operations that can be 
defined in a single line of code. 

The syntax for a lambda function is:
lambda arguments: expression

Here, lambda is the keyword, followed by a list of arguments, a colon, and an expression. The lambda function can take any number of arguments but can only have 
one expression.

Here are a few key points about lambda functions:

    1. Anonymous Functions: Lambda functions are anonymous, meaning they don't have a name. They are defined using the lambda keyword and are usually used for short, 
    simple operations.

    2. Single Expression: Lambda functions can only contain a single expression. This expression is evaluated and returned when the lambda function is called.

    3. No Statements: Lambda functions cannot contain statements, assignments, or multiple expressions.

Now, let's go through some examples and exercises to understand lambdas better:
"""    

 # Examples
 
# 1. Basic Lambda Function
# Lambda function to add two numbers
add = lambda x, y: x + y

result = add(3, 5)
print(result)  # Output: 8

# 2. Lambda with map()
# Using lambda with map() to square each element in a list
numbers = [1, 2, 3, 4, 5]
squared_numbers = list(map(lambda x: x**2, numbers))
print(squared_numbers)  # Output: [1, 4, 9, 16, 25]

# 3. Lambda with filter()
# Using lambda with filter() to get even numbers from a list
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
even_numbers = list(filter(lambda x: x % 2 == 0, numbers))
print(even_numbers)  # Output: [2, 4, 6, 8]


# ####################################################################################################
# Excercises
# ####################################################################################################

# 1: Using Lambda to Sort List of Tuples
# Write a Python program to sort a list of tuples based on the second element of each tuple.



