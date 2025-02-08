# Function to setup the supervisor address translation and protection (SATP) register

_setup_satp:
    li t0, 8                        # Value to set for Page-based 39-bit virtual addressing
    slli t0, t0, 60                 # Shift 60 steps to the left to encode the MODE field
    la t1, _page_table_start        # Starting point of the page table
    srai t1, t1, 12                 # Dividing the physical address by 4096
    or t0, t0, t1                   # Setting the 44 bits to the physical page number of the root page table
    csrw satp, t0                   # Write to the SATP register
    ret



# Translating VA -> PA
# PTESIZE = 8, LEVELS = 3, PAGESIZE = 2^12
# Virtual address (VA) -> VPN[2], VPN[1], VPN[0], page offset
# a -> SATP[PPN] * PAGESIZE, a: Physical address of the page
# PTE -> a + VA.VPN[i]*PTESIZE, PTE: Page Table Entry
# If VA = 0x00_0000_0000
# PTE = a + VA.VPN[2]*PTESIZE due to VA.VPN[2] = 0
# The first entry is located on PTE -> Add an entry on the page table
# Register usage
# a0: Virtual Page
# a1: Physical Page
# a2: Read/write/Execute bits
_map_to_virtual:    
    push ra

    # Calculate the first PTE fo the VA
    # Virtual addresses that are to be calculated: VPN[2], VPN[1], and VPN[0]


    srli t0, a0, 12    # Location of VPN[0] 
    li t1, 0x1FF       # Fill the field in VPN[0]
    and t2, t0, t1     # Allocate the bits to VA.VPN[0]
    li t1, 8           # Space of VA.VPN[0] is 8 bits i.3. PTESIZE
    mul t2, t1, t2     # store the offset value of VA.VPN[0]
    push t2


    # Same case for VPN[1]
    srli t0, a0, 21
    li t1, 0x1FF
    and t2, t0, t1
    li t1, 8
    mul t2, t1, t2
    push t2

    # Same case for VPN[2]
    srli t0, a0, 30     
    li t1, 0x1FF        
    and t2, t0, t1      
    li t0, 8            
    mul a0, t2, t1      


    la t0, _page_table_start    # Start location of the page table
    add a0, t0, a0              # Adding the start of the page table of each declared page: i.e SATP.PPN *4096

    # The Physical address of the 2nd level PTE is stored in register a0

    # Since there are 3 levels of PTE we should create the them
    # This is level 1
    
    ld t0, 0(a0)        # Load the PTE created
    li t1, 0x01         # Valid bit to be set
    and t2, t0, t1      # Check if it is set in the current PTE

    srli a4, t0, 10     # Get the Physical page number (PPN) of this entry
    srli a4, a4, 12     # Get the physical address of this PPN

    bnez t2, _map_level_1  # If the valid bit is 0, this means that the PTE is invalid 

    #if the valid bit is 0, create space for the page

    push a0
    push a1
    push a2
    call _kalloc              # Perform the allocation of the heaps
    mv a4, a0                 # The new virtual page to be allocated 
    pop a2
    pop a1
    pop a0

    # Create the PTE entry 
    srli a5, a4, 2      # Get the PPN       
    li t0, 1            # Set the valid bit
    or a5, a5, t0       # PPN | V 
    sd a5, 0(a0)        # store the created entry

_map_level_1:

    # The physical address of the next page table is stored in a4
    pop a0      # register a0 contains VPN[2]


    add a0, a4, a0  # Register a4 has the physical address of the level 1 page

    # Create the first level of the PTE
    ld t0, 0(a0)    
    li t1, 0x01
    and t2, t0, t1 

    srli a4, t0, 10     # The PPN mapped to the PTE entry is only valid if the valid bit is set to 1
    srli a4, a4, 12     # Physical address 

    # if the physical addres is not in A4, allocate space if the valid bit is set to 0
    bnez t2, _map_level_0

    #if the valid bit is 0, create space for the page

    push a0
    push a1
    push a2
    call _kalloc              # Perform the allocation of the heaps
    mv a4, a0                 # The new virtual page to be allocated 
    pop a2
    pop a1
    pop a0

    # Create the PTE entry 
    srli a5, a4, 2      # Get the PPN       
    li t0, 1            # Set the valid bit
    or a5, a5, t0       # PPN | V 
    sd a5, 0(a0)        # store the created entry

_map_level_0:

    pop a0              # VPN[0] offset is in a4

    add a0, a4, a0      # Calculate the physical address of the next PTE

    # register a1 has the physical page address that is to be mapped
    # Pages can be alighed by 4KB meaning we can shift by 2
    
    srli a1, a1, 2  # Shift the physical page addresses by 2
    or a1, a1, a2   # PPN | Permission bits
    sd a1, 0(a0)
    pop ra
    ret
    

_walk_page_tables:
    push ra
    mv t0, a0   # Pointer of the PTE entry
    li t1, 8    # size of PTE in bytes

_walk_page_tables_inner:
    
    li t6, 4088     # check if the PTE is greater than _page_table_start + 504 *
    add t5, a0, t6  # Get the end of the table
    bgt t0, t5, _walk_page_tables_end

    ld t2, 0(t0)    # load the PTE entry
    li t3, 0x01     # Valid bit location
    and t4, t2, t3  # store the valid bit

    add t0, t0, t1  # Add 8 to the PTE pointer

    beqz t4, _walk_page_tables_inner    # If the Valid bit is not set, continue

    push t0
    push t1
    push t2
    push a1
    push a0
    mv a0, t2
    call _print_hex
    pop a0
    pop a1
    pop t2
    pop t1
    pop t0

    # Get the physical address of the next Page table level
    srli t2, t2, 10
    srli t2, t2, 12     # Since the pages are 4K aliged -> we get the physical address


    # if this is the final level of the page table, move to the inner pages
    beqz a1, _walk_page_tables_inner

    push t0
    push t1
    push a1
    push a0
    mv a0, t2
    li t2, 0x1
    sub a1, a1, t2
    call _walk_page_tables      # go to the sub tables 
    pop a0
    pop a1
    pop t1
    pop t0


    j _walk_page_tables_inner

_walk_page_tables_end:
    pop ra
    ret



  
  
