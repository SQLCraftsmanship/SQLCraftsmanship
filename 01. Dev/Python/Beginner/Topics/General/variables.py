
# Comentario of single line

# Con Python las variables las podes llamar como vos quieras y el tipo de dato se asigna segun lo que le pones y luego la podes cambiar
# segun lo que le vas poniendo

varSting = 'Racing Club'
print (varSting)

varSting = 11
print (varSting)

# Asignamos valores a multiples variables en una sola linea
varA, varB, varC = 1, 2, 3
print (varA, varB, varC)

# Con del eliminamos variables
# del varA
# print(varA)

# Concatenar valores string + int
varA, varB, varC = 1, 'Racing Club', 3
varConcat = str(varA) + ' ' + varB + ' ' + str(varC)
print(varConcat)

# Convert str and int
varString = '1'
varInt = 1
varTotal = int(varString) + varInt
print('El total de la suma de las variables varString y varInt es:', varTotal)
