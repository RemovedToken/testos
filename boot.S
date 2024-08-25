.option norvc
.section .data

.section .text.init
.global _start

_start:
    csrr t0, mhartid
    bnez t0, _wait

    wfi


_wait:
    wfi
