
# super()
# isinstance() return True of False

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

class Moto(Vehiculo):
    wheelie = ""

    def wheelie(self):
        self.wheelie = "Estoy haciendo wheelie!!!!"

    def estado(self):
        print(f"Marca : {self.marca} \nModelo: {self.modelo} \nEn Marcha: {self.enmarcha} \nAcelera: {self.acelera} \nFrena: {self.frena} \nWheelie: {self.wheelie}")

class Cuartriciclo(Moto):
    pass
    
class Furgoneta(Vehiculo):
    
    def carga(self, cargar):
        self.cargado = cargar
        
        if(self.cargado):
            return "La furgoneta esta cargada"
        else:
            return "La forgoneta no esta cargada"
  
class vElectrico(Vehiculo):
    def __init__(self, marca, modelo) -> None:
        
        super().__init__(marca, modelo)
        
        self.autonomia = 100
    
    def cargarEnergia(self):
        self.cargado = True

class BicicletaElectrica(vElectrico,Vehiculo):
    pass

