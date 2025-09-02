.option norvc



# Macro files
.include "MACRO.S"


.section .data

welcome: .ascii "Welcome to testos\n\0"
iamhart: .ascii "I am HART \0"
newline: .ascii "\n\0"
tablespace: .ascii "      \0"
trapwarning: .ascii "WARNING!\0"
twisset: .ascii "TW bit is set!\0"

smode_trapwarning: .ascii "S-Mode Trap!"
supervisormodeentry: .ascii "Entering Supervisor Mode\0"

mpp_mmode: .ascii "MPP Mode: Machine \0"
mpp_smode: .ascii "MPP Mode: Supervisor \0"
interrupts_status: .ascii "Interrupts:\0"

data_section_address: .ascii "Data: \0"
write_uart_address: .ascii "Uart: \0"


walkingpagetables: .ascii "Walking Page Tables...\0"
endwalkingpagetables: .ascii "Walking Page Tables Complete\0"


pcidevices: .ascii "PCI Devices\0"
pcivendorid: .ascii "Vendor\0"
pcideviceid: .ascii "Device\0"
tableheader: .ascii "--------------------------------\0"

setup_qemu_pci_bridge: .ascii "Identified QEMU PCI Bridge...\0"
setup_qemu_vga: .ascii "Setting Up QEMU VGA...\0"


#machninemode: .ascii "Mode: Machine \0"
#interrupts_on: .ascii "Interrupts: "

hextable: .ascii "0123456789ABCDEF"

_lock: 
    .skip 8,0  # 1 word


_temp_memory:
    .skip 1024,0  # 1024 words

.align 12
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
  

    call _debug_misa        # subroutine to check details of the ISA in the MISA register

    call _sanity_check      # Perform a sanity check to see if the registers have the same state


    la t0, _machine_trap    # Load the subroutine to trigger a machine trap
    csrw mtvec, t0          # Laod the data of the machine trap to the machine vector
    
    la t0, _supervisor_trap # Load the subroutine to trigger a supervisor trap
    csrw stvec, t0          # Load the data of the supervisor trap to the supervisor vector

    li t0, 0xFFFFFFFF       # Bits used to send which region to allow for supervisor mode entry
    csrw pmpaddr0, t0       # loading the data to the PMP address
    li t0, 0x1F             # Configuration allowing Read (R), Write (W), and execute(X) on the allocated address
    csrw pmpcfg0, t0        # Load configuration to PMPCFG0

    csrr t0, mstatus            # Load the status register
    li t1, 0xFFFFFFFFFFFFE7FF   # Bits to clear the MPP bit
    and t1, t0, t1              # Clear the MPP bit by setting it to User mode
    li t2, 0x0800               # Bits to switch to supervisor mode
    or t1, t1, t2               # Set MPP to supervisor mode
    csrw mstatus, t1            # Write the MPP value to the status register


    call _sanity_check      # subroutine to read the status on all registers 

    call _setup_satp        # subroutine to setup SATP register
    
    #csrr a0, satp
    #call _print_hex

    #la a0, _exemple_page
    #call _print_hex

    # String address of Supervisor
    la a0, _data_start  
    call _print_hex

    call _setup_PCI

    # Identity map data for both virtual and physical pages
    la a0, _data_start
    la a1, _data_start
    li a2, 0x07
    call _map_to_virtual

    # Identity map for functions for both virtual and physical pages
    la a0, _stacks
    la a1, _stacks
    li a2, 0x0F
    call _map_to_virtual

    # Identity map for the UART ports
    li a0, 0x10000000
    li a1, 0x10000000
    li a2, 0x0F
    call _map_to_virtual

    # Identity map for the UART functions
    la a0, _write_uart
    la a1, _write_uart
    li a2, 0x0F
    call _map_to_virtual

    # virtual map of an example page
    la a0, _exemple_page
    la a1, _exemple_page
    li a2, 0x0F
    call _map_to_virtual

    la a0, walkingpagetables
    call _write_newline

    la a0, _page_table_start
    li a1, 2
    call _walk_page_tables

    la a0, endwalkingpagetables
    call _write_newline

    call _setup_PCI

    la t0, _exemple_page
    csrw mepc, t0
    mret



    #j _announce
    
    wfi


.include "PAGE.S"
.include "UART.S"
.include "PCI.S"
.include "HEX.S"
.include "VGA.S"

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


_supervisor_trap:
    la a0, smode_trapwarning
    call _write_uart

    csrr t0, mcause
    li t1, 0x30
    add t0, t0, t1

    la a0, _temp_memory

    sb t0, 0(a0)
    call _write_newline
    wfi

_machine_trap:
    la a0, trapwarning
    call _write_uart

    csrr a0, mcause
    call _print_hex
    wfi



