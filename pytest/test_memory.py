# Memory test - create large lists
data = []
for i in range(10000):
    data.append(i * 2)
print(len(data))
