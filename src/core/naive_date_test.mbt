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

///|
test "succ advances to the next calendar day, rolling over month and year boundaries" {
  let cases = [
    ((2023, 6, 14), (2023, 6, 15)),
    ((2023, 12, 31), (2024, 1, 1)),
    ((2023, 2, 28), (2023, 3, 1)),
    ((2024, 2, 28), (2024, 2, 29)),
  ]
  for case in cases {
    let (from, to) = case
    let (fy, fm, fd) = from
    let (ty, tm, td) = to
    assert_eq(
      @core.NaiveDate::from_ymd(fy, fm, fd).unwrap().succ(),
      @core.NaiveDate::from_ymd(ty, tm, td).unwrap(),
    )
  }
}

///|
test "pred goes back to the previous calendar day, rolling over month and year boundaries" {
  let cases = [
    ((2023, 6, 15), (2023, 6, 14)),
    ((2024, 1, 1), (2023, 12, 31)),
    ((2023, 3, 1), (2023, 2, 28)),
    ((2024, 2, 29), (2024, 2, 28)),
  ]
  for case in cases {
    let (from, to) = case
    let (fy, fm, fd) = from
    let (ty, tm, td) = to
    assert_eq(
      @core.NaiveDate::from_ymd(fy, fm, fd).unwrap().pred(),
      @core.NaiveDate::from_ymd(ty, tm, td).unwrap(),
    )
  }
}

///|
test "add_days moves forward by an arbitrary number of days, crossing month and year boundaries" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 25).unwrap()
  assert_eq(date.add_days(10), @core.NaiveDate::from_ymd(2023, 2, 4).unwrap())
  assert_eq(
    date.add_days(340),
    @core.NaiveDate::from_ymd(2023, 12, 31).unwrap(),
  )
}

///|
test "sub_days moves backward by an arbitrary number of days, crossing month and year boundaries" {
  let date = @core.NaiveDate::from_ymd(2023, 2, 4).unwrap()
  assert_eq(date.sub_days(10), @core.NaiveDate::from_ymd(2023, 1, 25).unwrap())
  assert_eq(date.sub_days(35), @core.NaiveDate::from_ymd(2022, 12, 31).unwrap())
}

///|
test "add_days and sub_days by the same count round-trip back to the original date" {
  let date = @core.NaiveDate::from_ymd(2023, 6, 15).unwrap()
  assert_eq(date.add_days(100).sub_days(100), date)
}

///|
test "add_months keeps the day when the target month is long enough" {
  let date = @core.NaiveDate::from_ymd(2023, 1, 15).unwrap()
  assert_eq(date.add_months(1), @core.NaiveDate::from_ymd(2023, 2, 15).unwrap())
}

///|
test "add_months clamps the day to the target month's length when it doesn't exist" {
  assert_eq(
    @core.NaiveDate::from_ymd(2023, 1, 31).unwrap().add_months(1),
    @core.NaiveDate::from_ymd(2023, 2, 28).unwrap(),
  )
  assert_eq(
    @core.NaiveDate::from_ymd(2024, 1, 31).unwrap().add_months(1),
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
  )
}

///|
test "add_months crosses a year boundary when the month count overflows 12" {
  assert_eq(
    @core.NaiveDate::from_ymd(2023, 11, 15).unwrap().add_months(3),
    @core.NaiveDate::from_ymd(2024, 2, 15).unwrap(),
  )
}

///|
test "add_months with a negative count moves backward, crossing a year boundary" {
  assert_eq(
    @core.NaiveDate::from_ymd(2023, 1, 15).unwrap().add_months(-2),
    @core.NaiveDate::from_ymd(2022, 11, 15).unwrap(),
  )
}

///|
test "sub_months clamps the day to the target month's length and crosses a year boundary" {
  assert_eq(
    @core.NaiveDate::from_ymd(2023, 3, 31).unwrap().sub_months(1),
    @core.NaiveDate::from_ymd(2023, 2, 28).unwrap(),
  )
  assert_eq(
    @core.NaiveDate::from_ymd(2023, 1, 15).unwrap().sub_months(2),
    @core.NaiveDate::from_ymd(2022, 11, 15).unwrap(),
  )
}

