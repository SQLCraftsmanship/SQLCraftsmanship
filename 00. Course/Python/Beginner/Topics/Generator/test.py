"""
def returnCities(*parCities):
    for a in parCities:
        # for b in a:
        yield from a

varCities = returnCities("Ramos Mejia", "Haedo", "Moron")

print(next(varCities))
print(next(varCities))
print(next(varCities))

def simple_generator():
    yield 1
    yield 2
    yield 3

gen = simple_generator()

for value in gen:
    print(value)
    
Exercises:
Write a generator function to generate a sequence of even numbers starting from 2 up to a given limit.

Create a generator function that generates the squares of numbers up to a specified limit.

Write a generator function to generate the first n prime numbers.

Implement a generator that reads lines from a text file and yields them one at a time. You can use a sample text file for this exercise.

Create a generator that generates random numbers between a specified range. Use the random module to help with this.

Here are the solutions to these exercises:

python
Copy code
def even_generator(limit):
    for i in range(2, limit + 1, 2):
        yield i
python
Copy code
def square_generator(limit):
    for i in range(1, limit + 1):
        yield i ** 2
python
Copy code
def is_prime(num):
    if num <= 1:
        return False
    for i in range(2, int(num**0.5) + 1):
        if num % i == 0:
            return False
    return True

def prime_generator(n):
    count, num = 0, 2
    while count < n:
        if is_prime(num):
            yield num
            count += 1
        num += 1
python
Copy code
def line_reader(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            yield line
python
Copy code
import random

def random_number_generator(low, high, count):
    for _ in range(count):
        yield random.randint(low, high)
"""

def fibonacci_generator():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b

fib = fibonacci_generator() #We use this line only tyo generate the GENERATOR
#print(fib)

for _ in range(13):
    print(next(fib))
