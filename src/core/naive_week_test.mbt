///|
test "week with a Monday start resolves first_day to the Monday on or before the date" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  let week = date.week(@core.Mon)
  assert_eq(week.first_day(), @core.NaiveDate::from_ymd(2024, 2, 26).unwrap())
}

///|
test "week with a Sunday start resolves first_day to the Sunday on or before the date" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  let week = date.week(@core.Sun)
  assert_eq(week.first_day(), @core.NaiveDate::from_ymd(2024, 2, 25).unwrap())
}

///|
test "week resolves first_day to the date itself when the date already is the start weekday" {
  let monday = @core.NaiveDate::from_ymd(2024, 2, 26).unwrap()
  assert_eq(monday.week(@core.Mon).first_day(), monday)
}

///|
test "last_day is six days after first_day" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  let week = date.week(@core.Mon)
  assert_eq(week.last_day(), @core.NaiveDate::from_ymd(2024, 3, 3).unwrap())
}

///|
test "days lists all seven dates of the week in order from first_day to last_day" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  let week = date.week(@core.Mon)
  assert_eq(week.days(), [
    @core.NaiveDate::from_ymd(2024, 2, 26).unwrap(),
    @core.NaiveDate::from_ymd(2024, 2, 27).unwrap(),
    @core.NaiveDate::from_ymd(2024, 2, 28).unwrap(),
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
    @core.NaiveDate::from_ymd(2024, 3, 1).unwrap(),
    @core.NaiveDate::from_ymd(2024, 3, 2).unwrap(),
    @core.NaiveDate::from_ymd(2024, 3, 3).unwrap(),
  ])
}

///|
test "week spans a month boundary without gaps or duplicates" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 1).unwrap()
  let week = date.week(@core.Mon)
  assert_eq(week.first_day(), @core.NaiveDate::from_ymd(2024, 2, 26).unwrap())
  assert_eq(week.last_day(), @core.NaiveDate::from_ymd(2024, 3, 3).unwrap())
}

///|
test "weeks constructed from different dates in the same week are equal" {
  let monday_anchor = @core.NaiveDate::from_ymd(2024, 2, 26)
    .unwrap()
    .week(@core.Mon)
  let sunday_anchor = @core.NaiveDate::from_ymd(2024, 3, 3)
    .unwrap()
    .week(@core.Mon)
  assert_eq(monday_anchor, sunday_anchor)
}

///|
test "weeks with different first days are not equal" {
  let this_week = @core.NaiveDate::from_ymd(2024, 2, 29)
    .unwrap()
    .week(@core.Mon)
  let next_week = @core.NaiveDate::from_ymd(2024, 3, 7).unwrap().week(@core.Mon)
  assert_true(this_week != next_week)
}

///|
test "weeks with different start weekdays are distinct when their spans differ" {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  assert_true(date.week(@core.Mon) != date.week(@core.Sun))
}

///|
test "a later week compares greater than an earlier week" {
  let earlier = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap().week(@core.Mon)
  let later = @core.NaiveDate::from_ymd(2024, 3, 7).unwrap().week(@core.Mon)
  assert_true(earlier < later)
  assert_true(later > earlier)
}

///|
test "weeks with the same first day hash equally regardless of the anchor date and work as map keys" {
  let from_wednesday = @core.NaiveDate::from_ymd(2024, 1, 3)
    .unwrap()
    .week(@core.Mon)
  let from_friday = @core.NaiveDate::from_ymd(2024, 1, 5)
    .unwrap()
    .week(@core.Mon)
  let next_week = @core.NaiveDate::from_ymd(2024, 1, 9).unwrap().week(@core.Mon)
  assert_eq(from_wednesday, from_friday)
  assert_eq(from_wednesday.hash(), from_friday.hash())
  let seen : Map[@core.NaiveWeek, Int] = Map([])
  seen[from_wednesday] = 1
  seen[next_week] = 2
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(from_friday), Some(1))
}

///|
fn week_min_date() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(-5875671, 4, 25).unwrap()
}

///|
fn week_max_date() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(5879610, 9, 9).unwrap()
}

///|
test "week of the first representable date can be constructed for every start weekday" {
  let date = week_min_date()
  for
    start in [
      @core.Mon,
      @core.Tue,
      @core.Wed,
      @core.Thu,
      @core.Fri,
      @core.Sat,
      @core.Sun,
    ] {
    ignore(date.week(start))
  }
}

///|
test "week of the last representable date can be constructed for every start weekday" {
  let date = week_max_date()
  for
    start in [
      @core.Mon,
      @core.Tue,
      @core.Wed,
      @core.Thu,
      @core.Fri,
      @core.Sat,
      @core.Sun,
    ] {
    ignore(date.week(start))
  }
}

///|
test "a week starting on the first representable date is fully representable" {
  let date = week_min_date()
  let week = date.week(date.weekday())
  assert_eq(week.checked_first_day(), Some(date))
  assert_eq(week.first_day(), date)
  assert_eq(week.checked_last_day(), date.checked_add_days(6))
  assert_eq(week.checked_days().map(fn(days) { days.length() }), Some(7))
}

///|
test "a week reaching before the first representable date has no checked first day or days" {
  let date = week_min_date()
  let week = date.week(date.weekday().succ())
  assert_eq(week.checked_first_day(), None)
  assert_eq(week.checked_days(), None)
  assert_eq(week.checked_last_day(), date.checked_add_days(0))
}

///|
test "a week ending on the last representable date is fully representable" {
  let date = week_max_date()
  let week = date.week(date.weekday().succ())
  assert_eq(week.checked_last_day(), Some(date))
  assert_eq(week.last_day(), date)
  assert_eq(week.checked_first_day(), date.checked_sub_days(6))
  assert_eq(week.checked_days().map(fn(days) { days.length() }), Some(7))
}

///|
test "a week reaching past the last representable date has no checked last day or days" {
  let date = week_max_date()
  let week = date.week(date.weekday())
  assert_eq(week.checked_last_day(), None)
  assert_eq(week.checked_days(), None)
  assert_eq(week.checked_first_day(), Some(date))
}

///|
test "checked accessors agree with the total ones for an ordinary week" {
  let week = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap().week(@core.Mon)
  assert_eq(week.checked_first_day(), Some(week.first_day()))
  assert_eq(week.checked_last_day(), Some(week.last_day()))
  assert_eq(week.checked_days(), Some(week.days()))
}

///|
test "a week reaching before the first representable date still equals itself and orders before the next week" {
  let date = week_min_date()
  let start = date.weekday().succ()
  let week = date.week(start)
  let next = date.checked_add_days(1).unwrap().week(start)
  assert_eq(week, date.week(start))
  assert_eq(week.hash(), date.week(start).hash())
  assert_true(week != next)
  assert_true(week < next)
}

///|
test "a week reaching past the last representable date still equals itself and orders after the previous week" {
  let date = week_max_date()
  let start = date.weekday()
  let week = date.week(start)
  let previous = date.checked_sub_days(1).unwrap().week(start)
  assert_eq(week, date.week(start))
  assert_eq(week.hash(), date.week(start).hash())
  assert_true(week != previous)
  assert_true(previous < week)
}

///|
test "panic first_day of a week reaching before the first representable date aborts" {
  let date = week_min_date()
  ignore(date.week(date.weekday().succ()).first_day())
}

///|
test "panic last_day of a week reaching past the last representable date aborts" {
  let date = week_max_date()
  ignore(date.week(date.weekday()).last_day())
}