_sanity_check:
    push ra
    csrr t0, mstatus                        # Load the mstatus information to t0
    
    #li t1, 0xC00                            # Set the hart to machine mode
    #and t0, t1, t2                          # Check if the interrupt is enabled
    #beq t1, t2, _sanity_check_interrupts    # if result is equal, check for interrupts
    #la a0, machninemode                     # Load machine mode string to a0
    
    srai t0, t0, 11                         # Shift to the right to read the MPP bits located in mstatus
    li t1, 0x3                              # Bit mask to read both bits
    and t2, t0, t1                          # Check if both bits are acive
    bne t1, t2, _sanity_check_smode         # if it is, jump to check if it is smode
    la a0, mpp_mmode                        # Load text to show that it is in M mode
    call _write_newline                     # Call write new line

_sanity_check_smode:
    csrr t0, mstatus                # load the mstatus information to t0
    srai t0, t0, 11                 # Shift to the right to read the MPP bits located in mstatus
    li t1, 0x3                      # Bit mask to read both bits
    and t2, t0, t1                  # Check if bit number 3 is active
    li t1, 0x1                      # Load the number 0x10 to check if S mode is active
    bne t1, t2, _sanity_check_tw    # Jump to check timeout wait (TW) bit in M status
    la a0, mpp_smode                # load text to show that you are in S mode
    call _write_newline             # Call write new line

_sanity_check_tw:
    csrr t0, mstatus                        # load the mstatus information to t0
    li t1, 0x100000                         # Load the location of the TW bit
    and t2, t0, t1                          # Check the value of the TW bit
    bne t1, t2, _sanity_check_interrupts    # Branch to check for interrupts
    la a0, twisset                          # Load text to show information of the TW bit
    call _write_newline




_sanity_check_interrupts:
    csrr t0, mstatus                # Load the mstatus information to t0,
    li t1, 0x8                      # Load status bit for interrupts
    and t0, t1, t2                  # Check if the interrupt is enabled
    la a0, interrupts_status        # Load machine mode string to a0
    call _write_uart                # Call UART subroutine
    
    li t3, 0x30             # Load the address value for the machine status register to t2
    srai t2, t2, 3          # shift arithmetically to the right 
    add t1, t2, t3          # add the statusID of the HARTs to t1
    la a0, _temp_memory     # Address of memory loaded to a0
    sb t1, 0(a0)            # store Hardware IDs from t1 to the address of a0       
    call _write_newline     # Call function to print and add new line



_sanity_check_end: 
    pop ra
    ret




_debug_misa:    # Debugging misa register that stores data regarding the ISA supported 
    push ra
    csrr t0, misa 
    li t1, 26  # load the number of extensions located in the misa register
    li t2, 0   # Counter
    li t3, 1   # Mask

    _debug_misa_extension_start:
    and t4, t0, t3
    beqz t4, _debug_misa_extension_inc
    
    li t4, 0x41  # Load the Ascii value of "A"
    add t4, t4, t2  # Load the location of the Atomic extension which is 0 in the MISA register

    la a0, _temp_memory  # Load the allocated RAM to a0
    sb t4, 0(a0)         # Store the ASII value to RAM
    
    push t0
    push t1
    push t2
    push t3
    call _write_uart
    pop t3
    pop t2
    pop t1
    pop t0


    _debug_misa_extension_inc:
    srai t0, t0, 1  # Value of the MISA register shifted to the right 
    add t2, t2, t3 

    bne t1, t2, _debug_misa_extension_start
    
    la a0, newline
    call _write_uart
    pop ra
    ret
    
_wait:
    wfi # wait for interrupt

_print_hex:
    push ra
    li a1, 15       # Length of a hex value in bits which is 16 bits

_print_hex_loop:
    li t4, 4        # Hex mask due to 4 bits -> 1 hex digit
    mul t4, a1, t4  # Multiply the mast with 15 to get 64 bits
    sra a2, a0, t4  # Shift the value in a0 with the t4 steps
    li t1, 0x0F
    and t1, a2, t1  # Perform logical AND with the value and 0x0F
    la t2, hextable # Load the hextable 
    push a0
    push a1
    add a0, t1, t2          
    call _write_uart_char
    pop a1
    pop a0
    li t1, -1
    add a1, a1, t1
    bgez a1, _print_hex_loop
    la a0, newline
    call _write_uart
    pop ra 
    ret


_kalloc: 
    la a1, _heap_counter
    ld t0, 0(a1)            # Load the heap counter defined in the linker file

    li t1, 1
    add t0, t0, t1
    sd t0, 0(a1)            # Incremeant the counter to allocate the pages

    la t1, _heap_end        # Locate the current position of the end of the heap
    li t2, 4096             # The end of the heap is located at 4096 from the end of memory
    mul t2, t0, t2          # Multiply the heap location with the total amount of heaps
    sub a0, t1, t2          # Subtract the total amount of heaps with the end of the heap to store in the pages
    ret

.align 12

_exemple_page:
    la a0, supervisormodeentry
    call _write_uart
    la a0, _page_table_start
    ld a0, 0(a0)
    wfi
    .skip 4096

.align 12
_page_table_start:
    .skip 4096
