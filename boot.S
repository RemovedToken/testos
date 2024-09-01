.option norvc
.section .data

welcome: .ascii "Welcome to testos\n\0"

.section .text.init
.global _start

_start:
    csrr t0, mhartid        # Get the hardware id  
    bnez t0, _wait          # Branch to _wait if the hardware ID is not equal to 0
    call _setup_uart        # Call the Setup uart function
    la a0, welcome          # Load a0 with the address of welcome
    call _write_uart        # call the _write_uart function
        

    wfi                     # wait for interrupt 



_setup_uart:
    li t1, 0x10000001   # Access interrupt register on UART + 1  
    sb x0, 0(t1)        # Disable the interrupts on the UART
    li t1, 0x10000003   # Access line control with the UART address + 3 
    li t2, 0x03         # Configure the UART to 8 bits no parity 
    sb t2, 0(t1)        # Store configuration into Line control register
    ret                 # Return to _start 


_write_uart:
    li t1, 0x10000000           # Load the UART address 
    lb t2, 0(a0)                # Load t2 with the byte in reg. a0
    beqz t2, _write_uart_end    # Jump to end when t2 is empty
    sb t2, 0(t1)                # Store the byte in t2 to the address of t1
    addi a0, a0, 1              # Incremeant the address in a0 with 1 
    j _write_uart               # Jump to the start of _write_uart

_write_uart_end:
    ret                         # Return to _start

_wait:
    wfi #wait for interrupt