///|
test "add_months is consistent across a proleptic year-zero boundary" {
  assert_eq(
    @core.NaiveDate::from_ymd(1, 1, 15).unwrap().sub_months(1),
    @core.NaiveDate::from_ymd(0, 12, 15).unwrap(),
  )
}

///|
test "a later date compares greater than an earlier one" {
  let d1 = @core.NaiveDate::from_ymd(2024, 1, 1).unwrap()
  let d2 = @core.NaiveDate::from_ymd(2024, 6, 15).unwrap()
  assert_true(d1 < d2)
  assert_true(d2 > d1)
  assert_true(d1.compare(d2) < 0)
}

///|
test "equal dates compare as neither less nor greater" {
  let d1 = @core.NaiveDate::from_ymd(2024, 1, 1).unwrap()
  let d2 = @core.NaiveDate::from_ymd(2024, 1, 1).unwrap()
  assert_true(d1 <= d2)
  assert_true(d1 >= d2)
  assert_eq(d1.compare(d2), 0)
}

///|
test "years_since counts a full elapsed year once the month and day have both passed" {
  let base = @core.NaiveDate::from_ymd(2014, 1, 1).unwrap()
  let date = @core.NaiveDate::from_ymd(2016, 1, 1).unwrap()
  assert_eq(date.years_since(base), Some(2))
}

///|
test "years_since does not count the current year until the base month and day recur" {
  let base = @core.NaiveDate::from_ymd(2020, 6, 15).unwrap()
  let just_before = @core.NaiveDate::from_ymd(2023, 6, 14).unwrap()
  let just_after = @core.NaiveDate::from_ymd(2023, 6, 16).unwrap()
  assert_eq(just_before.years_since(base), Some(2))
  assert_eq(just_after.years_since(base), Some(3))
}

///|
test "years_since is zero for the same date" {
  let date = @core.NaiveDate::from_ymd(2020, 6, 15).unwrap()
  assert_eq(date.years_since(date), Some(0))
}

///|
test "years_since is none when self is before base" {
  let base = @core.NaiveDate::from_ymd(2020, 6, 15).unwrap()
  let earlier = @core.NaiveDate::from_ymd(2019, 6, 15).unwrap()
  assert_eq(earlier.years_since(base), None)
}

///|
test "from_weekday_of_month finds the nth occurrence of a weekday in a month" {
  assert_eq(
    @core.NaiveDate::from_weekday_of_month(2017, 3, @core.Fri, 2),
    @core.NaiveDate::from_ymd(2017, 3, 10),
  )
}

///|
test "from_weekday_of_month finds the first occurrence when n is 1" {
  assert_eq(
    @core.NaiveDate::from_weekday_of_month(2017, 3, @core.Fri, 1),
    @core.NaiveDate::from_ymd(2017, 3, 3),
  )
}

///|
test "from_weekday_of_month rejects a non-positive n" {
  assert_eq(@core.NaiveDate::from_weekday_of_month(2017, 3, @core.Fri, 0), None)
  assert_eq(
    @core.NaiveDate::from_weekday_of_month(2017, 3, @core.Fri, -1),
    None,
  )
}

///|
test "from_weekday_of_month rejects an occurrence that doesn't exist in the month" {
  assert_eq(@core.NaiveDate::from_weekday_of_month(2023, 4, @core.Mon, 5), None)
}

///|
test "from_weekday_of_month rejects an invalid month" {
  assert_eq(
    @core.NaiveDate::from_weekday_of_month(2017, 13, @core.Fri, 1),
    None,
  )
}

///|
test "quarter reports 1 through 4 across the year" {
  for case in [(1, 1), (3, 1), (4, 2), (6, 2), (7, 3), (9, 3), (10, 4), (12, 4)] {
    let (month, expected) = case
    assert_eq(
      @core.NaiveDate::from_ymd(2024, month, 1).unwrap().quarter(),
      expected,
    )
  }
}

///|
test "add_signed moves a date forward across a month boundary by whole days" {
  let date = @core.NaiveDate::from_ymd(2024, 1, 30).unwrap()
  let result = date.add_signed(@core.TimeDelta::days(3L).unwrap())
  assert_eq(result, @core.NaiveDate::from_ymd(2024, 2, 2))
}

