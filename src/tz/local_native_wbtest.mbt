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
