#include "moonbit.h"
#include <stdio.h>

moonbit_bytes_t almanac_read_etc_localtime(void) {
  FILE *f = fopen("/etc/localtime", "rb");
  if (f == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  long size = ftell(f);
  if (size <= 0) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  rewind(f);
  moonbit_bytes_t buf = moonbit_make_bytes_raw((int32_t)size);
  size_t n = fread(buf, 1, (size_t)size, f);
  fclose(f);
  if (n != (size_t)size) {
    return moonbit_make_bytes(0, 0);
  }
  return buf;
}
