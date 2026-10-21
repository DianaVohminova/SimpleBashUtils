CC     = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

COMMON_DIR = ../common
TARGET     = s21_cat
OBJ        = s21_cat.o
COMMON_OBJ = s21_common.o

all: $(TARGET)

$(TARGET): $(OBJ) $(COMMON_OBJ)
	$(CC) $(CFLAGS) $^ -o $@

$(OBJ): s21_cat.c s21_cat.h $(COMMON_DIR)/s21_common.h
	$(CC) $(CFLAGS) -c $< -o $@

$(COMMON_OBJ): $(COMMON_DIR)/s21_common.c $(COMMON_DIR)/s21_common.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(COMMON_OBJ) $(TARGET)

rebuild: clean all

.PHONY: all clean rebuild