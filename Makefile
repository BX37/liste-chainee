CC     = gcc
CFLAGS = -Wall -Wextra -std=c11 -g
OBJ    = main.o liste.o

demo: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c liste.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) demo

.PHONY: clean
