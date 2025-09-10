
import pickle

class Persona():
    
    # Create constructor
    def __init__(self, pNombre, pGenero, pEdad) -> None:
        self.varNombre = pNombre
        self.varGenero = pGenero
        self.varEdad   = pEdad
        
        print(f"Se ha creado una persona nueva con nombre: {self.varNombre}, con genero: {self.varGenero} y una edad de: {self.varEdad}")
        
    def __str__(self) -> str:
        return "{} {} {}".format(self.varNombre, self.varGenero, self.varEdad)
    

class ListaPersona():
    
    # Create list
    lstPersona = []
    
    # Create constructor
    def __init__(self) -> None: 
        FicheroListaPersona = open("FicheroListaPersona", "ab+")
        FicheroListaPersona.seek(0)
        
        try:
            self.lstPersona = pickle.load(FicheroListaPersona)
            FicheroListaPersona.close()
            print("Se cargaron {} personas del fichero externo".format(len(self.lstPersona)))
        except:
            print("El fichero externo no existe")
        finally:
            FicheroListaPersona.close()
            del(FicheroListaPersona)
        
    # Add persona to list
    def agregarPersona(self, pPersona) -> None:
        self.lstPersona.append(pPersona)
        self.SavePersonaInFicheroExterno()
        
    # Read persona from list
    def leerPersona(self):
        for p in self.lstPersona:
            print(p)

    # 
    def SavePersonaInFicheroExterno(self):
        FicheroListaPersona = open("FicheroListaPersona", "wb")
        
        pickle.dump(self.lstPersona, FicheroListaPersona)
        FicheroListaPersona.close()
        del(FicheroListaPersona)

    # Read persona from Fichero Externo
    def ReadPersonaFromFichero(self):
        for p in self.lstPersona:
            print(p)
            
# ############################################################  
# Execution
# ############################################################

"""
myPersonList = ListaPersona()

varPersona = Persona("Lucas", "Masculino", "42")
myPersonList.agregarPersona(varPersona)

varPersona = Persona("Daina", "Femenino", "33")
myPersonList.agregarPersona(varPersona)

varPersona = Persona("Cecilia", "Femenino", "73")
myPersonList.agregarPersona(varPersona)

myPersonList.leerPersona()
"""

myPersonList = ListaPersona()
varPersona = Persona("Marta", "Femenino", "20")
myPersonList.agregarPersona(varPersona)
myPersonList.ReadPersonaFromFichero() 
