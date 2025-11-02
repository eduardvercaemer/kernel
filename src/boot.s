    .code16
    .section .bootsector

    ljmp     $0x0000, $.entry

.entry:
    // TODO: A20 gate

    // load kernel
    mov     $0x00, %ah
    int     $0x13
    mov     $0x02, %ah
    mov     $64, %al
    mov     $0, %ch
    mov     $2, %cl
    mov     $0, %dh
    lea     kernel, %bx
    int     $0x13

    // set segments
    xor     %ax, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %fs
    mov     %ax, %gs
    // and stack
    mov     %ax, %ss
    mov     $bootloader, %sp
    cld

    // zero buffer
    mov     $memory_map, %di
    push    %di
    mov     $0x1000, %ecx
    xor     %eax, %eax
    cld
    rep     stosl
    pop     %di

    leal    %es:0x1000(%edi), %eax
    orl     $3, %eax
    movl    %eax, %es:(%edi)

    leal    %es:0x2000(%edi), %eax
    orl     $3, %eax
    movl    %eax, %es:0x1000(%edi)
    
    leal    %es:0x3000(%edi), %eax
    orl     $3, %eax
    movl    %eax, %es:0x2000(%edi)
    
    pushl   %edi
    leal    0x3000(%edi), %edi
    movl    $3, %eax

.page:
    movl    %eax, %es:(%edi)
    addl    $0x1000, %eax
    addl    $8, %edi
    cmpl    $0x200000, %eax
    jb      .page

    popl    %edi
    
    movb    $0xff, %al
    outb    %al, $0xa1
    outb    %al, $0x21
    nop
    nop

    lidt    [.idt]
    
    movl    $0b10100000, %eax
    movl    %eax, %cr4
      
    movl    %edi, %edx
    movl    %edx, %cr3
      
    movl    $0xC0000080, %ecx
    rdmsr

    orl     $0x00000100, %eax
    wrmsr
      
    movl    %cr0, %ebx
    orl     $0x80000001, %ebx
    movl    %ebx, %cr0

    cli
    lgdt    [.gdt.ptr]
      
    jmp     $0x0008, $.entry64

    .code64
.entry64:
    mov     $0x0010, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %fs
    mov     %ax, %gs
    mov     %ax, %ss
    mov     $stack, %rsp
    mov     %rsp, %rbp

    jmp     kmain

    .align 4
    .byte 0x00
.idt:
    .quad 0x0000000000000000
.gdt:
    .quad 0x0000000000000000
    .quad 0x00209a0000000000
    .quad 0x0000920000000000
.gdt.ptr:
    .word .gdt.ptr - .gdt - 1
    .long .gdt
