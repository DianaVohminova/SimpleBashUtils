CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

CAT_DIR    = cat
GREP_DIR   = grep
COMMON_DIR = common
BUILD_DIR  = build

CAT_SRC = $(CAT_DIR)/s21_cat.c
CAT_OBJ = $(BUILD_DIR)/s21_cat.o
CAT_TARGET = $(CAT_DIR)/s21_cat

GREP_SRC = $(GREP_DIR)/s21_grep.c
GREP_OBJ = $(BUILD_DIR)/s21_grep.o
GREP_TARGET = $(GREP_DIR)/s21_grep

COMMON_SRC = $(COMMON_DIR)/s21_common.c
COMMON_OBJ = $(BUILD_DIR)/s21_common.o

ALL_SRC = $(CAT_SRC) $(GREP_SRC) $(COMMON_SRC)
ALL_HDR = $(CAT_DIR)/s21_cat.h $(GREP_DIR)/s21_grep.h $(COMMON_DIR)/s21_common.h

FORMAT_SRC = cat/s21_cat.c   cat/s21_cat.h   \
             grep/s21_grep.c grep/s21_grep.h \
             common/s21_common.c common/s21_common.h

all: s21_cat s21_grep

s21_cat: $(BUILD_DIR) $(CAT_TARGET)

$(CAT_TARGET): $(CAT_OBJ) $(COMMON_OBJ)
	$(CC) $(CFLAGS) $(CAT_OBJ) $(COMMON_OBJ) -o $@

$(CAT_OBJ): $(CAT_SRC) $(CAT_DIR)/s21_cat.h $(COMMON_DIR)/s21_common.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(CAT_SRC) -o $@

s21_grep: $(BUILD_DIR) $(GREP_TARGET)

$(GREP_TARGET): $(GREP_OBJ) $(COMMON_OBJ)
	$(CC) $(CFLAGS) $(GREP_OBJ) $(COMMON_OBJ) -o $@

$(GREP_OBJ): $(GREP_SRC) $(GREP_DIR)/s21_grep.h $(COMMON_DIR)/s21_common.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(GREP_SRC) -o $@

$(COMMON_OBJ): $(COMMON_SRC) $(COMMON_DIR)/s21_common.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(COMMON_SRC) -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(CAT_TARGET) $(GREP_TARGET)

rebuild: clean all

test: all
	@echo "=== cat ==="
	@bash tests/test_cat.sh
	@echo "=== grep ==="
	@bash tests/test_grep.sh

format:
	clang-format -i -style=Google $(FORMAT_SRC)

.PHONY: all s21_cat s21_grep clean rebuild test format