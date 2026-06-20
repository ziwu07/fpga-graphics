#include <stdint.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
  FILE *f = fopen("vram_init.data", "w");
  if (!f) {
    perror("Error opening file");
    return 1;
  }

  uint16_t buf[4096];
  for (uint32_t i = 0; i < 4096; ++i) {
    buf[i] = 0x0;
  }

  uint32_t offset = 0;

  for (uint32_t i = 0; i < 219; ++i) {
    for (uint32_t j = 0; j < 292; ++j) {
      uint_fast8_t bit = (i & 1) ^ (j & 1);
      // uint_fast8_t bit = (i == 0 || i == 218 || j == 0 || j == 291) ? 1 : 0;
      buf[offset / 16] |= bit << (offset % 16);
      offset++;
    }
  }

  for (uint32_t i = 0; i < 4096; ++i) {
    fprintf(f, "%04x\n", buf[i]);
  }
  for (uint32_t i = 0; i < 4096; ++i) {
    buf[i] ^= 0xFFFF;
  }
  for (uint32_t i = 0; i < 4096; ++i) {
    fprintf(f, "%04x\n", buf[i]);
  }

  fclose(f);
  return 0;
}
