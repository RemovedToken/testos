/* The architecture used to compile the file */
OUTPUT_ARCH( "riscv" )

/* Starting point of the program */
ENTRY( _start )


/* Specification of a memory region that can be read/written, executable, and allocatable with the start address 0x80000000 with the length of 128 megabytes */
/* This address is the location of the DRAM according to the virt c emulator */
MEMORY
{
  ram  (wxa) : ORIGIN = 0x80000000, LENGTH = 128M
}

/* Program headers that load the different parts of the program */
PHDRS
{
  text PT_LOAD;
  data PT_LOAD;
  bss PT_LOAD;
}


/* Maps input section to output section and how to place the output sections into memory */
SECTIONS
{

/* Declare a address where the functions can be accessed by the linker script from the declared >RAM. */ 
  .text : {
    PROVIDE(_text_start = .);
    *(.text.init) *(.text .text.*)
    PROVIDE(_text_end = .);
  } >ram AT>ram :text

   PROVIDE(_global_pointer = .);

  .rodata : {
    PROVIDE(_rodata_start = .);
    *(.rodata .rodata.*)
    PROVIDE(_rodata_end = .);
  } >ram AT>ram :text

  .data : {
    . = ALIGN(4096);
    PROVIDE(_data_start = .);
    *(.sdata .sdata.*) *(.data .data.*)
    PROVIDE(_data_end = .);
  } >ram AT>ram :data

  .bss : {
    PROVIDE(_bss_start = .);
    *(.sbss .sbss.*) *(.bss .bss.*)
    PROVIDE(_bss_end = .);
  } >ram AT>ram :bss

 /* This tells the kernel where the ram starts */
  PROVIDE(_memory_start = ORIGIN(ram));
  
  /* Telling the kernel where the memory ends */
  PROVIDE(_memory_end = ORIGIN(ram) + LENGTH(ram));
  
  /*Telling the kernel where the heap ends */ 
  PROVIDE(_heap_end = _memory_end - 4096);

  /* Heap counter */
  PROVIDE(_heap_counter = _heap_end + 8);

}