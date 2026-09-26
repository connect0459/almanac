///|
test "from_tzif_bytes rejects malformed TZif data" {
  assert_true(@tz.Location::from_tzif_bytes(Bytes::make(44, b'\x00')) is None)
}

///|
test "offset_from_utc uses the first non-DST local time type before the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let just_before = @core.NaiveDateTime::from_timestamp(-2_717_650_801L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(just_before),
    @tz.FixedOffset::east(-17762).unwrap(),
  )
}

///|
test "offset_from_utc uses the table for an instant at and after the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let at_first = @core.NaiveDateTime::from_timestamp(-2_717_650_800L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(at_first),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc resolves a known recent DST transition from the table (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start = 1_710_054_000L
  let dst_end = 1_730_613_600L
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_start - 1L, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_start, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_end - 1L, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(@core.NaiveDateTime::from_timestamp(dst_end, 0).unwrap()),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc uses the table at and before the last recorded transition, and the POSIX rule strictly after it" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let last = @core.NaiveDateTime::from_timestamp(2_140_668_000L, 0).unwrap()
  assert_eq(ny.offset_from_utc(last), @tz.FixedOffset::east(-18000).unwrap())
  let summer_2040 = @core.NaiveDateTime::from_timestamp(2_224_713_600L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(summer_2040),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  let winter_2040 = @core.NaiveDateTime::from_timestamp(2_208_988_800L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(winter_2040),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc is constant for a zone with no transitions (UTC)" {
  let utc = @tz.Location::from_tzif_bytes(tzif_utc).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  assert_eq(utc.offset_from_utc(dt), @tz.FixedOffset::east(0).unwrap())
}

///|
test "offset_from_local reports Absent within a real spring-forward gap and Single either side of it (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start = 1_710_054_000L
  let before_gap = @core.NaiveDateTime::from_timestamp(
    dst_start - 18000L - 1L,
    0,
  ).unwrap()
  let in_gap = @core.NaiveDateTime::from_timestamp(dst_start - 18000L, 0).unwrap()
  let after_gap = @core.NaiveDateTime::from_timestamp(dst_start - 14400L, 0).unwrap()
  assert_eq(
    ny.offset_from_local(before_gap),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
  assert_true(ny.offset_from_local(in_gap) is @tz.Absent)
  assert_eq(
    ny.offset_from_local(after_gap),
    @tz.Single(@tz.FixedOffset::east(-14400).unwrap()),
  )
}

///|
test "offset_from_local reports Ambiguous within a real fall-back fold (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_end = 1_730_613_600L
  let in_fold = @core.NaiveDateTime::from_timestamp(dst_end - 16000L, 0).unwrap()
  assert_eq(
    ny.offset_from_local(in_fold),
    @tz.Ambiguous(
      @tz.FixedOffset::east(-14400).unwrap(),
      @tz.FixedOffset::east(-18000).unwrap(),
    ),
  )
}

///|
test "offset_from_local delegates to the POSIX rule strictly past the last recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let summer_2040 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2040, 7, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(summer_2040),
    @tz.Single(@tz.FixedOffset::east(-14400).unwrap()),
  )
}

///|
test "offset_from_local is a single unambiguous resolution before the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let colonial_era = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1800, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(colonial_era),
    @tz.Single(@tz.FixedOffset::east(-17762).unwrap()),
  )
}

///|
test "from_tzif_bytes rejects a well-formed TZif file whose POSIX footer is malformed" {
  assert_true(@tz.Location::from_tzif_bytes(tzif_bad_posix_footer) is None)
}

///|
test "initial_type falls back to the first local time type when every type observes DST" {
  let loc = @tz.Location::from_tzif_bytes(tzif_all_dst_types).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  assert_eq(loc.offset_from_utc(dt), @tz.FixedOffset::east(3600).unwrap())
}

///|
test "offset_from_local resolves a local reading in the very first recorded segment" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let year1900 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1900, 6, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(year1900),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
}

///|
test "offset_from_local reports Ambiguous within a real fall-back fold in a positive-offset zone (Australia/Sydney)" {
  let sydney = @tz.Location::from_tzif_bytes(tzif_sydney).unwrap()
  let fold_end = 1_712_419_200L
  let in_fold = @core.NaiveDateTime::from_timestamp(fold_end + 37000L, 0).unwrap()
  assert_eq(
    sydney.offset_from_local(in_fold),
    @tz.Ambiguous(
      @tz.FixedOffset::east(39600).unwrap(),
      @tz.FixedOffset::east(36000).unwrap(),
    ),
  )
}

///|
test "offset_from_local reports Absent (not Ambiguous) when a local reading matches two non-adjacent segments but not the segment between them" {
  let loc = @tz.Location::from_tzif_bytes(tzif_pathological_close_transitions).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(25L, 0).unwrap()
  assert_true(loc.offset_from_local(dt) is @tz.Absent)
}

///|
test "offset_from_local resolves via the previous segment alone when the naive lookup's own segment and its next neighbor both fail to apply" {
  let loc = @tz.Location::from_tzif_bytes(tzif_prev_only_candidate).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(10L, 0).unwrap()
  assert_eq(
    loc.offset_from_local(dt),
    @tz.Single(@tz.FixedOffset::east(10).unwrap()),
  )
}

///|
test "a zone with no POSIX footer clamps to its last recorded transition's type past it" {
  let loc = @tz.Location::from_tzif_bytes(tzif_v1_only_with_transitions).unwrap()
  let far_future = @core.NaiveDateTime::from_timestamp(2_000_000_000L, 0).unwrap()
  assert_eq(
    loc.offset_from_utc(far_future),
    @tz.FixedOffset::east(3600).unwrap(),
  )
  assert_eq(
    loc.offset_from_local(far_future),
    @tz.Single(@tz.FixedOffset::east(3600).unwrap()),
  )
}
