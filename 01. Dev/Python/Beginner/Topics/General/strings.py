
# String conmillas
varCadena = 'Esta es una cadena de Texto con "comillas"'
varCadenaTambien = 'Esta es una cadena de Texto con \"comillas\" tambien'
print (varCadena, varCadenaTambien)

# Substring
varCadena = 'Esta es una cadena de Texto con "comillas"'
print (varCadena[0])

varCadena = 'Esta es una cadena de Texto con "comillas"'
print (varCadena[0:4])

varCadena = 'Esta es una cadena de Texto con "comillas"'
print (varCadena[2:])

"""
    'doesn\'t'  # use \' to escape the single quote...
    "doesn't"
    "doesn't"  # ...or use double quotes instead
    "doesn't"
    '"Yes," they said.'
    '"Yes," they said.'
    "\"Yes,\" they said."
    '"Yes," they said.'
    '"Isn\'t," they said.'
    '"Isn\'t," they said.'


    s = 'First line.\nSecond line.'  # \n means newline
    s  # without print(), special characters are included in the string
    'First line.\nSecond line.'
    print(s)  # with print(), special characters are interpreted, so \n produces new line
    First line.
    Second line.


    print('C:\some\name')  # here \n means newline!
    C:\some
    ame
    print(r'C:\some\name')  # note the r before the quote
    C:\some\name
"""

varPython = 'Python'
varPython = varPython[-5]
print(varPython)
