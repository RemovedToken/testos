# Getting started 

'https://youtube.com/playlist?list=PLvPRqTZ5Cxw5uxJ0_VKOUc0t5b6_IpBNS&si=Mioi43YxTLh4UYX2'


Instructions with the relevant implementations are found in the folder 'Documents'


References used: 
-   RISC-V specifications: https://riscv.org/technical/specifications/
-   Qemu instructions for compiling/installing: https://www.qemu.org/docs/master/system/riscv/virt.html
-   Reference to RISC-V emulator: https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c

Commands used:
-   Compilation: `riscv64-unknown-elf-as <Bootloader_file.S> -o <output_file_name.o>`
-   Linking: `riscv64-unknown-elf-ld -T <Kernel_file.lds> <output_file_name.o> -o <kernel_output_file_name.elf>`
-   Running the kernel with qemu: `qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M -nographic -serial mon:stdio -bios none -kernel <kernel_output_file_name.elf>`