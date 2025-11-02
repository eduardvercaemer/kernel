#![no_std]
#![no_main]
use core::arch::asm;
use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn kmain() -> ! {
    serial_init();

    let s = "hello, there\n";
    for b in s.bytes() {
        serial_writeb(b);
    }

    let mut c = 0;
    loop {
        c += 1;
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Requires a target that supports the `asm` feature (x86/x86_64 targets).

// --- I/O Port Functions using Inline Assembly ---

/// Reads a byte from the specified I/O port.
#[inline(always)]
unsafe fn inb(port: u16) -> u8 {
    let data: u8;
    // The 'in' instruction reads from port (dx) into data (al).
    unsafe {
        asm!(
            "in al, dx",
            out("al") data, // Output operand: data goes into AL
            in("dx") port,  // Input operand: port number comes from DX
            options(nomem, nostack, preserves_flags)
        );
        data
    }
}

/// Writes a byte to the specified I/O port.
#[inline(always)]
unsafe fn outb(port: u16, data: u8) {
    // The 'out' instruction writes data (al) to port (dx).
    unsafe {
        asm!(
            "out dx, al",
            in("dx") port,  // Input operand: port number comes from DX
            in("al") data,  // Input operand: data comes from AL
            options(nomem, nostack, preserves_flags)
        );
    }
}

/// The base I/O port address for COM1.
const PORT_COM1: u16 = 0x03f8;

/// Checks the Line Status Register (LSR) for the Data Ready bit (Bit 0).
fn serial_received() -> u8 {
    // PORT_COM1 + 5 is the LSR
    // Use `unsafe` to call the inline assembly function `inb`.
    unsafe { inb(PORT_COM1 + 5) & 1 }
}

/// Checks the Line Status Register (LSR) for the Transmit Holding Register Empty bit (Bit 5).
fn is_transmit_empty() -> u8 {
    // PORT_COM1 + 5 is the LSR
    unsafe { inb(PORT_COM1 + 5) & 0x20 }
}

/// Initializes the serial port.
/// Returns 0 on success, 1 on test failure.
fn serial_init() -> i32 {
    // All port I/O operations and global state access must be wrapped in `unsafe`.
    unsafe {
        // 0x03f8 + 1 (Interrupt Enable Register - IER)
        outb(PORT_COM1 + 1, 0x00); // Disable all interrupts

        // 0x03f8 + 3 (Line Control Register - LCR)
        outb(PORT_COM1 + 3, 0x80); // Enable DLAB (set baud rate divisor)

        // 0x03f8 + 0 (Divisor Latch Low - DLL)
        outb(PORT_COM1 + 0, 0x03); // Set divisor to 3 (lo byte) -> 38400 baud

        // 0x03f8 + 1 (Divisor Latch High - DLH)
        outb(PORT_COM1 + 1, 0x00); // (hi byte)

        // 0x03f8 + 3 (Line Control Register - LCR)
        outb(PORT_COM1 + 3, 0x03); // 8 bits, no parity, one stop bit (DLAB disabled)

        // 0x03f8 + 2 (FIFO Control Register - FCR)
        outb(PORT_COM1 + 2, 0xc7); // Enable FIFO, clear them, 14-byte threshold

        // 0x03f8 + 4 (Modem Control Register - MCR)
        outb(PORT_COM1 + 4, 0x0b); // IRQs enabled, RTS/DSR set

        // Test Serial Chip (Loopback Test)
        outb(PORT_COM1 + 4, 0x1e); // Set in loopback mode
        outb(PORT_COM1 + 0, 0xae); // Send test byte 0xAE

        // Check if serial is faulty (i.e: not same byte as sent)
        if inb(PORT_COM1 + 0) != 0xae {
            return 1;
        }

        // Set back to normal operation mode (not-loopback)
        outb(PORT_COM1 + 4, 0x0f);
    }
    0 // Success
}

/// Reads a single character from the serial port. Blocks until data is available.
fn serial_readb() -> u8 {
    unsafe {
        // Wait until `serial_received()` is non-zero (true)
        while serial_received() == 0 {}
        // PORT_COM1 + 0 (Data Register - DR)
        inb(PORT_COM1)
    }
}

/// Writes a single character to the serial port. Blocks until the port is ready.
fn serial_writeb(val: u8) {
    unsafe {
        // Wait until `is_transmit_empty()` is non-zero (true)
        while is_transmit_empty() == 0 {}
        // PORT_COM1 + 0 (Data Register - DR)
        outb(PORT_COM1, val);
    }
}
