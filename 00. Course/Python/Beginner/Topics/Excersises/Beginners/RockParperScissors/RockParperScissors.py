"""
# Script Name: RockParperSicissors
# Date       : 10/26
# Function   : Create an ap to play RockParperSicissors
# Owner      : LLI
"""

# ===========================================================
# Import section
# ===========================================================
import random


# ===========================================================
# Var section
# ===========================================================


# ===========================================================
# Class section
# ===========================================================
def f_RockPaperScissors():
    varUserWins = 0
    varComputeWins = 0

    varOptions = ['rock', 'paper', 'scissors']

    try:
        while True:
            varUserInput = input("Type Rock/Paper/Scissors or Q to quiet: ").lower()
            
            if varUserInput == 'q':
                break
            
            if varUserInput not in varOptions:
                continue
            
            # Random a number between 0 and 2. This is going to be the 
            # INDEX of the list (varOptions[]) 
            # 0: Rock 1: Paper 2: Scissors
            varRandomNumber = random.randint(0, 2)

            # Select ['Rock', 'Paper', 'Scissors'] depend on the random 
            # number Index
            varComputerInput = varOptions[varRandomNumber]
            
            print(f"Computer picked {varComputerInput}.")

            # Defined a winner
            if (varUserInput == "rock") and (varComputerInput == 'scissors'):
                print("You won!!")
                varUserWins += 1
            elif (varUserInput == "paper") and (varComputerInput == 'rock'):
                print("You won!!")
                varUserWins += 1
            elif (varUserInput == "scissors") and (varComputerInput == 'paper'):
                print("You won!!")
                varUserWins += 1
            else:
                print("You lost!!")
                varComputeWins += 1
    except Exception as e:
        print(f"Caught an exception: {e}")

    print(f"You won {varUserWins}, times.")
    print(f"You lost {varComputeWins}, times.") 
    print(f"Goodbye!!")

 
# ===========================================================
# Main section
# ===========================================================
f_RockPaperScissors()
