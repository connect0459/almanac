#include "moonbit.h"
#include <stdio.h>
#include <sys/stat.h>

#ifndef S_ISREG
#define S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#endif

#define ALMANAC_MAX_FILE_SIZE (1L << 20)

moonbit_bytes_t almanac_read_file(moonbit_bytes_t path) {
  FILE *f = fopen((const char *)path, "rb");
  if (f == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  struct stat st;
  if (fstat(fileno(f), &st) != 0 || !S_ISREG(st.st_mode)) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  long size = ftell(f);
  if (size <= 0 || size > ALMANAC_MAX_FILE_SIZE) {
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
