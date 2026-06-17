#!/bin/sh
head -c 16384 /dev/urandom | xxd -p -c 2 | head -n 8192 >vram_init.data
