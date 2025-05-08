"""
What is a Dictionary?
A dictionary is an unordered collection of data in a key-value pair form. Each key is unique, and it is used to access the corresponding value. Dictionaries are defined using curly braces {} and key-value pairs separated by colons :. Here's the basic syntax:

my_dict = {key1: value1, key2: value2, key3: value3}
"""

# Creating a diccionary
my_dict = {'name': 'John', 'age': 30, 'city': 'New York'}
print(my_dict)

# Using dict() constructor
my_dict = dict(name='John', age=30, city='New York')
print(my_dict)

# Using a list of tuples
my_dict = dict([('name', 'John'), ('age', 30), ('city', 'New York')])
print(my_dict)


# Accessing Values
my_dict = {'name': 'John', 'age': 30, 'city': 'New York'}

name = my_dict['name']  # 'John'
age = my_dict['age']    # 30

print(name, age)

# Modifying values
my_dict = {'name': 'John', 'age': 30, 'city': 'New York'}

my_dict['age'] = 31
print(my_dict)

# Adding New Key-Value Pairs
my_dict = {'name': 'John', 'age': 30, 'city': 'New York'}

my_dict['country'] = 'USA'
print(my_dict)


"""
Dictionary Methods and Operations
    len(my_dict)    : Returns the number of key-value pairs in the dictionary.
    my_dict.keys()  : Returns a list of all keys in the dictionary.
    my_dict.values(): Returns a list of all values in the dictionary.
    my_dict.items() : Returns a list of key-value pairs (tuples).
    my_dict.get(key): Returns the value associated with the given key, or a default value if the key doesn't exist.
    key in my_dict  : Returns True if the key exists in the dictionary, False otherwise.
    del my_dict[key]: Deletes the key-value pair associated with the given key.
    my_dict.clear() : Removes all key-value pairs from the dictionary.
"""
my_dict = {'name': 'John', 'age': 30, 'city': 'New York'}

# Dictionary methods
keys   = my_dict.keys()     # ['name', 'age', 'city']
values = my_dict.values()   # ['John', 30, 'New York']
items  = my_dict.items()    # [('name', 'John'), ('age', 30), ('city', 'New York')]

# Checking if a key exists
if 'name' in my_dict:
    print(f"'name' exists, and its value is {my_dict['name']}")

# Deleting a key-value pair
del my_dict['city']

# Clearing the dictionary
my_dict.clear() # Now, my_dict is an empty dictionary: {}


# Excersises
my_dict = {'title':'Racing Club', 'author':'Lucas D Liberatori', 'year':'1981'}
book_info = my_dict
print(book_info)

book_info['genre'] = 'Sport'  
print(book_info)

if 'author' in book_info:
    print(f"'author' exists, and its value is {book_info['author']}")
