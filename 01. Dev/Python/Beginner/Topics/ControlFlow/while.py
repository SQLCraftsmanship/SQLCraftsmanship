
# WHILE

"""
Is a control structure in Python (and in many other programming languages) that allows you to execute a block of code repeatedly as long as a certain condition is true. 
Here's the basic syntax:

    while condition:
        # Code to be executed while the condition is true

    
The condition is a boolean expression that is evaluated before each iteration of the loop. If the condition is True, the code inside the loop is executed. If the condition 
is False, the loop terminates, and the program continues with the code that comes after the while block.

Let's look at some examples and exercises to help you understand how while loops work.

"""

# Example 1: Simple While Loop
# This loop will print the value of count as long as it's less than 5. It will stop when count becomes 5 or greater.
count = 0
while count < 5:
    print(f"Count is {count}")
    count += 1


# Example 2: Infinite Loop with Break
# In this example, the loop runs indefinitely (while True), but it can be terminated by the user typing 'quit' to break out of the loop.
while True:
    user_input = input("Enter 'quit' to exit: ")
    if user_input == 'quit':
        break
    print(f"You entered: {user_input}")


# Exercise 1: Count from 1 to 10
# Write a while loop that prints numbers from 1 to 10.
count = 1
while count <= 10:
    print(count)
    count += 1

# Exercise 2: Sum of Even Numbers
# Write a while loop that calculates the sum of even numbers from 2 to 20 and prints the result.
total = 0
number = 2

while number <= 20:
    total += number
    number += 2

print(f"The sum of even numbers from 2 to 20 is: {total}")


# Exercise 3: Password Verification
# Write a while loop that asks the user to enter a password. The loop should continue until the user enters the correct password, which is 'password123'.
while True:
    password = input("Enter your password: ")

    if password == 'password123':
        print("Access granted!")
        break
    else:
        print("Incorrect password. Try again.")

# These exercises should help you practice using while loops in Python. They cover basic looping concepts and conditions.


"""
Continue, Pass , Else
"""
# Continue
for varLetra in "Python":
    if varLetra=="h":
        continue
    print(f"La letra es: {varLetra}")

# Pass
while True:
    pass

# Else
   # This will execute at the end of the loop
    