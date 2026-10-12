CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

CAT_DIR = cat
COMMON_DIR = common
BUILD_DIR = build

CAT_SRC = $(CAT_DIR)/s21_cat.c
COMMON_SRC = $(COMMON_DIR)/s21_common.c
ALL_SRC = $(CAT_SRC) $(COMMON_SRC)

CAT_OBJ = $(BUILD_DIR)/s21_cat.o
COMMON_OBJ = $(BUILD_DIR)/s21_common.o

TARGET = $(CAT_DIR)/s21_cat

all: s21_cat

s21_cat: $(BUILD_DIR) $(TARGET)

$(TARGET): $(CAT_OBJ) $(COMMON_OBJ)
	$(CC) $(CFLAGS) $(CAT_OBJ) $(COMMON_OBJ) -o $@

$(CAT_OBJ): $(CAT_SRC) $(CAT_DIR)/s21_cat.h $(COMMON_DIR)/s21_common.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(CAT_SRC) -o $@

$(COMMON_OBJ): $(COMMON_SRC) $(COMMON_DIR)/s21_common.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(COMMON_SRC) -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(TARGET)

rebuild: clean all

test: s21_cat
	@echo "=== Запуск базовых тестов ==="
	@bash tests/test_cat.sh

format:
	clang-format -i -style=Google $(ALL_SRC) $(CAT_DIR)/s21_cat.h $(COMMON_DIR)/s21_common.h

.PHONY: all s21_cat clean rebuild test format