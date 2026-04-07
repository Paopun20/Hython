def add(a, b):
    print("Inside add, a=" + str(a) + " b=" + str(b))
    c = a + b
    print("c=" + str(c))
    return c


x = add(1, 2)
print("Result: " + str(x))
