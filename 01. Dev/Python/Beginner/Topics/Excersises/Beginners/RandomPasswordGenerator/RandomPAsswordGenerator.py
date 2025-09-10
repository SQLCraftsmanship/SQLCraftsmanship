import string
import random

# Generate some characters. If this is not a tuple is going to give an error. IT MUST BE A TUPLE!!
varCharacters = list(string.ascii_letters + string.digits + "!@#$%^&*()")

def f_GeneratePass():
    varPassLength = int(input("How log would you like your password to be? "))
    
    # Mezcla the characters that we have in varPassLength
    print(varCharacters)
    random.shuffle(varCharacters)
    
    # We create a list
    lstPassword = []
    
    # We loop the list
    for x in range(varPassLength):
        lstPassword.append(random.choice(varCharacters))
    
    # We shuffle again
    random.shuffle(lstPassword)
    
    # ???
    lstPassword = "".join(lstPassword)
    
    print (lstPassword)


# ******************************************************************************
# Execute the app
# ******************************************************************************

# Ask for pass
varGenPass = input("Do you want to generate a pass? (Yes/No)")

if (varGenPass == "Yes"):
    f_GeneratePass()
elif (varGenPass == "No"):
    print("Program ended")
    quit()
else:
    print("Please select Yes or No")
    quit()
