# Turtle Graphics Example - Simple Drawing with Hython

# Create a turtle object
turtle = Turtle()

# Set initial properties
turtle.setPenColor("blue")
turtle.setPenSize(2)

# Draw a square
for i in range(4):
    turtle.forward(100)
    turtle.right(90)

# Change pen color and draw a triangle
turtle.setPenColor("red")
turtle.penup()
turtle.goto(200, 0)
turtle.pendown()

for i in range(3):
    turtle.forward(100)
    turtle.left(120)

# Draw a circle
turtle.setPenColor("green")
turtle.penup()
turtle.goto(0, -150)
turtle.pendown()
turtle.circle(50)

# Draw with dots
turtle.setPenColor("purple")
turtle.penup()
turtle.goto(100, -150)
turtle.pendown()
for i in range(8):
    turtle.dot(5, "purple")
    turtle.forward(20)
    turtle.right(45)

# Print drawing commands (this would be used for rendering)
print("Drawing completed!")
print("Total commands:", len(turtle.commands))
