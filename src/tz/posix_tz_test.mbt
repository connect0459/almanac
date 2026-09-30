///|
fn bounds_secs(tz : @tz.PosixTz, secs : Int64) -> (Int64, Int64)? {
  let bounds = tz.transition_bounds(utc_at(secs))
  match (bounds.start(), bounds.end()) {
    (Some(start), Some(end)) => Some((start.timestamp(), end.timestamp()))
    _ => None
  }
}

///|
test "type_at reports the standard/DST abbreviation and flag alongside the offset" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let std_type = tz.type_at(utc_at(dst_start - 1L))
  assert_eq(std_type.utc_offset(), -18000)
  assert_eq(std_type.is_dst(), false)
  assert_eq(std_type.abbreviation(), "EST")
  let dst_type = tz.type_at(utc_at(dst_start))
  assert_eq(dst_type.utc_offset(), -14400)
  assert_eq(dst_type.is_dst(), true)
  assert_eq(dst_type.abbreviation(), "EDT")
}

///|
test "parse_posix_tz parses a zone with no DST rule, type_at is constant regardless of instant" {
  let tz = @tz.parse_posix_tz("UTC0").unwrap()
  assert_eq(tz.type_at(utc_at(0L)).utc_offset(), 0)
  assert_eq(tz.type_at(utc_at(1_700_000_000L)).utc_offset(), 0)
  assert_eq(tz.type_at(utc_at(-1_700_000_000L)).utc_offset(), 0)
  assert_eq(tz.type_at(utc_at(0L)).abbreviation(), "UTC")
  assert_eq(tz.type_at(utc_at(0L)).is_dst(), false)
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
  assert_eq(tz.type_at(utc_at(0L)).utc_offset(), 32400)
  assert_eq(tz.type_at(utc_at(1_700_000_000L)).utc_offset(), 32400)
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
  assert_eq(tz.type_at(utc_at(dst_start - 1L)).utc_offset(), -18000)
  assert_eq(tz.type_at(utc_at(dst_start)).utc_offset(), -10800)
  assert_eq(tz.type_at(utc_at(dst_end - 1L)).utc_offset(), -10800)
  assert_eq(tz.type_at(utc_at(dst_end)).utc_offset(), -18000)
}

///|
test "parse_posix_tz parses minute/second-precision offsets and an explicit (non-default) rule time" {
  let tz = @tz.parse_posix_tz("STD-1DST,M3.5.0/1:30:15,M9.5.0").unwrap()
  assert_eq(tz.type_at(utc_at(1_902_484_800L)).utc_offset(), 7200)
  assert_eq(tz.type_at(utc_at(1_965_643_200L)).utc_offset(), 7200)
}

///|
test "parse_posix_tz evaluates a Julian-no-leap (Jn) rule" {
  let tz = @tz.parse_posix_tz("STD-1DST,J100,J200").unwrap()
  assert_eq(tz.type_at(utc_at(1_906_372_800L)).utc_offset(), 7200)
  assert_eq(tz.type_at(utc_at(1_915_012_800L)).utc_offset(), 3600)
}

///|
test "parse_posix_tz evaluates a Julian-with-leap (n) rule" {
  let tz = @tz.parse_posix_tz("STD-1DST,99,199").unwrap()
  assert_eq(tz.type_at(utc_at(1_906_372_800L)).utc_offset(), 7200)
  assert_eq(tz.type_at(utc_at(1_915_012_800L)).utc_offset(), 3600)
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
test "type_at resolves a non-wraparound DST rule (America/New_York) either side of both transitions" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let dst_end = 2_172_722_400L
  assert_eq(tz.type_at(utc_at(dst_start - 1L)).utc_offset(), -18000)
  assert_eq(tz.type_at(utc_at(dst_start)).utc_offset(), -14400)
  assert_eq(tz.type_at(utc_at(dst_end - 1L)).utc_offset(), -14400)
  assert_eq(tz.type_at(utc_at(dst_end)).utc_offset(), -18000)
}

///|
test "type_at resolves a wraparound DST rule (Australia/Sydney) that spans the year boundary" {
  let tz = @tz.parse_posix_tz("AEST-10AEDT,M10.1.0,M4.1.0/3").unwrap()
  let southern_summer = 2_208_988_800L
  let southern_winter = 2_224_713_600L
  assert_eq(tz.type_at(utc_at(southern_summer)).utc_offset(), 39600)
  assert_eq(tz.type_at(utc_at(southern_winter)).utc_offset(), 36000)
}

///|
test "transition_bounds reports None when the rule has no DST component" {
  let tz = @tz.parse_posix_tz("JST-9").unwrap()
  assert_eq(bounds_secs(tz, 0L), None)
}

