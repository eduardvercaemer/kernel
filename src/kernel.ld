ENTRY(kmain)
SECTIONS
{
    . = 0x7c00;

    bootloader = .;

    .bootsector :
    {
        * (.bootsector);
        . = 510;
        SHORT(0xaa55);
    }

    . = 0x8000;

    memory_map = .;

    . = 0xc000;

    kernel = .;

    .kernel :
    {
        * (.text*);
        * (.rodata*);
    }

    . = 0x7ffff;

    stack = .;

    /DISCARD/ : { *(*); }
}
