import math

total = 0
for i in range(1, 10001):
    total += int(math.sqrt(i)) + int(math.sin(i) * 100)
print(total)
