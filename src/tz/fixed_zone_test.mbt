///|
fn jst() -> @tz.FixedZone {
  @tz.FixedZone::new("JST", @tz.FixedOffset::east(9 * 3600).unwrap())
}

///|
fn reading() -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
}

///|
test "FixedZone reports the name and offset it was built with" {
  assert_eq(jst().name(), "JST")
  assert_eq(jst().offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
}

///|
test "FixedZone resolves every instant to its single offset, never ambiguous or absent" {
  let offset = @tz.FixedOffset::east(9 * 3600).unwrap()
  assert_eq(jst().offset_from_utc(reading()), offset)
  assert_eq(jst().offset_from_local(reading()), @tz.Single(offset))
}

///|
test "FixedZone's tz_name is its own name rather than the offset text" {
  assert_eq(jst().tz_name(reading()), "JST")
}

///|
test "FixedZone never observes daylight saving and has unbounded transition bounds" {
  assert_eq(jst().is_dst(reading()), false)
  assert_eq(jst().transition_bounds(reading()).start(), None)
  assert_eq(jst().transition_bounds(reading()).end(), None)
}

///|
test "FixedZone renders as its name" {
  assert_eq(jst().to_string(), "JST")
}

///|
test "FixedZone values with the same name and offset are equal and hash alike" {
  let same = @tz.FixedZone::new("JST", @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(jst(), same)
  assert_eq(jst().hash(), same.hash())
}

///|
test "FixedZone values differing in name or offset are not equal, even when the offset matches" {
  let offset = @tz.FixedOffset::east(9 * 3600).unwrap()
  assert_true(jst() != @tz.FixedZone::new("KST", offset))
  assert_true(
    jst() != @tz.FixedZone::new("JST", @tz.FixedOffset::east(0).unwrap()),
  )
}

///|
test "a DateTime in a FixedZone shifts local time by the offset and keeps the zone name" {
  let dt = @tz.DateTime::from_utc(reading(), jst())
  assert_eq(dt.naive_local().time().hour(), 21)
  assert_eq(dt.timezone().name(), "JST")
}

///|
test "FixedZone resolves its own name as an abbreviation and no other" {
  let offset = @tz.FixedOffset::east(9 * 3600).unwrap()
  assert_eq(jst().offset_from_abbreviation("JST", reading()), Some(offset))
  assert_eq(jst().offset_from_abbreviation("KST", reading()), None)
}
