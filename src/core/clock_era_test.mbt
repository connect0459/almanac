///|
fn ce_pair(year : @core.YearCe) -> (Bool, Int) {
  (year.is_ce(), year.year())
}

///|
fn clock_pair(hour : @core.ClockHour12) -> (Bool, Int) {
  (hour.is_pm(), hour.hour())
}

///|
test "year_ce and hour12 report named values that compare structurally" {
  let ce = @core.NaiveDate::from_ymd(2024, 6, 1).unwrap().year_ce()
  assert_true(ce.is_ce())
  assert_eq(ce.year(), 2024)
  assert_eq(ce, @core.NaiveDate::from_ymd(2024, 1, 1).unwrap().year_ce())
  let bce = @core.NaiveDate::from_ymd(0, 1, 1).unwrap().year_ce()
  assert_true(!bce.is_ce())
  assert_eq(bce.year(), 1)
  let noon = @core.NaiveTime::from_hms(12, 0, 0).unwrap().hour12()
  assert_true(noon.is_pm())
  assert_eq(noon.hour(), 12)
  assert_true(noon != @core.NaiveTime::from_hms(0, 0, 0).unwrap().hour12())
}
