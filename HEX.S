_format_hex:
    push ra
    mv t5, a1
    li a1, 15   # Load 64 bit value = 8 bytes = 16 nibbles

_format_hex_loop:
    li t4, 4            # Get the current hex nibble
    mul t4, a1, t4
    sra a2, a0, t4      # Mask created


    # Load the mask
    li t1, 0x0F
    and t1, a2, t1
    la t2, hextable     # Hextable and offset loaded

    add t6, t2, t1
    lb t6, 0(t6)        # ASCII value of Hexdigit


    sb t6, 0(t5)
    addi t5, t5, 1  

    li t1, -1
    add a1, a1, t1
    bgez a1, _format_hex_loop
    pop ra
    ret  
