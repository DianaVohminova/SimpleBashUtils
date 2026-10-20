CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

TARGET = s21_grep
COMMON_SRC = ../common/s21_common.c

SRC = s21_grep.c $(COMMON_SRC)
OBJ = s21_grep.o ../common/s21_common.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@

s21_grep.o: s21_grep.c s21_grep.h ../common/s21_common.h
	$(CC) $(CFLAGS) -c s21_grep.c -o s21_grep.o

../common/s21_common.o: ../common/s21_common.c ../common/s21_common.h
	$(CC) $(CFLAGS) -c ../common/s21_common.c -o ../common/s21_common.o

clean:
	rm -f *.o ../common/*.o $(TARGET)

rebuild: clean all

test:
	chmod +x test_grep.sh
	./test_grep.sh

.PHONY: all clean rebuild test