
"""
Generators in Python are a powerful and memory-efficient way to create iterators. They allow you to iterate over a potentially large sequence of data without loading the 
entire sequence into memory at once. Generators are defined using functions and the yield keyword.

Here's a breakdown of generators in Python, along with examples and exercises to help you understand them better.

Basics of Generators:
1. Generator Functions: Generators are created using generator functions. A generator function is defined like a regular function, but it uses the yield keyword 
instead of return. When a generator function is called, it doesn't execute immediately; instead, it returns a generator object.

2. The yield Statement: The yield statement is used to produce a value in the generator and temporarily pause the function's execution. The state of the function is 
saved, and it can be resumed from where it left off when needed.

3. Iterating Over a Generator: You can iterate over the elements of a generator using a for loop, or you can explicitly call the next() function on the generator object.

4. Lazy Evaluation: Generators use lazy evaluation, meaning that they only generate and yield values one at a time. This makes them memory-efficient, especially when 
dealing with large data sets.

Example 1: Simple Generator Function
def simple_generator():
    yield 1
    yield 2
    yield 3

gen = simple_generator()

for value in gen:
    print(value)

2: Fibonacci Generator
Here's an example of a generator function that generates the Fibonacci sequence:

def fibonacci_generator():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b

fib = fibonacci_generator()
for _ in range(10):
    print(next(fib))
"""

#########################################################################################################
# Simple generator
#########################################################################################################

# Whitout generatror
def generaPares(varLimite):
    varNum = 1
    
    varList=[]
    
    while varNum < varLimite:
        
        varList.append(varNum*2)
        
        varNum+=1
    
    return varList

print(generaPares(10))


# Whit generatror
def generaPares(varLimite):
    varNum = 1
       
    while varNum < varLimite:
        
        yield varNum*2
        
        varNum+=1
    
varReturnEven = generaPares(10)

for i in varReturnEven:
    if i == 8:
        continue
    print(i)
    

#########################################################################################################
# Generador Anidado
#########################################################################################################
def returnCities(*parCities):
    for a in parCities:
        # for b in a:
        yield from a

varCities = returnCities("Ramos Mejia", "Haedo", "Moron")

print(next(varCities))
print(next(varCities))
print(next(varCities))

