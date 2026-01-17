# Advanced Turtle Graphics Examples

# Example 1: Draw a Colorful Star
def draw_star(turtle, size, color):
    turtle.setPenColor(color)
    for i in range(5):
        turtle.forward(size)
        turtle.right(144)

t = Turtle()
draw_star(t, 100, "red")
print("Star created!")

# Example 2: Spiral Pattern
def draw_spiral(turtle, turns=20, start_length=5, increment=2):
    for i in range(turns):
        length = start_length + (i * increment)
        turtle.forward(length)
        turtle.right(15)

t2 = Turtle(-100, 0)
t2.setPenColor("blue")
draw_spiral(t2)
print("Spiral created!")

# Example 3: Nested Squares
def draw_nested_squares(turtle, num_squares, size, color_list):
    for i in range(num_squares):
        turtle.setPenColor(color_list[i % len(color_list)])
        for j in range(4):
            turtle.forward(size)
            turtle.right(90)
        size += 20
        turtle.forward(10)

t3 = Turtle()
colors = ["red", "blue", "green", "yellow", "purple"]
draw_nested_squares(t3, 5, 50, colors)
print("Nested squares created!")

# Example 4: Polygon Generator
def draw_polygon(turtle, sides, length, color):
    turtle.setPenColor(color)
    angle = 360 / sides
    for i in range(sides):
        turtle.forward(length)
        turtle.right(angle)

t4 = Turtle(200, 0)
# Draw multiple polygons
for sides in range(3, 8):
    draw_polygon(t4, sides, 60, "green")
    t4.penup()
    t4.forward(30)
    t4.pendown()

print("Polygons created!")

# Example 5: Get Drawing Information
t5 = Turtle()
t5.forward(100)
t5.right(90)
t5.forward(50)

print("Final Position:", t5.position())
print("Current Heading:", t5.getHeading())
print("X Coordinate:", t5.xcor())
print("Y Coordinate:", t5.ycor())
print("Distance to origin:", t5.distance(0, 0))
print("Angle to (100, 100):", t5.towards(100, 100))
print("Total commands:", len(t5.commands))

# Example 6: Turtle with Pen Control
t6 = Turtle()
t6.setPenColor("red")
t6.setPenSize(2)

for i in range(8):
    t6.forward(50)
    t6.penup()
    t6.forward(10)
    t6.pendown()
    t6.right(45)

print("Draw with pen control completed!")

# Example 7: Reset and Clear
t7 = Turtle(50, 50)
t7.circle(30)
print("Circle drawn, commands:", len(t7.commands))

t7.clear()
print("After clear, commands:", len(t7.commands))

t7.forward(100)
print("After forward, commands:", len(t7.commands))

t7.reset()
print("After reset - Position:", t7.position(), "Commands:", len(t7.commands))
