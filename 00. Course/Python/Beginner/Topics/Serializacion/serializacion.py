 
import pickle

# Create binary file
lista_nombre = ["A", "B", "C", "D", "E"]
varFicheroExterno = open("FicheroExterno", "wb")
pickle.dump(lista_nombre, varFicheroExterno)
varFicheroExterno.close()
del varFicheroExterno

# Read binary file
varFicheroExterno = open("FicheroExterno", "rb")
varListaNombreFromFichero = pickle.load(varFicheroExterno)
print(varListaNombreFromFichero)
