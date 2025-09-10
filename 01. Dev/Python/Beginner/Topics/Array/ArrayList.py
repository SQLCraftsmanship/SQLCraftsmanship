
# Array de tipo List

""" 
Python documentation with exercices!!
https://docs.python.org/3/tutorial/introduction.html#lists

In Python, Lists are one of the most commonly used data structures, and they can hold a collection of items of different types.
Lists are ordered, mutable, and can contain elements like integers, strings, and even other lists.
Here's an overview of lists in Python: """ 

# 1. Creating a List
# You can create a list by enclosing a comma-separated sequence of values within square brackets []. Here's an example:
my_list = [1, 2, 3, 4, 5]
print (my_list)


# 2. Accessing Elements
# Lists are indexed, and you can access individual elements by their index. Indexing starts from 0. For example:
first_element = my_list[0]  # Access the first element (1)
third_element = my_list[2]  # Access the third element (3)

print(first_element)
print(third_element) 

# 3 Slicing
# You can also extract a subset of a list using slicing. Slicing uses the format list[start:stop:step]. For example:
sublist = my_list[1:4]  # Get elements 2, 3, and 4
print(sublist)

# Modifying Lists
# Lists are mutable, which means you can change their contents. You can update an element by assigning a new value to a specific index, 
# add elements using append(), and remove elements using methods like remove() or pop()
my_list[2] = 42    # Update the third element to 42
print(my_list)
my_list.append(6)  # Add an element (6) to the end
print(my_list)
my_list.pop(1)     # Remove the second element
print(my_list)

# The built-in function len() also applies to lists:
letters = ['a', 'b', 'c', 'd']
varLen = len(letters)
print(varLen)



""" 
List Method

The list data type has some more methods. Here are all of the methods of list objects:

list.append(x)
Add an item to the end of the list. Equivalent to a[len(a):] = [x].

list.extend(iterable)
Extend the list by appending all the items from the iterable. Equivalent to a[len(a):] = iterable.

list.insert(i, x)
Insert an item at a given position. The first argument is the index of the element before which to insert, so a.insert(0, x) inserts at the front of the list, and a.insert(len(a), x) is equivalent to a.append(x).

list.remove(x)
Remove the first item from the list whose value is equal to x. It raises a ValueError if there is no such item.

list.pop([i])
Remove the item at the given position in the list, and return it. If no index is specified, a.pop() removes and returns the last item in the list. (The square brackets around the i in the method signature denote that the parameter is optional, not that you should type square brackets at that position. You will see this notation frequently in the Python Library Reference.)

list.clear()
Remove all items from the list. Equivalent to del a[:].

list.index(x[, start[, end]])
Return zero-based index in the list of the first item whose value is equal to x. Raises a ValueError if there is no such item.

The optional arguments start and end are interpreted as in the slice notation and are used to limit the search to a particular subsequence of the list. The returned index is computed relative to the beginning of the full sequence rather than the start argument.

list.count(x)
Return the number of times x appears in the list.

list.sort(*, key=None, reverse=False)
Sort the items of the list in place (the arguments can be used for sort customization, see sorted() for their explanation).

list.reverse()
Reverse the elements of the list in place.

list.copy()
Return a shallow copy of the list. Equivalent to a[:].

An example that uses most of the list methods:
"""

fruits = ['orange', 'apple', 'pear', 'banana', 'kiwi', 'apple', 'banana']
fruits.count('apple')

fruits.count('tangerine')

fruits.index('banana')

fruits.index('banana', 4)  # Find next banana starting at position 4

fruits.reverse()
fruits
['banana', 'apple', 'kiwi', 'banana', 'pear', 'apple', 'orange']
fruits.append('grape')
fruits
['banana', 'apple', 'kiwi', 'banana', 'pear', 'apple', 'orange', 'grape']
fruits.sort()
fruits
['apple', 'apple', 'banana', 'banana', 'grape', 'kiwi', 'orange', 'pear']
fruits.pop()
'pear'

"""
You might have noticed that methods like insert, remove or sort that only modify the list have no return value printed – they return the default None. 
1 This is a design principle for all mutable data structures in Python.

Another thing you might notice is that not all data can be sorted or compared. For instance, [None, 'hello', 10] doesn’t sort because integers can’t 
be compared to strings and None can’t be compared to other types. Also, there are some types that don’t have a defined ordering relation. 
For example, 3+4j < 5+7j isn’t a valid comparison.
"""
