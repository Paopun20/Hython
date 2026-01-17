# Turtle Graphics in Hython

Hython now supports turtle graphics! The `Turtle` class provides a Python-compatible turtle graphics interface for drawing graphics.

## Creating a Turtle

```python
# Create a turtle at the origin (0, 0)
t = Turtle()

# Create a turtle at a specific position
t = Turtle(100, 50)
```

## Movement Methods

### `forward(distance)` / `fd(distance)`
Move the turtle forward by the specified distance.

```python
t.forward(100)  # Move forward 100 units
t.fd(50)        # Alias for forward
```

### `backward(distance)` / `bk(distance)`
Move the turtle backward by the specified distance.

```python
t.backward(100)  # Move backward 100 units
t.bk(50)         # Alias for backward
```

### `right(angle)` / `rt(angle)`
Turn the turtle right (clockwise) by the specified angle in degrees.

```python
t.right(90)   # Turn right 90 degrees
t.rt(45)      # Alias for right
```

### `left(angle)` / `lt(angle)`
Turn the turtle left (counter-clockwise) by the specified angle in degrees.

```python
t.left(90)    # Turn left 90 degrees
t.lt(45)      # Alias for left
```

### `goto(x, y)` / `setpos(x, y)` / `setposition(x, y)`
Move the turtle to the specified coordinates.

```python
t.goto(100, 50)
t.setpos(0, 0)
t.setposition(200, 100)
```

### `setX(x)` / `setY(y)`
Set only the X or Y coordinate while keeping the other the same.

```python
t.setX(100)  # Move to x=100, keep y the same
t.setY(50)   # Move to y=50, keep x the same
```

### `home()`
Return the turtle to the origin (0, 0) and set heading to 0 (east).

```python
t.home()
```

## Heading Methods

### `setHeading(angle)` / `seth(angle)`
Set the turtle's heading (direction) in degrees. 0 = east, 90 = north.

```python
t.setHeading(0)    # Face east
t.seth(90)         # Face north
t.setHeading(180)  # Face west
```

### `getHeading()`
Get the turtle's current heading in degrees.

```python
heading = t.getHeading()
print("Current heading:", heading)
```

## Pen Control Methods

### `penup()` / `pu()`
Lift the pen up (stop drawing lines).

```python
t.penup()
t.pu()
```

### `pendown()` / `pd()`
Put the pen down (start drawing lines).

```python
t.pendown()
t.pd()
```

### `isdown()`
Check if the pen is currently down.

```python
if t.isdown():
    print("Pen is down")
```

## Pen Customization

### `setPenColor(color)`
Set the pen's drawing color.

```python
t.setPenColor("red")
t.setPenColor("blue")
t.setPenColor("black")
```

### `setPenSize(size)`
Set the pen's line width.

```python
t.setPenSize(1)    # Thin line
t.setPenSize(5)    # Thicker line
```

### `setFillColor(color)`
Set the color for filled shapes.

```python
t.setFillColor("yellow")
```

## Drawing Shapes

### `circle(radius, extent=360)`
Draw a circle with the specified radius. The optional `extent` parameter draws only part of a circle (in degrees).

```python
t.circle(50)        # Draw a full circle with radius 50
t.circle(50, 180)   # Draw a semicircle
t.circle(50, 90)    # Draw a quarter circle
```

### `dot(size=-1, color=None)`
Draw a dot at the current position.

```python
t.dot()              # Draw with default size and pen color
t.dot(10)            # Draw with size 10
t.dot(10, "red")     # Draw with size 10 in red
```

## Position Query Methods

### `position()` / `pos()`
Get the turtle's current position as `[x, y]`.

```python
pos = t.position()
print("Position:", pos)
```

### `xcor()`
Get the turtle's X coordinate.

```python
x = t.xcor()
print("X position:", x)
```

### `ycor()`
Get the turtle's Y coordinate.

```python
y = t.ycor()
print("Y position:", y)
```

## Distance and Angle Calculation

### `distance(x, y)`
Calculate the distance from the turtle's current position to the specified point.

```python
dist = t.distance(100, 100)
print("Distance:", dist)
```

### `towards(x, y)`
Calculate the angle (heading) needed to point towards the specified point.

```python
angle = t.towards(100, 100)
print("Angle towards:", angle)
```

## Visibility

### `showturtle()` / `st()`
Make the turtle visible.

```python
t.showturtle()
t.st()
```

### `hideturtle()` / `ht()`
Hide the turtle.

```python
t.hideturtle()
t.ht()
```

### `isvisible()`
Check if the turtle is currently visible.

```python
if t.isvisible():
    print("Turtle is visible")
```

## Clearing and Resetting

### `clear()`
Clear all drawing commands (erases all drawings) but keeps the turtle's state.

```python
t.clear()
```

### `reset()`
Reset the turtle to its initial state (clears drawings, resets position, heading, pen, etc.).

```python
t.reset()
```

## Properties

The Turtle class has several accessible properties:

- `x` - Current X coordinate
- `y` - Current Y coordinate
- `heading` - Current heading in degrees
- `penDown` - Whether the pen is down (drawing)
- `penColor` - Current pen color
- `penSize` - Current pen width
- `fillColor` - Current fill color
- `visible` - Whether the turtle is visible
- `speed` - Drawing speed (0-10, 0 = instant)
- `commands` - Array of drawing commands (for rendering)

```python
t.x = 50          # Set X position
t.y = 100         # Set Y position
print(t.penColor) # Get pen color
```

## Examples

### Draw a Square

```python
t = Turtle()
for i in range(4):
    t.forward(100)
    t.right(90)
```

### Draw a Star

```python
t = Turtle()
t.setPenColor("yellow")
for i in range(5):
    t.forward(100)
    t.right(144)
```

### Draw Concentric Circles

```python
t = Turtle()
for i in range(1, 6):
    t.circle(i * 20)
    t.forward(5)
```

### Draw with Multiple Colors

```python
t = Turtle()
colors = ["red", "blue", "green", "yellow", "purple"]

for i in range(5):
    t.setPenColor(colors[i])
    t.forward(100)
    t.right(72)
```

## Drawing Commands History

The `commands` property stores all drawing operations as a list of command objects. Each command has properties like `type`, `x1`, `y1`, `x2`, `y2`, `color`, and `width`. This can be used for rendering the graphics in your Haxe application:

```python
t = Turtle()
t.forward(100)
t.right(90)
t.forward(100)

# Get all drawing commands
for cmd in t.commands:
    print("Command:", cmd)
```

## Notes

- The turtle starts at position (0, 0) facing east (heading 0°)
- Angles are measured in degrees, with 0° pointing east, 90° pointing north
- The pen is initially down, so drawing occurs by default
- Drawing commands are stored for later rendering in your Haxe application
