AS = nasm
ASFLAGS = -f elf64
LD = ld 
LDFLAGS = -nostdlib 
TARGET = lisp 
OBJECTS = lisp.o 

TARGET2 = sse 
OBJECTS2 = sse42.o 


%.o: %.asm 
	$(AS) $(ASFLAGS) $<

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(TARGET)

$(TARGET2): $(OBJECTS2)
	rm -f *.o
	gcc sse.c sse42.o -o $(TARGET2)