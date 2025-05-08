
"""
What are Tuples?
A tuple is a collection of ordered and immutable (unchangeable) elements. They are similar to lists but differ in their mutability. Once you create a tuple, you cannot 
change its content - add, remove, or modify elements.
"""
my_tuple = (1, 2, 3)
print(my_tuple)

# You can also create a tuple without parentheses, but it's a good practice to use them for clarity, especially in complex cases.
my_tuple = 4, 5, 6


"""
Accessing Tuple Elements:
You can access individual elements in a tuple by their index, just like with lists. The indexing is zero-based.
"""
my_tuple = (1, 2, 3)
print(my_tuple[0])  # Output: 1
print(my_tuple[1])  # Output: 2
print(my_tuple[2])  # Output: 3

"""
Tuple Slicing:
You can also slice tuples to extract a range of elements. Slicing works the same way as with lists.
"""
my_tuple = (1, 2, 3, 4, 5)
print(my_tuple[1:4])  # Output: (2, 3, 4)

"""
Tuple Methods:
Tuples have two methods:
    count(): Returns the number of times a specified value appears in the tuple.
    index(): Searches the tuple for a specified value and returns the position of the first occurrence.
    list() : Convert tuple into list
    tuple(): Convert list into tuple
    len()  : Returns the number of elements on the tuple 
"""
my_tuple = (1, 2, 2, 3, 4, 4, 4)
print(my_tuple.count(2))  # Output: 2 (number of 2s)
print(my_tuple.index(4))  # Output: 4 (position of first 4)

"""
Tuple Packing and Unpacking:
You can "pack" multiple values into a single tuple, and then "unpack" them into separate variables. This is a powerful feature of tuples.
"""
coordinates = (3, 4)
x, y = coordinates  # Unpacking the tuple
print(f"x: {x}, y: {y}")  # Output: x: 3, y: 4

# Examples
# Creating a tuple
fruits = ("apple", "banana", "cherry")

# Accessing elements
print(fruits[1])  # Output: banana

# Tuple packing and unpacking
point = (5, 10)
x, y = point
print(f"x: {x}, y: {y}")  # Output: x: 5, y: 10

# Slicing
numbers = (1, 2, 3, 4, 5)
subset = numbers[1:4]
print(subset)  # Output: (2, 3, 4)

# Exercises
tup_Colors = ('celeste', 'blanco', 'azul')
print(tup_Colors[2])

tup_days_of_week = ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
tup_workdays = tup_days_of_week[:5]
print(tup_workdays)
