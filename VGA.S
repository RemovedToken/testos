_setup_qemu_vga:
    push ra

    push a0
    la a0, setup_qemu_vga
    call _write_newline
    pop a0
    pop ra
    