///|
test "transition_bounds computes the exact DST interval bounds for a non-wraparound rule (America/New_York)" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_start = 2_152_162_800L
  let dst_end = 2_172_722_400L
  assert_eq(bounds_secs(tz, dst_start), Some((dst_start, dst_end)))
}

///|
test "transition_bounds computes the exact standard-time interval bounds spanning a year boundary (America/New_York)" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let dst_end_2038 = 2_172_722_400L
  let dst_start_2039 = 2_183_612_400L
  assert_eq(bounds_secs(tz, dst_end_2038), Some((dst_end_2038, dst_start_2039)))
}

///|
test "transition_bounds computes the exact DST interval bounds for a wraparound rule spanning a year boundary (Australia/Sydney)" {
  let tz = @tz.parse_posix_tz("AEST-10AEDT,M10.1.0,M4.1.0/3").unwrap()
  let southern_summer = 2_208_988_800L
  let dst_start_2039 = 2_201_097_600L
  let dst_end_2040 = 2_216_822_400L
  assert_eq(
    bounds_secs(tz, southern_summer),
    Some((dst_start_2039, dst_end_2040)),
  )
}

///|
test "transition_bounds computes the exact standard-time interval bounds for a wraparound rule (Australia/Sydney)" {
  let tz = @tz.parse_posix_tz("AEST-10AEDT,M10.1.0,M4.1.0/3").unwrap()
  let southern_winter = 2_224_713_600L
  let dst_end_2040 = 2_216_822_400L
  let dst_start_2040 = 2_233_152_000L
  assert_eq(
    bounds_secs(tz, southern_winter),
    Some((dst_end_2040, dst_start_2040)),
  )
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

///|
test "PosixTz as a TimeZone reports the offset and abbreviation in effect at a UTC instant (EST5EDT)" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let winter = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  assert_eq(
    tz.offset_from_utc(winter),
    @tz.FixedOffset::east(-5 * 3600).unwrap(),
  )
  assert_eq(
    tz.offset_from_utc(summer),
    @tz.FixedOffset::east(-4 * 3600).unwrap(),
  )
  assert_eq(tz.tz_name(winter), "EST")
  assert_eq(tz.tz_name(summer), "EDT")
}

///|
test "PosixTz as a TimeZone resolves a local reading to Single, Absent in a gap and Ambiguous in a fold" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let reading = fn(y, mo, d, h, mi) {
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(y, mo, d).unwrap(),
      @core.NaiveTime::from_hms(h, mi, 0).unwrap(),
    )
  }
  assert_true(
    tz.offset_from_local(reading(2024, 7, 1, 12, 0)).single() is Some(_),
  )
  assert_true(
    @tz.DateTime::from_local(reading(2024, 3, 10, 2, 30), tz) is @tz.Absent,
  )
  let fold = @tz.DateTime::from_local(reading(2024, 11, 3, 1, 30), tz)
  assert_eq(
    fold.earliest().unwrap().compare_instant(fold.latest().unwrap()),
    -1,
  )
}

///|
test "PosixTz without a DST rule is a constant-offset TimeZone (JST-9)" {
  let tz = @tz.parse_posix_tz("JST-9").unwrap()
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(tz.offset_from_utc(any), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(tz.tz_name(any), "JST")
  let dt = @tz.DateTime::from_timestamp(0L, 0, tz).unwrap()
  assert_eq(dt.naive_local().hour(), 9)
}

///|
test "PosixTz has a Debug representation" {
  let tz = @tz.parse_posix_tz("JST-9").unwrap()
  debug_inspect(
    tz,
    content=(
      #|{
      #|  std_offset: 32400,
      #|  std_name: "JST",
      #|  dst_offset: None,
      #|  dst_name: None,
      #|  rule: None,
      #|}
    ),
  )
}

///|
test "parse_posix_tz rejects an offset FixedOffset cannot represent instead of aborting later" {
  assert_true(@tz.parse_posix_tz("XXX-99") is None)
  assert_true(@tz.parse_posix_tz("XXX24:00:00") is None)
  assert_true(@tz.parse_posix_tz("XXX-24:00:00") is None)
  assert_true(@tz.parse_posix_tz("XXX-23:59:59") is Some(_))
  assert_true(@tz.parse_posix_tz("XXX23:59:59") is Some(_))
  assert_true(@tz.parse_posix_tz("AAA0BBB-99,M3.2.0,M11.1.0") is None)
  assert_true(@tz.parse_posix_tz("AAA-23:59:59BBB,M3.2.0,M11.1.0") is None)
}
