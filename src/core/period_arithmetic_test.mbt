///|
fn ymd(year : Int32, month : Int32, day : Int32) -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(year, month, day).unwrap()
}

///|
fn ymd_hms(
  year : Int32,
  month : Int32,
  day : Int32,
  hour : Int32,
  min : Int32,
  sec : Int32,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::from_ymd_hms(year, month, day, hour, min, sec).unwrap()
}

///|
test "adding a period of years and months keeps the day when the target month is long enough" {
  let period = @core.Period::new(years=1, months=2)
  assert_eq(ymd(2023, 1, 15).add_period(period), ymd(2024, 3, 15))
}

///|
test "adding a period clamps the day of month at month end" {
  let one_month = @core.Period::new(months=1)
  assert_eq(ymd(2023, 1, 31).add_period(one_month), ymd(2023, 2, 28))
  assert_eq(ymd(2024, 1, 31).add_period(one_month), ymd(2024, 2, 29))
}

///|
test "adding a period moves February 29 to February 28 in a non-leap year" {
  assert_eq(
    ymd(2020, 2, 29).add_period(@core.Period::new(years=1)),
    ymd(2021, 2, 28),
  )
  assert_eq(
    ymd(2020, 2, 29).add_period(@core.Period::new(years=4)),
    ymd(2024, 2, 29),
  )
}

///|
test "the days of a period are applied after its months" {
  assert_eq(
    ymd(2023, 1, 31).add_period(@core.Period::new(months=1, days=1)),
    ymd(2023, 3, 1),
  )
}

///|
test "adding a period with negative components moves the date back" {
  assert_eq(
    ymd(2023, 3, 31).add_period(@core.Period::new(months=-1)),
    ymd(2023, 2, 28),
  )
  assert_eq(
    ymd(2023, 3, 10).add_period(@core.Period::new(years=-1, days=-10)),
    ymd(2022, 2, 28),
  )
}

///|
test "adding the zero period leaves a date unchanged" {
  assert_eq(ymd(2023, 1, 31).add_period(@core.Period::zero()), ymd(2023, 1, 31))
}

///|
test "subtracting a period moves the date back by its months and then its days" {
  assert_eq(
    ymd(2023, 3, 31).sub_period(@core.Period::new(months=1)),
    ymd(2023, 2, 28),
  )
  assert_eq(
    ymd(2023, 3, 31).sub_period(@core.Period::new(months=1, days=1)),
    ymd(2023, 2, 27),
  )
  assert_eq(
    ymd(2023, 3, 31).sub_period(@core.Period::new(years=-1)),
    ymd(2024, 3, 31),
  )
}

///|
test "a period whose result leaves the date range is rejected by the checked forms" {
  assert_eq(max_date().checked_add_period(@core.Period::new(days=1)), None)
  assert_eq(max_date().checked_add_period(@core.Period::new(months=1)), None)
  assert_eq(min_date().checked_sub_period(@core.Period::new(days=1)), None)
  assert_eq(min_date().checked_add_period(@core.Period::new(years=-1)), None)
  assert_eq(
    ymd(2023, 1, 1).checked_add_period(@core.Period::new(years=2_147_483_647)),
    None,
  )
}

///|
test "the checked forms of a period agree with the plain forms inside the range" {
  let period = @core.Period::new(years=1, months=1, days=1)
  assert_eq(
    ymd(2023, 1, 31).checked_add_period(period),
    Some(ymd(2023, 1, 31).add_period(period)),
  )
  assert_eq(
    ymd(2023, 1, 31).checked_sub_period(period),
    Some(ymd(2023, 1, 31).sub_period(period)),
  )
}

///|
test "subtracting the minimum Int32 component does not overflow" {
  let period = @core.Period::new(months=-2_147_483_648)
  assert_eq(ymd(2023, 1, 1).checked_sub_period(period), None)
  assert_eq(ymd(2023, 1, 1).checked_add_period(period), None)
}

///|
test "the period from a date to itself is zero" {
  assert_eq(ymd(2023, 5, 17).until(ymd(2023, 5, 17)), @core.Period::zero())
}

///|
test "the period between dates counts whole years, then months, then days" {
  assert_eq(
    ymd(2020, 1, 15).until(ymd(2023, 3, 20)),
    @core.Period::new(years=3, months=2, days=5),
  )
}

///|
test "the period across a month end counts the largest whole months that fit" {
  assert_eq(
    ymd(2023, 1, 31).until(ymd(2023, 3, 1)),
    @core.Period::new(months=1, days=1),
  )
  assert_eq(
    ymd(2023, 1, 31).until(ymd(2023, 2, 28)),
    @core.Period::new(months=1),
  )
  assert_eq(
    ymd(2023, 1, 31).until(ymd(2023, 2, 27)),
    @core.Period::new(days=27),
  )
}

///|
test "the period across a leap day depends on whether the target year has one" {
  assert_eq(
    ymd(2020, 2, 29).until(ymd(2021, 2, 28)),
    @core.Period::new(years=1),
  )
  assert_eq(
    ymd(2020, 2, 29).until(ymd(2021, 2, 27)),
    @core.Period::new(months=11, days=29),
  )
  assert_eq(ymd(2020, 2, 28).until(ymd(2020, 3, 1)), @core.Period::new(days=2))
}

///|
test "adding the period from a date to a later date reaches that date" {
  let dates = [
    ymd(2023, 1, 31),
    ymd(2020, 2, 29),
    ymd(2023, 3, 1),
    ymd(2024, 2, 29),
    ymd(1999, 12, 31),
    ymd(2000, 1, 1),
    ymd(2023, 8, 31),
    ymd(2024, 6, 30),
  ]
  for a in dates {
    for b in dates {
      if a <= b {
        assert_eq(a.add_period(a.until(b)), b)
      }
    }
  }
}

