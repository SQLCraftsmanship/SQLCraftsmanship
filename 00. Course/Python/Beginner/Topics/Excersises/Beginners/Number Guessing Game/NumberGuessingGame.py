"""
# Script Name: Number Guessing Game
# Date       : 10/26
# Function   : Given a random number guess the number in less than 5 oportunities
# Owner      : LLI
"""

# ===========================================================
# Impor section
# ===========================================================
import random


# ===========================================================
# Class section
# ===========================================================
def f_GuessNumber():
    
    # Imput a number
    var_TopOfRange = input("Please select a number: ")
    
    #region Validate Input
    # Validate that the number is digit
    if var_TopOfRange.isdigit():
        # We have to do this because all value inserted using input are string.
        # But could be "25". So be must convert "25" into 25.
        var_TopOfRange = int(var_TopOfRange)
    
        # Validate that the number is higer than 0
        if var_TopOfRange <= 0:
            print("Please next time insert a value greather tan 0")
            quit()
    else:
        print("Please enter a number next time.")
        quit()
    #endregion Validate Input
            
    # Declare var
    varRandomNumber = random.randint(0, var_TopOfRange)
    varGuesses = 0

    #region While
    # Create a loop while
    while True:
        varGuesses += 1
        
        var_UserGuess = input("Please guess the number: ")
        
        #region Validate Input
        # Validate that the number is digit
        if var_UserGuess.isdigit():
            # We have to do this because all value inserted using input are string.
            # But could be "25". So be must convert "25" into 25.
            var_UserGuess = int(var_UserGuess)
        else:
            print("Please enter a number next time.")
            continue
        #endregion Validate Input
        
        # Validate  if the user guess is the correct one
        if (var_UserGuess == varRandomNumber):
            print("You got it!")
            break
        elif (var_UserGuess > varRandomNumber):
            print("You were above the number!")
        else:
            print("You are below the number!")
    #endregion While
    
    print(f"You got it in {varGuesses} guesses")


# ===========================================================
# Main section
# ===========================================================

f_GuessNumber()
