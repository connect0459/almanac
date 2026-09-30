///|
test "MappedLocalTime distinguishes Single, Ambiguous, and Absent as unequal" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_true(@tz.Single(a) != @tz.Single(b))
  assert_true(@tz.Single(a) != @tz.Ambiguous(a, b))
  assert_true(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]) != @tz.Single(a),
  )
  assert_eq(@tz.Ambiguous(a, b), @tz.Ambiguous(a, b))
}

///|
test "single returns the offset only when the result is unambiguous" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).single(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).single(), None)
  assert_eq((@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).single(), None)
}

///|
test "earliest returns the first offset of an ambiguous fold" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).earliest(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).earliest(), Some(a))
  assert_eq(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).earliest(),
    None,
  )
}

///|
test "latest returns the second offset of an ambiguous fold" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).latest(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).latest(), Some(b))
  assert_eq((@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).latest(), None)
}

///|
test "map transforms every offset carried by the result" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  let bump = fn(offset : @tz.FixedOffset) -> @tz.FixedOffset {
    @tz.FixedOffset::east(offset.local_minus_utc() + 1).unwrap()
  }
  assert_eq(@tz.Single(a).map(bump), @tz.Single(bump(a)))
  assert_eq(@tz.Ambiguous(a, b).map(bump), @tz.Ambiguous(bump(a), bump(b)))
  assert_eq(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).map(bump),
    @tz.Absent,
  )
}

///|
fn naive_at(
  y : Int,
  mo : Int,
  d : Int,
  h : Int,
  mi : Int,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(y, mo, d).unwrap(),
    @core.NaiveTime::from_hms(h, mi, 0).unwrap(),
  )
}

///|
test "from_utc_datetime interprets the naive datetime as UTC and attaches the zone" {
  let naive = naive_at(2024, 6, 15, 12, 0)
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = tokyo.from_utc_datetime(naive)
  assert_eq(dt.naive_utc(), naive)
  assert_eq(dt.naive_local(), naive_at(2024, 6, 15, 21, 0))
  assert_eq(dt.timezone(), tokyo)
  assert_eq(@tz.Utc::new().from_utc_datetime(naive).naive_local(), naive)
}

///|
test "from_local_datetime interprets the naive datetime as wall-clock time in the zone" {
  let naive = naive_at(2024, 6, 15, 12, 0)
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = tokyo.from_local_datetime(naive).single().unwrap()
  assert_eq(dt.naive_local(), naive)
  assert_eq(dt.naive_utc(), naive_at(2024, 6, 15, 3, 0))
  assert_eq(
    @tz.Utc::new().from_local_datetime(naive).single().unwrap().naive_utc(),
    naive,
  )
}

///|
test "from_local_datetime reports Absent in a spring-forward gap and Ambiguous in a fall-back fold (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  assert_true(
    ny.from_local_datetime(naive_at(2024, 3, 10, 2, 30)) is @tz.Absent,
  )
  let fold = ny.from_local_datetime(naive_at(2024, 11, 3, 1, 30))
  assert_eq(
    fold.earliest().unwrap().compare_instant(fold.latest().unwrap()),
    -1,
  )
  assert_eq(
    ny.from_utc_datetime(naive_at(2024, 7, 1, 16, 0)).naive_local(),
    naive_at(2024, 7, 1, 12, 0),
  )
}

///|
fn[Tz : @tz.TimeZone] resolve_abbreviation(
  tz : Tz,
  abbreviation : String,
  near : @core.NaiveDateTime,
) -> @tz.FixedOffset? {
  tz.offset_from_abbreviation(abbreviation, near)
}

///|
test "offset_from_abbreviation resolves a Location's abbreviation through the TimeZone trait" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let winter = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(
    resolve_abbreviation(ny, "EDT", winter),
    @tz.FixedOffset::east(-4 * 3600),
  )
  assert_eq(resolve_abbreviation(ny, "XYZ", winter), None)
}

///|
test "offset_from_abbreviation resolves a PosixTz's standard and DST names" {
  let rule = @tz.parse_posix_tz("FOO5BAR4,M3.2.0,M11.1.0").unwrap()
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(
    rule.offset_from_abbreviation("FOO", any),
    @tz.FixedOffset::east(-5 * 3600),
  )
  assert_eq(
    rule.offset_from_abbreviation("BAR", any),
    @tz.FixedOffset::east(-4 * 3600),
  )
  assert_eq(rule.offset_from_abbreviation("EST", any), None)
  let jst = @tz.parse_posix_tz("JST-9").unwrap()
  assert_eq(
    jst.offset_from_abbreviation("JST", any),
    @tz.FixedOffset::east(9 * 3600),
  )
}

///|
test "offset_from_abbreviation is None for zones that carry no abbreviation of their own" {
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(@tz.Utc::new().offset_from_abbreviation("UTC", any), None)
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  assert_eq(tokyo.offset_from_abbreviation("+09:00", any), None)
}

///|
test "unwrap returns the value of an unambiguous local time" {
  let mapped : @tz.MappedLocalTime[Int] = @tz.Single(7)
  assert_eq(mapped.unwrap(), 7)
}

///|
test "panic unwrap aborts on a local time that occurs twice" {
  let mapped : @tz.MappedLocalTime[Int] = @tz.Ambiguous(1, 2)
  ignore(mapped.unwrap())
}

///|
test "panic unwrap aborts on a local time that never occurs" {
  let mapped : @tz.MappedLocalTime[Int] = @tz.Absent
  ignore(mapped.unwrap())
}

///|
test "unwrap resolves a wall-clock reading in a zone with no daylight saving" {
  let dt = @tz.DateTime::from_ymd_hms(
    2024,
    6,
    15,
    12,
    0,
    0,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  ).unwrap()
  assert_eq(dt.naive_local().time().hour(), 12)
}
