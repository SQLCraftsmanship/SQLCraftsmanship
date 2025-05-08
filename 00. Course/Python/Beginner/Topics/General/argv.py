
# ARGV
import sys

print("************************************************************************************")
print("Programa para multiplicar dos numeros usando ARGV")
print("************************************************************************************")

varNro1 = sys.argv[1]
varNro2 = sys.argv[2]

try:
    varNro1 = float(varNro1)
    varNro2 = float(varNro2)

    varTotal = varNro1 * varNro2
    print(f"La miltiplicacion de los numeros {varNro1} y {varNro2} es: ", varTotal)
except ValueError:
    print("Error en el ingreso de los valores de los numeros a multiplicar")

