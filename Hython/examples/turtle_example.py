# Turtle Graphics Example for Hython

# Create a new turtle
t = Turtle()

# Draw a square
for i in range(4):
    t.forward(100)
    t.right(90)

# Get turtle position
pos = t.position()
print("Turtle position:", pos)

# Get heading
heading = t.getHeading()
print("Turtle heading:", heading)

# Draw a simple shape with pen color
t.setPenColor("red")
t.penup()
t.goto(0, 100)
t.pendown()

# Draw a triangle
for i in range(3):
    t.forward(80)
    t.left(120)

# Check commands (for rendering)
print("Total drawing commands:", len(t.commands))
