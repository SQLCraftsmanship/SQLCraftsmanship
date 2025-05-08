
import pickle

class Vehiculo():
    
    def __init__(self, marca, modelo) -> None:
        
        self.marca = marca
        self.modelo = modelo
        self.enmarcha = False
        self.acelera = False
        self.frena = False
    
    def arrancar(self):
        self.enmarcha = True
    
    def acelerar(self):
        self.acelera = True
        
    def frenar(self):
        self.frena = True
    
    def estado(self):
        print(f"Marca : {self.marca} \nModelo: {self.modelo} \nEn Marcha: {self.enmarcha} \nAcelera: {self.acelera} \nFrena: {self.frena}")

varCoche1 = Vehiculo("Ford", "Falcon")
varCoche2 = Vehiculo("Chevrolet", "Corsa")
varCoche3 = Vehiculo("Fiat", "500")

varCoche = [varCoche1, varCoche2, varCoche3]

varFichero = open("LosCoches", "wb")

pickle.dump(varCoche, varFichero)

varFichero.close()
del (varFichero)

# READ serializable object

varFicheroRead = open("LosCoches", "rb")
varCocheRead = pickle.load(varFicheroRead)
varFicheroRead.close()

for c in varCocheRead:
    print(c.estado())

