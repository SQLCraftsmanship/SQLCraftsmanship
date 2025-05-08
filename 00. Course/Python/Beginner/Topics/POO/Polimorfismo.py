
class Coche():
    def desplazamiento(self):
        print("Me desplazo utilizando cuatro ruedas")

class Moto():
    def desplazamiento(self):
        print("Me desplazo utilizando dos ruedas")

class Camion():
    def desplazamiento(self):
        print("Me desplazo utilizando ocho ruedas")


def desplazamientoVerhiculo(vehiculo):
    vehiculo.desplazamiento()
    
    
miVehiculo = Camion()
# miVehiculo.desplazamiento()
desplazamientoVerhiculo(miVehiculo)

