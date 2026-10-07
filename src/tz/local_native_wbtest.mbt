///|
test "read_host_file reads the bytes of a regular file" {
  assert_true(read_host_file("moon.mod") is Some(_))
}

///|
test "read_host_file is None for a path that does not exist" {
  assert_true(read_host_file("/almanac/no/such/file") is None)
}

///|
test "read_host_file is None for a directory" {
  assert_true(read_host_file(".") is None)
}

///|
test "read_host_file is None for a file that is not a regular file" {
  assert_true(read_host_file("/dev/null") is None)
}

///|
test "zoneinfo_dirs puts the ZONEINFO directory ahead of the standard system directories" {
  assert_eq(
    zoneinfo_dirs(Some("/opt/tzdata")),
    ["/opt/tzdata", ..zoneinfo_dirs(None)],
  )
}

///|
test "zoneinfo_dirs always includes the system zoneinfo directory" {
  assert_true(zoneinfo_dirs(None).contains("/usr/share/zoneinfo"))
}

///|
test "zoneinfo_dirs ignores an empty ZONEINFO" {
  assert_eq(zoneinfo_dirs(Some("")), zoneinfo_dirs(None))
}
