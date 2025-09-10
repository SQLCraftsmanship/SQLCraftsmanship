def evaluaEdad(edad):
    if edad<0:
        raise TypeError("No se pueden ingresar valores negativos")
    if edad<20:
        return "eres muy joven ..."
    if edad<40:
        return "eres joven ..."
    if edad<65:
        return "eres maduro ..."
    if edad<100:
        return "Cuidate ..."

print(evaluaEdad(15))
