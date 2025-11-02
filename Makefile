.EXTRA_PREREQS := $(abspath $(lastword $(MAKEFILE_LIST)))
.PHONY: run debug lldb clean

run: out/image.bin
	qemu-system-x86_64 \
		-m 512M \
		-serial stdio \
		-display none \
		-drive file=$<,format=raw

debug: out/image.bin out/kernel.elf
	qemu-system-x86_64 \
		-m 512M \
		-serial stdio \
		-display none \
		-drive file=$<,format=raw \
		-S -s

lldb:
	lldb -s qemu.lldb

clean:
	rm -r out

out:
	@test -d out || mkdir out

#####################################################################

out/image.bin: out/boot.bin out/kernel.bin
	cat $^ > $@

out/boot.bin: out/kernel.elf
	objcopy \
		-O binary \
		-j .bootsector \
		$< $@

out/kernel.bin: out/kernel.elf
	objcopy \
		-O binary \
		-j .kernel \
		$< $@

out/kernel.elf: out/kernel.o out/boot.o src/kernel.ld
	ld \
		-z noexecstack \
		--build-id=none \
		-T src/kernel.ld \
		-o $@ \
		out/kernel.o out/boot.o

out/kernel.o: src/kernel.rs | out
	rustc \
		--target x86_64-unknown-none \
		--edition 2024 \
		--emit obj=$@ \
		-C opt-level=z \
		-C panic=abort \
		-g $<

out/boot.o: src/boot.s | out
	clang \
		-target x86_64-unknown-none \
		-o $@ \
		-c $<
