.option norvc
.section .data

welcome: .ascii "Welcome to testos\n\0"
iamhart: .ascii "I am HART \0"
newline: .ascii "\n\0"

_lock: 
    .skip 1,0  # 1 word


_temp_memory:
    .skip 1024,0  # 1024 words

.section .text.init
.global _start



_start:
    # Making all harts except 0 to wait. 

    csrr t0, mhartid        # Get the hardware id  
    bnez t0, _announce      # Branch to _announce if the hardware ID is not equal to 0

    # Setup UART + print welcome message
    call _setup_uart        # Call the Setup uart function
    la a0, welcome          # Load a0 with the address of welcome
    call _write_uart        # call the _write_uart function
    j _announce
    wfi



_write_newline:
    mv s0, ra
    call _write_uart
    la a0, newline
    call _write_uart
    mv ra, s0
    ret


_setup_uart:
    li t1, 0x10000001       # Access interrupt register on UART + 1  
    sb x0, 0(t1)            # Disable the interrupts on the UART
    li t1, 0x10000003       # Access line control with the UART address + 3 
    li t2, 0x03             # Configure the UART to 8 bits no parity 
    ret                     # Return to _start 


_write_uart:
    li t1, 0x10000000           # Load the UART address 
    lb t2, 0(a0)                # Load t2 with the byte in reg. a0
    beqz t2, _write_uart_end    # Jump to end when t2 is empty
    sb t2, 0(t1)                # Store the byte in t2 to the address of t1
    addi a0, a0, 1              # Incremeant the address in a0 with 1 
    j _write_uart               # Jump to the start of _write_uart

_write_uart_end:
    ret                         # Return to _start


# Function for all HARTs to announce themselves
_announce: 
    fence
    la t0, _lock
    lw t0, 0(t0)
    csrr t1, mhartid
    bne t0, t1, _announce 

    # Announce which hart ID
    la a0, iamhart
    call _write_uart


    csrr t1, mhartid        # Get the HARTID
    li t2, 0x30             # Load the address value for the machine status register to t2
    add t1, t2, t1          # add the statusID of the HARTs to t1
    la a0, _temp_memory     # Address of memory loaded to a0
    sb t1, 0(a0)            # store Hardware IDs from t1 to the address of a0       
    call _write_newline     # Call function to print and add new line
    
    
    # Incremeant of _lock
    csrr t0, mhartid        # Get the current HartID
    li t1, 0x01             # Load t1 with the value of 1
    add t1, t0, t1          # Incremeant t0 with 1
    la t2, _lock            # load t2 with address of _lock
    sw t1, 0(t2)            # store value of t1 to address of t2
    la t0, _lock            # Load t0 with the address of lock
    lw t1, 0(t0)            # Load t1 with the  

    fence

    j _wait                 # wait for interrupt 
    

_wait:
    wfi # wait for interrupt
