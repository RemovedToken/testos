_write_newline:
    push ra
    call _write_uart
    la a0, newline
    call _write_uart
    pop ra
    ret


_setup_uart:
    li t1, 0x10000001       # Access interrupt register on UART + 1  
    sb x0, 0(t1)            # Disable the interrupts on the UART
    li t1, 0x10000003       # Access line control with the UART address + 3 
    li t2, 0x03             # Configure the UART to 8 bits no parity 
    ret                     # Return to _start 

_write_uart_char:
    push ra
    li t1, 0x10000000
    lb t2, 0(a0)
    sb t2, 0(t1)
    pop ra
    ret  

_write_uart:
    push ra

_write_uart_loop:
    li t1, 0x10000005           # Load the UART address and check if it is free 
    lb t2, 0(t1)                # Load t2 with the byte in reg. a0
    li t3, 0x20                 # Load t3 with the ascii value of space
    and t2, t3, t1              # Check if the UART is empty by checking if the ascii value of space is available
    beqz t1, _write_uart_loop   # Jump to end when t2 is empty
    li t1, 0x10000000           # Load the UART address
    lb t2, 0(a0)                # Send data stored in a0 to the address
    beqz t2, _write_uart_end    # Jump to end if there is no data to be written
    sb t2, 0(t1)                # Store the byte in t2 to the address of t1
    li t2, 1
    add a0, t2, a0              # Incremeant the address in a0 with 1 
    j _write_uart_loop          # Jump to the start of _write_uart

_write_uart_end:
    pop ra
    ret                         # Return to _start
