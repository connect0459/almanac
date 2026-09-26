///|
test "from_ymd constructs a date whose accessors report back year, month, and day" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  assert_eq(date.year(), 2024)
  assert_eq(date.month(), @core.Feb)
  assert_eq(date.day(), 29)
}

///|
test "from_ymd rejects a month outside 1..=12" {
  assert_eq(@core.NaiveDate::from_ymd(2024, 0, 1), None)
  assert_eq(@core.NaiveDate::from_ymd(2024, 13, 1), None)
}

///|
test "from_ymd rejects a day outside the target month's length" {
  assert_eq(@core.NaiveDate::from_ymd(2024, 4, 31), None)
  assert_eq(@core.NaiveDate::from_ymd(2024, 1, 0), None)
}

///|
test "from_ymd rejects February 29 in a non-leap year but accepts it in a leap year" {
  assert_eq(@core.NaiveDate::from_ymd(2023, 2, 29), None)
  assert_true(@core.NaiveDate::from_ymd(2024, 2, 29) is Some(_))
}

///|
test "from_yo resolves ordinal day 1 to January 1st" {
  let date = @core.NaiveDate::from_yo(2023, 1).unwrap()
  assert_eq(date.year(), 2023)
  assert_eq(date.month(), @core.Jan)
  assert_eq(date.day(), 1)
}

///|
test "from_yo resolves ordinal day 60 to March 1st, accounting for leap years" {
  assert_eq(@core.NaiveDate::from_yo(2023, 60).unwrap().month(), @core.Mar)
  assert_eq(@core.NaiveDate::from_yo(2023, 60).unwrap().day(), 1)
  assert_eq(@core.NaiveDate::from_yo(2024, 60).unwrap().month(), @core.Feb)
  assert_eq(@core.NaiveDate::from_yo(2024, 60).unwrap().day(), 29)
}

///|
test "from_yo rejects ordinal day 0 and rejects day 366 in a non-leap year" {
  assert_eq(@core.NaiveDate::from_yo(2023, 0), None)
  assert_eq(@core.NaiveDate::from_yo(2023, 366), None)
  assert_true(@core.NaiveDate::from_yo(2024, 366) is Some(_))
}

///|
test "ordinal round-trips through from_yo" {
  for
    case in [
      (2023, 1),
      (2023, 60),
      (2023, 365),
      (2024, 1),
      (2024, 60),
      (2024, 366),
    ] {
    let (year, ordinal) = case
    assert_eq(
      @core.NaiveDate::from_yo(year, ordinal).unwrap().ordinal(),
      ordinal,
    )
  }
}

///|
test "weekday reports the correct day of week for known reference dates" {
  let cases = [
    (1970, 1, 1, @core.Thu),
    (2000, 1, 1, @core.Sat),
    (2023, 1, 1, @core.Sun),
    (2024, 1, 1, @core.Mon),
    (1900, 1, 1, @core.Mon),
  ]
  for case in cases {
    let (year, month, day, expected) = case
    assert_eq(
      @core.NaiveDate::from_ymd(year, month, day).unwrap().weekday(),
      expected,
    )
  }
}

///|
test "weekday cycles through every day of the week across a span before the Unix epoch" {
  let cases = [
    (1969, 12, 25, @core.Thu),
    (1969, 12, 26, @core.Fri),
    (1969, 12, 27, @core.Sat),
    (1969, 12, 28, @core.Sun),
    (1969, 12, 29, @core.Mon),
    (1969, 12, 30, @core.Tue),
    (1969, 12, 31, @core.Wed),
  ]
  for case in cases {
    let (year, month, day, expected) = case
    assert_eq(
      @core.NaiveDate::from_ymd(year, month, day).unwrap().weekday(),
      expected,
    )
  }
}

///|
test "month returns the matching Month variant for every month number" {
  let cases = [
    (1, @core.Jan),
    (2, @core.Feb),
    (3, @core.Mar),
    (4, @core.Apr),
    (5, @core.May),
    (6, @core.Jun),
    (7, @core.Jul),
    (8, @core.Aug),
    (9, @core.Sep),
    (10, @core.Oct),
    (11, @core.Nov),
    (12, @core.Dec),
  ]
  for case in cases {
    let (month, expected) = case
    assert_eq(
      @core.NaiveDate::from_ymd(2023, month, 1).unwrap().month(),
      expected,
    )
  }
}

