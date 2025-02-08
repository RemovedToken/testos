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
# PTE -> a + VA.VPN[i]*PTESIZE, PTE: Page Tabel Entry
# If VA = 0x00_0000_0000
# PTE = a + VA.VPN[2]*PTESIZE due to VA.VPN[2] = 0
# The first entry is located on PTE -> Add an entry on the page table
# Register usage
# a0: Virtual Page
# a1: Physical Page
# a2: Read/write/Execute bits
_map_to_virtual:    
    push ra



    
    srli a0, a0, 30     # Finding the PTE of the VA.VPN[2]
    li t0, 8            # Space of VA.VPN[2] is 8 bits
    mul a0, a0, t0      # Register a0 is now VA.VPN[2] 8 bits long

    la t0, _page_table_start
    add a0, t0, t0              # Adding the start of the page table of each declared page: i.e SATP.PPN *4096


    push a0
    push a1
    push a2
    call _zalloc              # Perform the allocation of the heaps
    mv a4, a0                 # The new virtual page to be allocated 
    pop a2
    pop a1
    pop a0

    srli a5, a4, 2            
    li t0, 1
    or a5, a5, t0
    sd a5, 0(a0)

    push a0
    push a1
    push a2
    push a4
    call _zalloc
    mv a5, a0
    pop a4
    pop a2
    pop a1
    pop a0

    srli a6, a5, 2
    li t0, 1
    or a6, a6, t0
    sd a6, 0(a4)

    srli a1, a1, 2
    or a1, a1, a2
    sd a1, 0(a5)
    pop ra
    ret

