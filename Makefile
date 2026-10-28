CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g

SRCS_LIB = matrice.c matrice_alloc.c matrice_calcul.c matrice_io.c
OBJS_LIB = $(SRCS_LIB:.c=.o)

TARGETS = test_ex1 test_ex2 test_ex3 demo_matrices

all: $(TARGETS)

test_ex1: test_ex1.o $(OBJS_LIB)
	$(CC) $(CFLAGS) $^ -o $@

test_ex2: test_ex2.o $(OBJS_LIB)
	$(CC) $(CFLAGS) $^ -o $@

test_ex3: test_ex3.o $(OBJS_LIB)
	$(CC) $(CFLAGS) $^ -o $@

demo_matrices: main.o $(OBJS_LIB)
	$(CC) $(CFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o $(TARGETS)

.PHONY: all clean
