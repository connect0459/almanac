///|
test "parse_posix_tz parses a zone with no DST rule, offset_at is constant regardless of instant" {
  let tz = @tz.parse_posix_tz("UTC0").unwrap()
  assert_eq(tz.offset_at(0L), 0)
  assert_eq(tz.offset_at(1_700_000_000L), 0)
  assert_eq(tz.offset_at(-1_700_000_000L), 0)
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    tz.offset_from_local(dt),
    @tz.Single(@tz.FixedOffset::east(0).unwrap()),
  )
}

///|
test "parse_posix_tz parses a positive (east-of-UTC) offset with no DST rule" {
  let tz = @tz.parse_posix_tz("JST-9").unwrap()
  assert_eq(tz.offset_at(0L), 32400)
  assert_eq(tz.offset_at(1_700_000_000L), 32400)
}

///|
test "parse_posix_tz rejects malformed input" {
  assert_true(@tz.parse_posix_tz("") is None)
  assert_true(@tz.parse_posix_tz("US") is None)
  assert_true(@tz.parse_posix_tz("EST") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0extra") is None)
  assert_true(@tz.parse_posix_tz("EST5#") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT4X") is None)
  assert_true(@tz.parse_posix_tz("<ABC5EDT,M3.2.0,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0,") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,J,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,#,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0,#") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0/") is None)
  assert_true(@tz.parse_posix_tz("EST5:,M3.2.0,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5:30:,M3.2.0,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("EST5EDT,M3.2.0/,M11.1.0") is None)
}

///|
test "parse_posix_tz parses a quoted name, an explicit '+' sign, and an explicit (non-default) DST offset" {
  let tz = @tz.parse_posix_tz("<STD>+5<DST>3,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let dst_end = 2_172_718_800L
  assert_eq(tz.offset_at(dst_start - 1L), -18000)
  assert_eq(tz.offset_at(dst_start), -10800)
  assert_eq(tz.offset_at(dst_end - 1L), -10800)
  assert_eq(tz.offset_at(dst_end), -18000)
}

///|
test "parse_posix_tz parses minute/second-precision offsets and an explicit (non-default) rule time" {
  let tz = @tz.parse_posix_tz("STD-1DST,M3.5.0/1:30:15,M9.5.0").unwrap()
  assert_eq(tz.offset_at(1_902_484_800L), 7200)
  assert_eq(tz.offset_at(1_965_643_200L), 7200)
}

///|
test "parse_posix_tz evaluates a Julian-no-leap (Jn) rule" {
  let tz = @tz.parse_posix_tz("STD-1DST,J100,J200").unwrap()
  assert_eq(tz.offset_at(1_906_372_800L), 7200)
  assert_eq(tz.offset_at(1_915_012_800L), 3600)
}

///|
test "parse_posix_tz evaluates a Julian-with-leap (n) rule" {
  let tz = @tz.parse_posix_tz("STD-1DST,99,199").unwrap()
  assert_eq(tz.offset_at(1_906_372_800L), 7200)
  assert_eq(tz.offset_at(1_915_012_800L), 3600)
}

///|
test "offset_from_local resolves a wraparound rule's local reading that is not near either transition" {
  let tz = @tz.parse_posix_tz("AEST-10AEDT,M10.1.0,M4.1.0/3").unwrap()
  let january = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2038, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    tz.offset_from_local(january),
    @tz.Single(@tz.FixedOffset::east(39600).unwrap()),
  )
}

///|
test "offset_from_local falls through to a Single resolution when the DST offset equals the standard offset" {
  let tz = @tz.parse_posix_tz("STD5DST5,M3.2.0,M11.1.0").unwrap()
  let mid_year = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2038, 6, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    tz.offset_from_local(mid_year),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
}

///|
test "offset_at resolves a non-wraparound DST rule (America/New_York) either side of both transitions" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let dst_end = 2_172_722_400L
  assert_eq(tz.offset_at(dst_start - 1L), -18000)
  assert_eq(tz.offset_at(dst_start), -14400)
  assert_eq(tz.offset_at(dst_end - 1L), -14400)
  assert_eq(tz.offset_at(dst_end), -18000)
}

///|
test "offset_at resolves a wraparound DST rule (Australia/Sydney) that spans the year boundary" {
  let tz = @tz.parse_posix_tz("AEST-10AEDT,M10.1.0,M4.1.0/3").unwrap()
  let southern_summer = 2_208_988_800L
  let southern_winter = 2_224_713_600L
  assert_eq(tz.offset_at(southern_summer), 39600)
  assert_eq(tz.offset_at(southern_winter), 36000)
}

///|
test "offset_from_local reports Absent within the spring-forward gap and Single either side of it" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let before_gap = @core.NaiveDateTime::from_timestamp(
    dst_start - 18000L - 1L,
    0,
  ).unwrap()
  let in_gap = @core.NaiveDateTime::from_timestamp(dst_start - 18000L, 0).unwrap()
  let after_gap = @core.NaiveDateTime::from_timestamp(dst_start - 14400L, 0).unwrap()
  assert_eq(
    tz.offset_from_local(before_gap),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
  assert_true(tz.offset_from_local(in_gap) is @tz.Absent)
  assert_eq(
    tz.offset_from_local(after_gap),
    @tz.Single(@tz.FixedOffset::east(-14400).unwrap()),
  )
}

///|
test "offset_from_local reports Ambiguous within the fall-back fold" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_end = 2_172_722_400L
  let in_fold = @core.NaiveDateTime::from_timestamp(dst_end - 16000L, 0).unwrap()
  assert_eq(
    tz.offset_from_local(in_fold),
    @tz.Ambiguous(
      @tz.FixedOffset::east(-14400).unwrap(),
      @tz.FixedOffset::east(-18000).unwrap(),
    ),
  )
}
