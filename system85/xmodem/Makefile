CC = zcc
CFLAGS = +system85 -vn -DPOSIX -DMD=2 -DBUFSIZ=512
LDFLAGS = +system85 -vn -create-app -crt0 system85_crt0.asm

OBJ = xmodem.o

%.o: %.asm
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@	

xmodem: $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $@

all: xmodem

clean:
	rm -f xmodem xmodem.ihx xmodem.map *.lis *.bin *.o
