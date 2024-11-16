.option norvc
.section .data

welcome: .ascii "Welcome to testos\n\0"
iamhart: .ascii "I am HART \0"
newline: .ascii "\n\0"
machninemode: .ascii "Mode: Machine \0"
interrupts_on: .ascii "interrupts: "

_lock: 
    .skip 8,0  # 1 word


_temp_memory:
    .skip 1024,0  # 1024 words


_stacks:
    .skip 8192, 0 # Creating a dedicated stack memory 

.section .text.init
.global _start



_start:
    # Making all harts except 0 to wait. 

    csrr t0, mhartid        # Get the hardware id
    la t1, _stacks          # Load stack size to t1 
    li t2, 1024             # load stack value to 42
    mul t3, t2, t0          # distribute allocate stack space based on the available hardware threads
    add sp, t3, t1          # load space value to stackpointer 

    bnez t0, _announce      # Branch to _announce if the hardware ID is not equal to 0


    # Setup UART + print welcome message
    call _setup_uart        # Call the Setup uart function
    la a0, welcome          # Load a0 with the address of welcome
    call _write_uart        # call the _write_uart function

    call _sanity_check

    j _announce
    
    wfi


.macro push
    sd ra, 0(sp)    # Save address to stackpointer
    li t0, 8        # allocate 8 words of space to t0 
    add sp, sp, t0  # add space to the stack pointer

.endm

.macro pop
    li t0, -8        # Remove allocated 8 words 
    add sp, sp, t0 # Add the negative space to the stack pointer
    ld ra, 0(sp)

.endm

_sanity_check:
    push
    csrr t0, mstatus                        # Load the mstatus information to t0
    li t1, 0xC00                            # Set the hart to machine mode
    and t0, t1, t2                          # Check if the interrupt is enabled
    beq t1, t2, _sanity_check_interrupts    # if result is equal, check for interrupts
    la a0, machninemode                     # Load machine mode string to a0
    call _write_newline                     # Call write new line


_sanity_check_interrupts:
    csrr t0, mstatus                # Load the mstatus information to t0,
    li t1, 0x8                      # Load status bit for interrupts
    and t0, t1, t2                  # Check if the interrupt is enabled
    la a0, interrupts_on            # Load machine mode string to a0
    call _write_uart                # Call UART subroutine
    
    li t3, 0x30             # Load the address value for the machine status register to t2
    srai t2, t2, 3          # shift arithmetically to the right 
    add t1, t2, t3          # add the statusID of the HARTs to t1
    la a0, _temp_memory     # Address of memory loaded to a0
    sb t1, 0(a0)            # store Hardware IDs from t1 to the address of a0       
    call _write_newline     # Call function to print and add new line



_sanity_check_end: 
    pop
    ret



_write_newline:
    push
    call _write_uart
    la a0, newline
    call _write_uart
    pop
    ret


_setup_uart:
    li t1, 0x10000001       # Access interrupt register on UART + 1  
    sb x0, 0(t1)            # Disable the interrupts on the UART
    li t1, 0x10000003       # Access line control with the UART address + 3 
    li t2, 0x03             # Configure the UART to 8 bits no parity 
    ret                     # Return to _start 


_write_uart:
    push

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
    pop
    ret                         # Return to _start


# Function for all HARTs to announce themselves
_announce:

    fence                   # Force all threads to execute the instructions in the programmed order

    la t0, _lock            # Load the address of the dedicated lock memory to t0
    lw t0, 0(t0)            # load the value stored in the address of t0 and t0 
    csrr t1, mhartid        # Get the hardware ID 
    bne t0, t1, _announce   # Branch back to announce if the hardware ID is not 0   

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
    lw t1, 0(t0)            # Load t1 with the value stored in the address of t0  

    fence

    j _wait                 # wait for interrupt 
    

_wait:
    wfi # wait for interrupt
