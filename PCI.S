# The PCI express address is located on 0x30000000
# Register a0 will contain the PCIE ECAM address
_list_pci_device: 
    push ra         # Store the return addresses
    li t0, 0        # Load 0

    _iterate_devices:
    li t1, 0
    li t2, 1

    mv a0, t0
    mv a1, t1
    mv a2, x0
    push t0
    push t1
    push t2
    call _read_pci
    call _print_hex
    pop t2
    pop t1
    pop t0

    pop ra
    ret


# We will store: 
# a0: PCI bus
# a1: Device 
# a2: Function
# a3: Offset
_build_PCI_address:
    li t0, 0x40000000
    slli  a0, a0, 16    # Access Bus number
    slli  a1, a1, 11    # Access the device number
    slli  a2, a2, 8     # Access the function number
    add a0, a0, t0      # Store the PCI bus to a0
    add a0, a0, a1      # Store the bus number
    add a0, a0, a2      # Store the device 
    add a0, a0, a3      # Store the offset
    ret

# a0 will store the PCI bus
# a1 will store the PCI device
# a2 will store the offset
_read_pci: 
    push ra
    mv a3, a2               # Store the old offset
    mv a2, x0               # Zero the a2 register
    call _build_PCI_address # start building the address
    
    # Since a0 has the address, it needs to be configured
    li t0, 0xCF8       # Location of the configuration address
    sd a0, 0(t0)       # Store the configuration address to the PCI address
    li t0, 0xCFC       # Location of the configuration data
    ld a0, 0(t0)       # Load the configuration data to the PCI address
    pop ra
    ret