///|
test "add_signed with a negative duration moves a date backward" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 1).unwrap()
  let result = date.add_signed(@core.TimeDelta::days(-1L).unwrap())
  assert_eq(result, @core.NaiveDate::from_ymd(2024, 2, 29))
}

///|
test "add_signed truncates a sub-day remainder toward zero" {
  let date = @core.NaiveDate::from_ymd(2024, 5, 10).unwrap()
  assert_eq(
    date.add_signed(@core.TimeDelta::hours(36L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 5, 11),
  )
  assert_eq(
    date.add_signed(@core.TimeDelta::hours(-36L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 5, 9),
  )
  assert_eq(date.add_signed(@core.TimeDelta::hours(23L).unwrap()), Some(date))
  assert_eq(date.add_signed(@core.TimeDelta::hours(-23L).unwrap()), Some(date))
}

///|
test "sub_signed is the inverse of add_signed" {
  let date = @core.NaiveDate::from_ymd(2024, 5, 10).unwrap()
  let delta = @core.TimeDelta::days(400L).unwrap()
  assert_eq(date.add_signed(delta).unwrap().sub_signed(delta), Some(date))
  assert_eq(
    date.sub_signed(@core.TimeDelta::days(10L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 4, 30),
  )
}

///|
test "add_signed rejects a duration whose day count exceeds the representable date range" {
  let date = @core.NaiveDate::from_ymd(2024, 5, 10).unwrap()
  assert_eq(date.add_signed(@core.TimeDelta::max_value()), None)
  assert_eq(date.add_signed(@core.TimeDelta::min_value()), None)
  assert_eq(date.sub_signed(@core.TimeDelta::max_value()), None)
  assert_eq(date.sub_signed(@core.TimeDelta::min_value()), None)
}

///|
test "add_signed reaches the representable range boundary on both sides and rejects one day past it" {
  let epoch = @core.NaiveDate::from_ymd(1970, 1, 1).unwrap()
  let limit = 2_147_483_647L - 719_468L
  let upper = epoch.add_signed(@core.TimeDelta::days(limit).unwrap()).unwrap()
  let lower = epoch.add_signed(@core.TimeDelta::days(-limit).unwrap()).unwrap()
  assert_true(upper.year() > 5_000_000)
  assert_true(lower.year() < -5_000_000)
  assert_eq(upper.succ().pred(), upper)
  assert_eq(epoch.add_signed(@core.TimeDelta::days(limit + 1L).unwrap()), None)
  assert_eq(epoch.add_signed(@core.TimeDelta::days(-limit - 1L).unwrap()), None)
}

///|
test "signed_duration_since counts whole days between two dates" {
  let a = @core.NaiveDate::from_ymd(2024, 3, 1).unwrap()
  let b = @core.NaiveDate::from_ymd(2024, 2, 1).unwrap()
  assert_eq(a.signed_duration_since(b), @core.TimeDelta::days(29L).unwrap())
  assert_eq(b.signed_duration_since(a), @core.TimeDelta::days(-29L).unwrap())
}

///|
test "signed_duration_since reports zero for a date against itself" {
  let a = @core.NaiveDate::from_ymd(2024, 3, 1).unwrap()
  assert_true(a.signed_duration_since(a).is_zero())
}

///|
test "signed_duration_since is the inverse of add_signed" {
  let a = @core.NaiveDate::from_ymd(2000, 2, 29).unwrap()
  let b = @core.NaiveDate::from_ymd(2024, 12, 31).unwrap()
  assert_eq(a.add_signed(b.signed_duration_since(a)), Some(b))
}

///|
test "signed_duration_since spans the full representable range without overflow" {
  let epoch = @core.NaiveDate::from_ymd(1970, 1, 1).unwrap()
  let limit = 2_147_483_647L - 719_468L
  let upper = epoch.add_signed(@core.TimeDelta::days(limit).unwrap()).unwrap()
  let lower = epoch.add_signed(@core.TimeDelta::days(-limit).unwrap()).unwrap()
  assert_eq(
    upper.signed_duration_since(lower),
    @core.TimeDelta::days(2L * limit).unwrap(),
  )
}
