///|
test "parse_tzif rejects data that is too short to hold a header" {
  assert_true(@tz.parse_tzif(b"TZif") is None)
}

///|
test "parse_tzif rejects data with an invalid magic number" {
  assert_true(@tz.parse_tzif(Bytes::make(44, b'\x00')) is None)
}

///|
test "parse_tzif parses UTC: a single local time type, no transitions, no DST" {
  let parsed = @tz.parse_tzif(tzif_utc).unwrap()
  assert_eq(parsed.transitions(), [])
  assert_eq(parsed.local_time_types().length(), 1)
  let utc_type = parsed.local_time_types()[0]
  assert_eq(utc_type.utc_offset(), 0)
  assert_eq(utc_type.is_dst(), false)
  assert_eq(utc_type.abbreviation(), "UTC")
  assert_eq(parsed.posix_tz(), Some("UTC0"))
}

///|
test "parse_tzif parses Asia/Tokyo's local time types, including negative-adjacent historical LMT offset" {
  let parsed = @tz.parse_tzif(tzif_tokyo).unwrap()
  assert_eq(parsed.local_time_types().length(), 4)
  let types = parsed.local_time_types()
  assert_eq(types[0], @tz.LocalTimeType::new(33539, false, "LMT"))
  assert_eq(types[1], @tz.LocalTimeType::new(36000, true, "JDT"))
  assert_eq(types[2], @tz.LocalTimeType::new(32400, false, "JST"))
  assert_eq(parsed.posix_tz(), Some("JST-9"))
}

///|
test "parse_tzif parses Asia/Tokyo's transition table in chronological order" {
  let parsed = @tz.parse_tzif(tzif_tokyo).unwrap()
  assert_eq(parsed.transitions().length(), 9)
  assert_eq(parsed.transitions()[0], -2587712400L)
  assert_eq(parsed.transition_types()[0], 3)
  assert_eq(parsed.transitions()[8], -577962000L)
  assert_eq(parsed.transition_types()[8], 2)
}

///|
test "parse_tzif parses America/New_York, a zone with a negative (west-of-UTC) historical LMT offset" {
  let parsed = @tz.parse_tzif(tzif_new_york).unwrap()
  let types = parsed.local_time_types()
  assert_eq(types.length(), 6)
  assert_eq(types[0], @tz.LocalTimeType::new(-17762, false, "LMT"))
  assert_eq(types[1], @tz.LocalTimeType::new(-14400, true, "EDT"))
  assert_eq(types[2], @tz.LocalTimeType::new(-18000, false, "EST"))
  assert_eq(parsed.transitions().length(), 236)
  assert_eq(parsed.transitions()[0], -2717650800L)
  assert_eq(parsed.transitions()[235], 2140668000L)
  assert_eq(parsed.transition_types()[235], 2)
  assert_eq(parsed.posix_tz(), Some("EST5EDT,M3.2.0,M11.1.0"))
  assert_eq(parsed.leap_seconds(), [])
}

///|
test "parse_tzif parses Australia/Sydney's wraparound POSIX footer (DST spans a year boundary)" {
  let parsed = @tz.parse_tzif(tzif_sydney).unwrap()
  assert_eq(parsed.transitions().length(), 142)
  assert_eq(parsed.posix_tz(), Some("AEST-10AEDT,M10.1.0,M4.1.0/3"))
}

///|
test "parse_tzif parses a version-1-only file (no 64-bit block or POSIX footer), including its 32-bit leap-second record" {
  let parsed = @tz.parse_tzif(tzif_v1_only).unwrap()
  assert_eq(parsed.transitions(), [])
  assert_eq(parsed.local_time_types(), [@tz.LocalTimeType::new(0, false, "X")])
  assert_eq(parsed.posix_tz(), None)
  assert_eq(parsed.leap_seconds(), [(78796800L, 1)])
}

///|
test "parse_tzif rejects a header whose declared counts exceed the data actually present" {
  assert_true(@tz.parse_tzif(tzif_header_only_claims_one_transition) is None)
}

///|
test "parse_tzif parses a leap-second record without applying it to any other field" {
  let parsed = @tz.parse_tzif(tzif_v2_with_leap_second).unwrap()
  assert_eq(parsed.leap_seconds(), [(78796800L, 1)])
}

///|
test "parse_tzif rejects a file truncated immediately after the version-1 block" {
  assert_true(@tz.parse_tzif(tzif_v2_truncated_before_second_block) is None)
}

///|
test "parse_tzif rejects a footer missing its leading newline" {
  assert_true(@tz.parse_tzif(tzif_footer_missing_leading_newline) is None)
}

///|
test "parse_tzif rejects a footer missing its trailing newline" {
  assert_true(@tz.parse_tzif(tzif_footer_missing_trailing_newline) is None)
}

///|
test "mutating an array returned by a TzifData accessor leaves the data unchanged" {
  let parsed = @tz.parse_tzif(tzif_tokyo).unwrap()
  let before = @tz.parse_tzif(tzif_tokyo).unwrap()
  parsed.transitions().clear()
  parsed.transition_types().clear()
  parsed.local_time_types().clear()
  parsed.leap_seconds().clear()
  assert_true(parsed == before)
  assert_eq(parsed.transitions(), before.transitions())
  assert_true(parsed.transitions().length() > 0)
  assert_true(parsed.local_time_types().length() > 0)
}
