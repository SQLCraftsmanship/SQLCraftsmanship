
# Modularizacion
# Encapsulacion
# Constructores

class Coche():

    def __init__(self):
        self.__largo = 250
        self.__ancho = 120
        self.__ruedas = 4 # Con el __ hacemos que sea privada
        self.__enmarcha = False
    
    def arrancar(self, arrancamos):
        self.__enmarcha = arrancamos

        if(self.__enmarcha):
            chequeo = self.__ChequeoInterno()
        
        if(self.__enmarcha and chequeo):
            return print("El auto esta en marcha")
        elif(self.__enmarcha and chequeo == False):
            return print("Algo salio mal en el chequeo interno")
        else:
            return print("El auto esta parado")
    
    def estado(self):
        print("El coche tiene ", self.__ruedas, "ruedas. Un ancho de ", self.__ancho, " y un largo de ", self.__largo)
    
    def __ChequeoInterno(self):
        print("Realizando Chequeo Interno")

        self.gasolina = "ok"
        self.aceite = "ok"
        self.puertas = "cerradas"
        
        if(self.gasolina == "ok" and self.aceite == "ok" and self.puertas == "cerradas"):
            return True
        else:
            return False        



miCoche = Coche()
print(miCoche.arrancar(True))
miCoche.estado()
print ("**************************************************************************")
miCoche = Coche()
print(miCoche.arrancar(False))
miCoche.estado()

