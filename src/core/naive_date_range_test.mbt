///|
fn first_representable_date() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(-5875671, 4, 25).unwrap()
}

///|
fn last_representable_date() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(5879610, 9, 9).unwrap()
}

///|
test "from_ymd accepts the first and last representable days and rejects the days beyond them" {
  assert_eq(first_representable_date().epoch_days(), -2146764179)
  assert_eq(last_representable_date().epoch_days(), 2146764179)
  assert_eq(@core.NaiveDate::from_ymd(-5875671, 4, 24), None)
  assert_eq(@core.NaiveDate::from_ymd(5879610, 9, 10), None)
  assert_eq(@core.NaiveDate::from_ymd(5879611, 1, 1), None)
  assert_eq(@core.NaiveDate::from_ymd(-5875672, 12, 31), None)
}

///|
test "from_ymd rejects a year far outside the range instead of wrapping into another year" {
  for
    year in [
      6_000_000, 100_000_000, 2_000_000_000, 2_147_483_647, -6_000_000, -100_000_000,
      -2_000_000_000, -2_147_483_648,
    ] {
    assert_eq(@core.NaiveDate::from_ymd(year, 6, 15), None)
  }
}

///|
test "from_yo accepts the last representable day and rejects years and days beyond the range" {
  let last = last_representable_date()
  assert_eq(@core.NaiveDate::from_yo(5879610, last.ordinal()), Some(last))
  assert_eq(@core.NaiveDate::from_yo(5879610, last.ordinal() + 1), None)
  let first = first_representable_date()
  assert_eq(@core.NaiveDate::from_yo(-5875671, first.ordinal()), Some(first))
  assert_eq(@core.NaiveDate::from_yo(-5875671, first.ordinal() - 1), None)
  for year in [6_000_000, 2_000_000_000, -6_000_000, -2_147_483_648] {
    assert_eq(@core.NaiveDate::from_yo(year, 100), None)
  }
}

///|
test "from_isoywd rejects a week whose date lies outside the range" {
  for
    year in [
      6_000_000, 2_000_000_000, 2_147_483_647, -6_000_000, -2_147_483_648,
    ] {
    assert_eq(@core.NaiveDate::from_isoywd(year, 10, Mon), None)
  }
  assert_eq(@core.NaiveDate::from_isoywd(5879610, 52, Fri), None)
}

///|
test "from_isoywd reads back the ISO week of every day within a week of both ends of the range" {
  for offset in 0..<7 {
    for
      edge in [
        @core.NaiveDate::from_epoch_days(-2146764179 + offset).unwrap(),
        @core.NaiveDate::from_epoch_days(2146764179 - offset).unwrap(),
      ] {
      let iso = edge.iso_week()
      assert_eq(
        @core.NaiveDate::from_isoywd(iso.year(), iso.week(), edge.weekday()),
        Some(edge),
      )
    }
  }
}

///|
test "with_year, with_month and with_day reject a result outside the range" {
  let last = last_representable_date()
  assert_eq(last.with_year(5879611), None)
  assert_eq(last.with_year(-6_000_000), None)
  assert_eq(last.with_month(10), None)
  assert_eq(last.with_day(10), None)
  assert_eq(last.with_ordinal(last.ordinal() + 1), None)
}

///|
test "calendar accessors agree with the day count at both ends of the range" {
  for edge in [first_representable_date(), last_representable_date()] {
    let (year, month, day) = edge.ymd()
    assert_eq(@core.NaiveDate::from_ymd(year, month.number(), day), Some(edge))
    assert_eq(@core.NaiveDate::from_yo(year, edge.ordinal()), Some(edge))
  }
}
