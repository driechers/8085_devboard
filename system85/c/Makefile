CC = zcc
CFLAGS = +system85 -vn
LDFLAGS = +system85 -vn -create-app

OBJ = hello.o stoopid.o

%.o: %.asm
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@	

hello: $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $@

all: hello

clean:
	rm -f hello hello.ihx hello.map *.lis *.bin *.o
