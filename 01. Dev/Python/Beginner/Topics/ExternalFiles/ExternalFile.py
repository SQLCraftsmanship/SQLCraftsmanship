from io import open

"""
# Create ands Open
varArchivoDeTexto = open("archivo_de_texto.txt", "w")

# Manipulate
varFrase = "Hermosa noche para estudiar Python. \nHoy es 10.23.2023"
varArchivoDeTexto.write(varFrase)

# CLose from memory
varArchivoDeTexto.close()
"""

"""
# Open as read
varArchivoDeTexto = open("archivo_de_texto.txt", "r")

# Read the txt
varReadTxt = varArchivoDeTexto.read()

# Close
varArchivoDeTexto.close()

# Print infor from text
print(varReadTxt)
"""

"""
varArchivoDeTexto = open("archivo_de_texto.txt", "r")
varReadLine = varArchivoDeTexto.readlines()
varArchivoDeTexto.close()
print(varReadLine[2])
"""

"""
# Open as read
varArchivoDeTexto = open("archivo_de_texto.txt", "a")
varArchivoDeTexto.write("\nSiempre es una linda ocasion para tener sexo!!!")
varArchivoDeTexto = open("archivo_de_texto.txt", "r")
varReadTxt = varArchivoDeTexto.read()
varArchivoDeTexto.close()
print(varReadTxt)
"""

"""
# Open as read
varArchivoDeTexto = open("archivo_de_texto.txt", "r")
varArchivoDeTexto.seek(14)
print(varArchivoDeTexto.read())
varArchivoDeTexto.close()
"""


# Open as read
varArchivoDeTexto = open("archivo_de_texto.txt", "r+")
varArchivoDeTexto.write("\nSiempre Racing", len(varArchivoDeTexto))


 