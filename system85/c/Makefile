CC = zcc
CFLAGS = +micro8085 -vn
LDFLAGS = +micro8085 -vn -create-app -crt0=system85_crt0.asm

OBJ = hello.o stoopid.o

%.o: %.asm
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@	

hello: $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $@

clean:
	rm hello hello.ihx hello.map *.lis *.bin *.o
