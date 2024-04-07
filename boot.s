# Declare constants used for creating a multiboot header.
.set ALIGN,    1<<0             # align loaded modules on page boundaries
.set MEMINFO,  1<<1             # provide memory map
.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

# Declare a header as in the Multiboot Standard.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# Currently the stack pointer register (esp) points at anything and using it may
# cause massive harm. Instead, we'll provide our own stack.
.section .bootstrap_stack, "aw", @nobits
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

# The linker script specifies _start as the entry point to the kernel and the
# bootloader will jump to this position once the kernel has been loaded. It
# doesn't make sense to return from this function as the bootloader is gone.
.section .text
.global _start
.type _start, @function
_start:
	# To set up a stack, we simply set the esp register to point to the top of
	# our stack (as it grows downwards).
	movl $stack_top, %esp

	# We are now ready to actually execute Go code. Functions that start with a
	# capital letter are exported as "go.<package>.<function>".
	call go.kernel.Main

	# In case the function returns, we'll want to put the computer into an
	# infinite loop.
	cli
	hlt
.Lhang:
	jmp .Lhang

# Set the size of the _start symbol to the current location '.' minus its start.
# This is useful when debugging or when you implement call tracing.
.size _start, . - _start

# The Go runtime is a big problem when wanting to write a kernel in Go.
# Although not impossible, it's certainly not trivial. At the very least
# you'd need to implement parts of libc that it uses. Porting the runtime
# goes way beyond the scope of this barebone. 
#
# Beware that there are almost no language features you can use at this point.
# The linker will fail with missing symbols when you try to use them.
#
# You have to implement those missing symbols yourself to get things working.
# Sometimes you can get away with declaring them as an empty function. 
# But this won't always work.
#
# After you get this bare bone working, the first priority should be to write
# your own memory allocator. A simple sbrk implementation should suffice for
# symbols like __go_new.
#
# For now we just implement the symbols below as empty functions to get this
# barebone up and running.
#

.global __go_register_gc_roots
.type __go_register_gc_roots, @function
__go_register_gc_roots:
	ret
.size __go_register_gc_roots, . - __go_register_gc_roots

.global __go_runtime_error
.type __go_runtime_error, @function
__go_runtime_error:
	ret
.size __go_runtime_error, . - __go_runtime_error
