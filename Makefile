NAME=gokernel.bin

CC=gccgo
TARGET=i686-elf
HOME_PREFIX="$(HOME)/opt/cross"
GO_FLAGS=-static -Werror -nostdlib -nostartfiles -nodefaultlibs
LINKER_FLAGS=-ffreestanding -O2 -nostdlib -shared 

KERNEL_SRC=kernel.go
KERNEL_PACKAGE_SRC=terminal.go
BOOT_SRC=boot.s
KERNEL_OBJ=$(KERNEL_SRC:.go=.go.o)
KERNEL_PACKAGE_OBJ=$(KERNEL_PACKAGE_SRC:.go=.go.o)
BOOT_OBJ=$(BOOT_SRC:.s=.o)
OBJ=$(KERNEL_OBJ) $(KERNEL_PACKAGE_OBJ) $(BOOT_OBJ)
LINKER=linker.ld

all: $(NAME)

$(NAME): $(BOOT_OBJ) $(KERNEL_PACKAGE_OBJ) $(KERNEL_OBJ)
	PATH=$(HOME_PREFIX)/bin $(TARGET)-ld -T $(LINKER) $(LINKER_FLAGS) -o $@ $(OBJ)

$(KERNEL_OBJ): $(KERNEL_SRC)
	PATH=$(HOME_PREFIX)/bin $(TARGET)-$(CC) $(GO_FLAGS) -c $< -o $@

$(KERNEL_PACKAGE_OBJ): $(KERNEL_PACKAGE_SRC)
	PATH=$(HOME_PREFIX)/bin $(TARGET)-$(CC) $(GO_FLAGS) -c $< -o $@
	PATH=$(HOME_PREFIX)/bin $(TARGET)-objcopy -j .go_export terminal.go.o terminal.gox

$(BOOT_OBJ): $(BOOT_SRC)
	PATH=$(HOME_PREFIX)/bin $(TARGET)-as $< -o $@

clean:
	rm -f $(OBJ) $(NAME)

clone_binutils:
	if [ ! -d $(HOME)/src/binutils-gdb ]; then \
		git clone git://sourceware.org/git/binutils-gdb.git $(HOME)/src/binutils-gdb; \
	fi

clone_gcc:
	if [ ! -d $(HOME)/src/gcc-11 ]; then \
		git clone git://gcc.gnu.org/git/gcc.git $(HOME)/src/gcc-11; \
	fi

install_binutils:
	if which -- $(TARGET)-$(CC) >/dev/null 2>&1; then \
		echo "$(TARGET)-$(CC) already exist"; \
		exit 0; \
	fi
	mkdir -p $(HOME)/src/build-binutils-$(TARGET);
	cd $(HOME)/src/build-binutils-$(TARGET) && \
		../binutils-gdb/configure --target=$(TARGET) --prefix="$(PREFIX)" --with-sysroot --disable-nls --disable-werror && \
		make && \
		make install


install_gcc:
	if which -- $(TARGET)-as >/dev/null 2>&1; then \
		echo "$(TARGET)-as already exist"; \
		exit 0; \
	fi
	mkdir -p $(HOME)/src/build-gcc-$(TARGET)
	cd $(HOME)/src/build-gcc-$(TARGET) && \
		../gcc-11/configure --target=$(TARGET) --prefix="$(PREFIX)" --disable-nls --enable-languages=c,c++,go --without-headers && \
		make all-gcc && \
		make all-target-libgcc && \
		make install-gcc && \
		make install-target-libgcc

install: clone_binutils clone_gcc install_binutils install_gcc


.PHONY: all clean