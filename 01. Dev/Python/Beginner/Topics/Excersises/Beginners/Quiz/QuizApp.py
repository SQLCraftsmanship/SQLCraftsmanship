
# Create diccionary
dic_Quiz = {
    "Question 1": {
        "question": "What is the capital of Argentina?",
        "answer": "CABA"
    },
    "Question 2": {
        "question": "What is the capital of Ireland?",
        "answer": "Dublin"
    },
    "Question 3": {
        "question": "What is the capital of España?",
        "answer": "Madrid"
    },
    "Question 4": {
        "question": "What is the capital of Italy?",
        "answer": "Rome"
    },
    "Question 5": {
        "question": "What is the capital of Portugal?",
        "answer": "Lisbon"
    },
    "Question 6": {
        "question": "What is the capital of Austria?",
        "answer": "Vienna"
    },
    "Question 7": {
        "question": "What is the capital of Alemania?",
        "answer": "Berlin"
    }    
}

# Set score
varScore = 0

# WARNING
# There is a difference here but I don't understan what is? Look for more information.
#print(dic_Quiz)
#print(dic_Quiz.items())

# Loop the dictionary
for key, value in dic_Quiz.items():
    print(value['question'])
    varAnswer = input("Answe? ")
    
    if varAnswer.lower() == value['answer'].lower():
        print("Correct")
        varScore += 1
        print(f"Your score is: {varScore}\n")
    else:
        print("Wrong")
        print("The correct answer is: ", value['answer'])
        print(f"Your score is: {varScore}\n")

print(f"You responde {varScore} over a 7")
print(f"You have a score of {int(varScore/7*100)} over 100")