///|
test "the period to a later date never has a negative component" {
  let dates = [
    ymd(2023, 1, 31),
    ymd(2020, 2, 29),
    ymd(2023, 3, 1),
    ymd(2024, 2, 29),
    ymd(1999, 12, 31),
  ]
  for a in dates {
    for b in dates {
      if a <= b {
        let period = a.until(b)
        assert_true(period.years() >= 0)
        assert_true(period.months() >= 0 && period.months() < 12)
        assert_true(period.days() >= 0)
      }
    }
  }
}

///|
test "the period to an earlier date is the negation of the period from it" {
  let dates = [
    ymd(2023, 1, 31),
    ymd(2020, 2, 29),
    ymd(2023, 3, 1),
    ymd(2024, 2, 29),
    ymd(1999, 12, 31),
  ]
  for a in dates {
    for b in dates {
      if a > b {
        assert_eq(a.until(b), b.until(a).checked_neg().unwrap())
      }
    }
  }
  assert_eq(
    ymd(2023, 3, 1).until(ymd(2023, 1, 31)),
    @core.Period::new(months=-1, days=-1),
  )
}

///|
test "the period across the whole date range is representable" {
  let span = min_date().until(max_date())
  assert_true(span.years() > 0)
  assert_eq(max_date().until(min_date()), span.checked_neg().unwrap())
}

///|
test "adding a period to a datetime keeps the time of day" {
  assert_eq(
    ymd_hms(2023, 1, 31, 13, 45, 10).add_period(
      @core.Period::new(months=1, days=1),
    ),
    ymd_hms(2023, 3, 1, 13, 45, 10),
  )
}

///|
test "subtracting a period from a datetime keeps the time of day" {
  assert_eq(
    ymd_hms(2023, 3, 31, 13, 45, 10).sub_period(@core.Period::new(months=1)),
    ymd_hms(2023, 2, 28, 13, 45, 10),
  )
}

///|
test "a period whose result leaves the range is rejected for a datetime by the checked forms" {
  assert_eq(max_datetime().checked_add_period(@core.Period::new(days=1)), None)
  assert_eq(
    max_datetime().checked_add_period(@core.Period::new(months=1)),
    None,
  )
  assert_eq(
    max_datetime().checked_sub_period(@core.Period::new(years=-1)),
    None,
  )
  assert_eq(
    ymd_hms(2023, 1, 1, 0, 0, 0).checked_add_period(@core.Period::new(years=1)),
    Some(ymd_hms(2024, 1, 1, 0, 0, 0)),
  )
}

///|
test "the period between datetimes with the same time of day matches their dates" {
  let a = ymd_hms(2023, 1, 31, 13, 45, 10)
  let b = ymd_hms(2023, 3, 1, 13, 45, 10)
  assert_eq(a.until(b), @core.Period::new(months=1, days=1))
  assert_eq(a.add_period(a.until(b)), b)
}

///|
test "a month is not complete in a datetime until the time of day is reached" {
  assert_eq(
    ymd_hms(2023, 1, 15, 12, 0, 0).until(ymd_hms(2023, 2, 15, 11, 59, 59)),
    @core.Period::new(days=30),
  )
  assert_eq(
    ymd_hms(2023, 1, 15, 12, 0, 0).until(ymd_hms(2023, 2, 15, 12, 0, 0)),
    @core.Period::new(months=1),
  )
}

///|
test "a day is not complete in a datetime until the time of day is reached" {
  assert_eq(
    ymd_hms(2023, 1, 15, 12, 0, 0).until(ymd_hms(2023, 1, 16, 11, 0, 0)),
    @core.Period::zero(),
  )
  assert_eq(
    ymd_hms(2023, 1, 15, 12, 0, 0).until(ymd_hms(2023, 1, 16, 12, 0, 0)),
    @core.Period::new(days=1),
  )
}

///|
test "adding the period to a later datetime never overshoots it" {
  let times = [
    ymd_hms(2023, 1, 31, 23, 0, 0),
    ymd_hms(2023, 3, 1, 1, 0, 0),
    ymd_hms(2020, 2, 29, 12, 30, 0),
    ymd_hms(2021, 2, 28, 12, 29, 59),
    ymd_hms(2021, 2, 28, 12, 30, 0),
  ]
  for a in times {
    for b in times {
      if a <= b {
        let reached = a.add_period(a.until(b))
        assert_true(reached <= b)
      }
    }
  }
}

///|
test "the period to an earlier datetime is the negation of the period from it" {
  let a = ymd_hms(2023, 3, 1, 10, 0, 0)
  let b = ymd_hms(2023, 1, 31, 10, 0, 0)
  assert_eq(a.until(b), b.until(a).checked_neg().unwrap())
  assert_eq(a.until(b), @core.Period::new(months=-1, days=-1))
}

///|
test "the period between datetimes across the whole range is representable" {
  let earliest = min_date().and_hms(0, 0, 0).unwrap()
  let span = earliest.until(max_datetime())
  assert_true(span.years() > 0)
  assert_eq(max_datetime().until(earliest), span.checked_neg().unwrap())
}

///|
test "the months of a period are applied before its days so the date between them must be in range" {
  let period = @core.Period::new(months=1, days=-31)
  assert_eq(max_date().checked_add_period(period), None)
  assert_true(
    max_date().checked_add_period(@core.Period::new(days=-31)) is Some(_),
  )
}
