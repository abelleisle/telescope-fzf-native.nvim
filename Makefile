BUILD_DIR = build
ifeq ($(OS),Windows_NT)
	BUILD_DIR := $(BUILD_DIR)_win_$(PROCESSOR_ARCHITECTURE)
else
    ARCH_U := $(shell uname -p)
	BUILD_DIR := $(BUILD_DIR)_$(ARCH_U)
endif

CFLAGS += -Wall -Werror -fpic -std=gnu99

ifeq ($(OS),Windows_NT)
    CC = gcc
    TARGET := libfzf.dll
ifeq (,$(findstring MSYS,$(MSYSTEM)))
	# On Windows, but NOT msys
    MKD = cmd /C mkdir
    RM = cmd /C rmdir /Q /S
else
    MKD = mkdir -p
    RM = rm -rf
endif
else
    MKD = mkdir -p
    RM = rm -rf
    TARGET := libfzf.so
endif

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): src/fzf.c src/fzf.h
	$(MKD) $(BUILD_DIR)
	$(CC) -O3 $(CFLAGS) -shared src/fzf.c -o $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/test: $(BUILD_DIR)/$(TARGET) test/test.c
	$(CC) -Og -ggdb3 $(CFLAGS) test/test.c -o $(BUILD_DIR)/test -I./src -L./build -lfzf -lexaminer

.PHONY: lint format clangdhappy clean test ntest
lint:
	luacheck lua

format:
	clang-format --style=file --dry-run -Werror src/fzf.c src/fzf.h test/test.c

test: $(BUILD_DIR)/test
	@LD_LIBRARY_PATH=${PWD}/$(BUILD_DIR):${PWD}/examiner/$(BUILD_DIR):${LD_LIBRARY_PATH} ./$(BUILD_DIR)/test

ntest:
	nvim --headless --noplugin -u test/minrc.vim -c "PlenaryBustedDirectory test/ { minimal_init = './test/minrc.vim' }"

clangdhappy:
	compiledb make

clean:
	$(RM) $(BUILD_DIR)
