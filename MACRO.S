# Macro to push data
.macro push reg 
        sd \reg, 0(sp)
        li t0, 8
        add sp, sp, t0
.endm

# Macro to pop data
.macro pop reg
        li t0, -8
        add sp, sp, t0
        ld \reg, 0(sp)
.endm 
