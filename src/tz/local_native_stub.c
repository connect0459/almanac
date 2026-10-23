#include "moonbit.h"
#include <stdio.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#endif

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

moonbit_bytes_t almanac_windows_zone_key_name(void) {
#ifdef _WIN32
  DYNAMIC_TIME_ZONE_INFORMATION info;
  if (GetDynamicTimeZoneInformation(&info) == TIME_ZONE_ID_INVALID) {
    return moonbit_make_bytes(0, 0);
  }
  int size = WideCharToMultiByte(CP_UTF8, 0, info.TimeZoneKeyName, -1, NULL, 0,
                                 NULL, NULL);
  if (size <= 1) {
    return moonbit_make_bytes(0, 0);
  }
  moonbit_bytes_t buf = moonbit_make_bytes_raw(size - 1);
  if (WideCharToMultiByte(CP_UTF8, 0, info.TimeZoneKeyName, -1, (char *)buf,
                          size - 1, NULL, NULL) == 0) {
    return moonbit_make_bytes(0, 0);
  }
  return buf;
#else
  return moonbit_make_bytes(0, 0);
#endif
}
