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
