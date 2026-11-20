# Paint Program
# MustyV Playground - RISC-V
# Left click = Paint
# F = Draw filled circle
# Keys 1-9 = Change color
# L = Clear screen
# WASD = Move cursor
# Space = Paint with cursor

.equ FB,      0x20000000
.equ PRESENT, 0x21001008
.equ CLEAR,   0x2100100C
.equ DEV,     0x40000000
.equ KEY,     0x28
.equ KEYHIT,  0x2C
.equ MX,      0x30
.equ MY,      0x34
.equ MBTN,    0x38
.equ W,       128
.equ H,       96

.text
main:
    li s0, DEV
    li s1, 2              # starting color = red
    li s2, 0              # cursor X
    li s3, 0              # cursor Y

loop:
    lw s4, MX(s0)         # mouse X
    lw s5, MY(s0)         # mouse Y
    lw t2, MBTN(s0)       # mouse buttons

    # Left click paints pixel
    andi t3, t2, 1
    beqz t3, keyboard

    li t4, W
    bgeu s4, t4, keyboard

    li t4, H
    bgeu s5, t4, keyboard

    li t3, W
    mul t3, s5, t3        # y * width
    add t3, t3, s4        # + x

    li t4, FB
    add t3, t3, t4

    sb s1, 0(t3)          # draw pixel
    j keyboard


# Add-on 1: F draws filled circle
# Circle radius = 15 pixels

drawCircle:
    li t5, -15            # Y offset

circleRow:
    li t6, 15
    bgt t5, t6, show

    li a3, -15            # X offset

circleCol:
    li t6, 15
    bgt a3, t6, nextRow

    # Check x^2 + y^2 <= 225
    mul a0, a3, a3
    mul a1, t5, t5
    add a0, a0, a1

    li t6, 225
    bgt a0, t6, skipPixel

    # Calculate pixel coordinates
    add a0, s4, a3
    add a1, s5, t5

    # Check screen boundaries
    li t6, W
    bgeu a0, t6, skipPixel

    li t6, H
    bgeu a1, t6, skipPixel

    # Calculate framebuffer address
    li a2, W
    mul a2, a1, a2
    add a2, a2, a0

    li t6, FB
    add a2, a2, t6

    sb s1, 0(a2)          # draw circle pixel

skipPixel:
    addi a3, a3, 1
    j circleCol

nextRow:
    addi t5, t5, 1
    j circleRow


# Keyboard input
# KEYHIT reads a new key press

keyboard:
    lw t0, KEYHIT(s0)

    # F key draws circle
    li t1, 102            # lowercase f
    beq t0, t1, drawCircle

    li t1, 70             # uppercase F
    beq t0, t1, drawCircle

    # L key clears screen
    li t1, 8            # backspace
    beq t0, t1, reset

    # Keys 1-9 change paint color
    li t1, 49             # ASCII '1'
    blt t0, t1, checkMove

    li t1, 57             # ASCII '9'
    bgt t0, t1, checkMove

    addi s1, t0, -48      # convert ASCII to color


# WASD uses currently held key

checkMove:
    lw t0, KEY(s0)

    li t1, 119            # W
    beq t0, t1, moveUp

    li t1, 97             # A
    beq t0, t1, moveLeft

    li t1, 115            # S
    beq t0, t1, moveDown

    li t1, 100            # D
    beq t0, t1, moveRight

    li t1, 32             # Space
    beq t0, t1, paintKey

    j show


# Move cursor up

moveUp:
    beqz s3, show
    addi s3, s3, -1
    j show


# Move cursor left

moveLeft:
    beqz s2, show
    addi s2, s2, -1
    j show


# Move cursor down

moveDown:
    li t1, 95
    bge s3, t1, show

    addi s3, s3, 1
    j show


# Move cursor right

moveRight:
    li t1, 127
    bge s2, t1, show

    addi s2, s2, 1
    j show


# Spacebar paints pixel

paintKey:
    li t1, W
    mul t2, s3, t1        # cursor Y * width
    add t2, t2, s2        # + cursor X

    li t3, FB
    add t2, t2, t3

    sb s1, 0(t2)
    j show


# Add-on 2: L clears screen

reset:
    li t1, CLEAR
    sw zero, 0(t1)        # clear to black
    j show


# Update the screen

show:
    li t0, PRESENT
    sw t0, 0(t0)

    j loop
