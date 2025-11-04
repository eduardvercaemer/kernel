# x86 Kernel with Rust

**Tested with**:

```
clang = 21.1.3 (for assembler only)
rustc = 1.90.0 (1159e78c4 2025-09-14)
qemu  = 10.1.1
```

**Structure**:

```
src/boot.s:    simple bootloader
src/kernel.rs: kernel entry point
src/kernel.ld: linker script
```

## Running

```
make run
```

## Debugging

```
make debug
make lldb
```

## Architecture

1. The easiest way to get an idea of the memory layout is to simply
   look at the linker script. In summary, the bootloader gets loaded
   at `0x7c00`, it then loads the next 32KiB of the drive at `0xc000`,
   this is the kernel main address. After loading the kernel, it then
   creates an initial page configuration that identity-maps the first
   2MiB of memory, enters long mode, and jumps to the kernel.

## Resources

- https://wiki.osdev.org/
- https://blog.zolutal.io/understanding-paging/

## Changelog

- 2025-11-02 (`9643a362`): hello world with serial output!
