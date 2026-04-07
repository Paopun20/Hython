import math


def fib(n):
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)


def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(math.sqrt(n)) + 1):
        if n % i == 0:
            return False
    return True


total = 0
for i in range(1, 26):
    if is_prime(i):
        total += fib(i)

print(total)
