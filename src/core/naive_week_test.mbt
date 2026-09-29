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
