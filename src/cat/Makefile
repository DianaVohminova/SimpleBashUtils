CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

TARGET = s21_cat
COMMON_SRC = ../common/s21_common.c

SRC = s21_cat.c $(COMMON_SRC)
OBJ = s21_cat.o ../common/s21_common.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@

s21_cat.o: s21_cat.c s21_cat.h ../common/s21_common.h
	$(CC) $(CFLAGS) -c s21_cat.c -o s21_cat.o

../common/s21_common.o: ../common/s21_common.c ../common/s21_common.h
	$(CC) $(CFLAGS) -c ../common/s21_common.c -o ../common/s21_common.o

clean:
	rm -f *.o ../common/*.o $(TARGET)

rebuild: clean all

.PHONY: all clean rebuild