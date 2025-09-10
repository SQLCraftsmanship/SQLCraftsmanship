
def sumar(*arg):
    varTotal = arg[0]

    for value in arg[1:]:
        print('Esto es varTotal: ', varTotal)
        print('Esto es value: ', value)
        varTotal += value
    return varTotal

def restar(*arg):
    varTotal = arg[0]
    
    for value in arg[1:]:
        varTotal -= value
    return varTotal


def multiplicar(*arg):
    varTotal = arg[0]
    
    for value in arg[1:]:
        varTotal *= value
    return varTotal
        

def dividir(arg1, arg2):
    return arg1 / arg2