///|
test "leap_year reflects the proleptic Gregorian leap-year rule for the date's year" {
  assert_true(@core.NaiveDate::from_ymd(2024, 3, 1).unwrap().leap_year())
  assert_false(@core.NaiveDate::from_ymd(2023, 3, 1).unwrap().leap_year())
  assert_false(@core.NaiveDate::from_ymd(1900, 3, 1).unwrap().leap_year())
  assert_true(@core.NaiveDate::from_ymd(2000, 3, 1).unwrap().leap_year())
}

///|
test "from_isoywd resolves a week date to the matching calendar date" {
  let cases = [
    (2015, 1, @core.Mon, 2014, 12, 29),
    (2015, 10, @core.Sun, 2015, 3, 8),
    (2015, 30, @core.Mon, 2015, 7, 20),
    (2014, 52, @core.Sun, 2014, 12, 28),
    (2015, 52, @core.Sun, 2015, 12, 27),
    (2015, 53, @core.Sun, 2016, 1, 3),
    (2016, 1, @core.Mon, 2016, 1, 4),
  ]
  for case in cases {
    let (iso_year, week, weekday, year, month, day) = case
    let expected = @core.NaiveDate::from_ymd(year, month, day).unwrap()
    assert_eq(
      @core.NaiveDate::from_isoywd(iso_year, week, weekday),
      Some(expected),
    )
  }
}

///|
test "from_isoywd rejects a week number that does not exist in that ISO year" {
  assert_eq(@core.NaiveDate::from_isoywd(2015, 60, @core.Mon), None)
  assert_eq(@core.NaiveDate::from_isoywd(2014, 53, @core.Mon), None)
  assert_eq(@core.NaiveDate::from_isoywd(2015, 0, @core.Sun), None)
}

///|
test "with_year replaces the year while keeping month and day" {
  let date = @core.NaiveDate::from_ymd(2023, 6, 15).unwrap()
  assert_eq(date.with_year(2030), @core.NaiveDate::from_ymd(2030, 6, 15))
}

///|
test "with_year rejects moving February 29 into a year that is not a leap year" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  assert_eq(date.with_year(2023), None)
  assert_eq(date.with_year(2000), @core.NaiveDate::from_ymd(2000, 2, 29))
}

///|
test "with_month replaces the month while keeping year and day" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 15).unwrap()
  assert_eq(date.with_month(6), @core.NaiveDate::from_ymd(2023, 6, 15))
}

///|
test "with_month rejects a day that does not exist in the target month" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 31).unwrap()
  assert_eq(date.with_month(4), None)
  assert_eq(date.with_month(3), @core.NaiveDate::from_ymd(2023, 3, 31))
}

///|
test "with_month rejects a month number outside 1..=12" {
  let date = @core.NaiveDate::from_ymd(2023, 6, 15).unwrap()
  assert_eq(date.with_month(0), None)
  assert_eq(date.with_month(13), None)
}

///|
test "with_day replaces the day while keeping year and month" {
  let date = @core.NaiveDate::from_ymd(2023, 6, 1).unwrap()
  assert_eq(date.with_day(15), @core.NaiveDate::from_ymd(2023, 6, 15))
}

///|
test "with_day rejects a day outside the current month's length" {
  let date = @core.NaiveDate::from_ymd(2023, 4, 1).unwrap()
  assert_eq(date.with_day(31), None)
  assert_eq(date.with_day(30), @core.NaiveDate::from_ymd(2023, 4, 30))
}

///|
test "with_ordinal replaces the ordinal day while keeping the year" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 1).unwrap()
  assert_eq(date.with_ordinal(60), @core.NaiveDate::from_yo(2023, 60))
}

///|
test "with_ordinal rejects ordinal day 366 in a year that is not a leap year" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 1).unwrap()
  assert_eq(date.with_ordinal(366), None)
  assert_eq(date.with_ordinal(365), @core.NaiveDate::from_yo(2023, 365))
}
