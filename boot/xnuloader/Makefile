CROSS_COMPILE ?= aarch64-linux-gnu-
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy

CFLAGS := -Wall -Wextra -ffreestanding -nostdlib -fno-stack-protector -fno-builtin -mcpu=cortex-a77 -O2
LDFLAGS := -T linker.ld -nostdlib

TARGET := xnuloader.elf
BIN := xnuloader.bin

all: $(BIN)

$(TARGET): entry.S main.c
	$(CC) $(CFLAGS) -c entry.S -o entry.o
	$(CC) $(CFLAGS) -c main.c -o main.o
	$(LD) $(LDFLAGS) entry.o main.o -o $(TARGET)

$(BIN): $(TARGET)
	$(OBJCOPY) -O binary $(TARGET) $(BIN)

clean:
	rm -f *.o $(TARGET) $(BIN)

.PHONY: all clean
