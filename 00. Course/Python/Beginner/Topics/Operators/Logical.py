
"""
Logical operators 

In Python are used to perform operations on Boolean values (True or False). Python has three main logical operators: and, or, and not. 
I'll explain each of them with official information, provide examples, and give you some exercises to practice.

    and Operator:
        The and operator returns True if both operands are True. Otherwise, it returns False. Official Python documentation reference: Logical AND (and)
        https://docs.python.org/3/reference/expressions.html#binary-bitwise-operations

        Example:
            x = True
            y = False

            result = x and y
            print(result)  # Output: False

        Exercise:
            Write a Python program that checks if a person is eligible for voting. You should ask for the person's age and if they are a citizen. 
            The person is eligible to vote if they are at least 18 years old and a citizen.


    or Operator:
        The or operator returns True if at least one of the operands is True. It returns False only if both operands are False.
        Official Python documentation reference: Logical OR (or)
        https://docs.python.org/3/reference/expressions.html#binary-bitwise-operations

        Example:
            x = True
            y = False

            result = x or y
            print(result)  # Output: True

        Exercise:
        Write a Python program that checks if a number is either positive or even. Ask the user for a number and use the or operator to check both conditions.

    
    not Operator:
        The not operator returns the opposite of the Boolean value. If the operand is True, not returns False, and if the operand is False, not returns True.
        Official Python documentation reference: Logical NOT (not)
        https://docs.python.org/3/reference/expressions.html#unary-arithmetic-and-bitwise-operations

        Example:
            x = True

            result = not x
            print(result)  # Output: False

        Exercise:
        Write a Python program that checks if a user-entered number is not equal to 0. Use the not operator to perform this check.

        Now, let's combine these operators in some exercises:

        Exercise 1: Create a Python program that checks if a number is a multiple of both 3 and 5. Ask the user for a number and use the and operator to check both conditions.

        Exercise 2: Write a Python program that checks if a number is either a multiple of 2 or a multiple of 3. Ask the user for a number and use the or operator to check both conditions.

        These exercises will help you practice using logical operators in Python. You can use if statements to implement the conditions and display appropriate messages based on the results.
"""
