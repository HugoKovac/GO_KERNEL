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

$(NAME): $(KERNEL_OBJ) $(KERNEL_PACKAGE_OBJ) $(BOOT_OBJ)
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
	mkdir -p $(HOME)/src/build-binutils;
	$(HOME)/src/binutils-gdb/configure --target=$(TARGET) --prefix="$(PREFIX)" --with-sysroot --disable-nls --disable-werror
	# --disable-nls: Reduces dependencies and compile time. Set tools language to english
	make -C $(HOME)/src/build-binutils
	make -C $(HOME)/src/build-binutils install


install_gcc:
	which -- $(TARGET)-as || echo $(TARGET)-as is not in the PATH
	
	mkdir -p $(HOME)/src/build-gcc
	$(HOME)/src/gcc-11/configure --target=$(TARGET) --prefix="$(PREFIX)" --disable-nls --enable-languages=c,c++,go --without-headers

	make -C $(HOME)/src/build-gcc all-gcc
	make -C $(HOME)/src/build-gcc all-target-libgcc
	make -C $(HOME)/src/build-gcc install-gcc
	make -C $(HOME)/src/build-gcc install-target-libgcc

install: clone_binutils clone_gcc install_binutils install_gcc


.PHONY: all clean