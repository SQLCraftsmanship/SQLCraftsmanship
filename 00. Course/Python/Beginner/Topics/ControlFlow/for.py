
# FOR

"""
Is a fundamental control structure that allows you to repeatedly execute a block of code for a predefined number of times or over a collection of items.

Let's start by exploring the basic syntax and usage of the for loop in Python, and then I'll provide examples and exercises to help you practice.

Basic Syntax of a for Loop

In Python, the for loop is typically used to iterate over sequences like lists, tuples, strings, or ranges. Here's the basic syntax of a for loop:

    for variable in iterable:
        # Code to be executed in each iteration

    variable: This is a variable that will take on the value of each item in the iterable during each iteration.
    iterable: This is the collection of items over which the loop iterates.
"""

# Example 1: Iterating Over a List
# Let's start with a simple example of iterating over a list of numbers and printing each number:
# This code will iterate through the list numbers and print each element, one at a time.
numbers = [1, 2, 3, 4, 5]

for number in numbers:
    print(number)


# Example 2: Iterating Over a String
# You can also use a for loop to iterate over the characters of a string:
# This code will print each character of the string text one by one.
text = "Hello, Python!"

for character in text:
    print(character)


# Example 3: Using range() for a Fixed Number of Iterations
# The range() function is often used with for loops when you want to iterate a specific number of times. 
# For example, to print the numbers from 1 to 5:
# This code uses range(1, 6) to generate numbers from 1 to 5.
for number in range(1, 6):
    print(number)

"""
    Exercises
    Now, let's try some exercises to practice using for loops in Python:

    Exercise 1: Write a for loop to calculate the sum of the first 10 natural numbers (1 to 10) and print the result.

    Exercise 2: Create a list of your favorite fruits and use a for loop to print each fruit's name.

    Exercise 3: Write a program that asks the user to enter a number and then use a for loop to print the multiplication table for that number from 1 to 10.

    Feel free to try these exercises and let me know if you have any questions or need help with them.
"""
