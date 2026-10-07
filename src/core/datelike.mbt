///|
/// Read-only access to the calendar-date components of a value, so generic
/// code can accept a `NaiveDate`, a `NaiveDateTime` or a `DateTime` alike.
/// Implemented by `NaiveDate`, `NaiveDateTime` and `tz`'s `DateTime[Tz]`,
/// which reports its local date. Only `year`, `month`, `day`, `ordinal` and
/// `weekday` are required; the rest derive from them. A method added later
/// always has a default, so adding one never breaks an implementation. The
/// `with_*` modifiers are not part of the trait, because their return types
/// differ per type.
pub(open) trait Datelike {
  fn year(Self) -> Int
  fn month(Self) -> Month
  fn day(Self) -> Int
  fn ordinal(Self) -> Int
  fn weekday(Self) -> Weekday
  fn month0(Self) -> Int = _
  fn day0(Self) -> Int = _
  fn ordinal0(Self) -> Int = _
  fn quarter(Self) -> Int = _
  fn year_ce(Self) -> YearCe = _
  fn num_days_in_month(Self) -> Int = _
  fn leap_year(Self) -> Bool = _
  fn num_days_from_ce(Self) -> Int = _
  fn iso_week(Self) -> IsoWeek = _
}

///|
impl Datelike with fn month0(self) -> Int {
  self.month().number() - 1
}

///|
impl Datelike with fn day0(self) -> Int {
  self.day() - 1
}

///|
impl Datelike with fn ordinal0(self) -> Int {
  self.ordinal() - 1
}

///|
impl Datelike with fn quarter(self) -> Int {
  (self.month().number() - 1) / 3 + 1
}

///|
impl Datelike with fn year_ce(self) -> YearCe {
  let year = self.year()
  if year >= 1 {
    YearCe::{ is_ce: true, year, }
  } else {
    YearCe::{ is_ce: false, year: 1 - year, }
  }
}

///|
impl Datelike with fn num_days_in_month(self) -> Int {
  self.month().num_days(self.year())
}

///|
impl Datelike with fn leap_year(self) -> Bool {
  is_leap_year(self.year())
}

///|
impl Datelike with fn num_days_from_ce(self) -> Int {
  days_from_civil(self.year(), self.month().number(), self.day()) +
  CE_TO_EPOCH_DAYS.to_int()
}

///|
impl Datelike with fn iso_week(self) -> IsoWeek {
  let days = days_from_civil(self.year(), self.month().number(), self.day())
  iso_week_of(days, self.weekday())
}

///|
pub impl Datelike for NaiveDate with fn year(self) {
  NaiveDate::year(self)
}

///|
pub impl Datelike for NaiveDate with fn month(self) {
  NaiveDate::month(self)
}

///|
pub impl Datelike for NaiveDate with fn day(self) {
  NaiveDate::day(self)
}

///|
pub impl Datelike for NaiveDate with fn ordinal(self) {
  NaiveDate::ordinal(self)
}

///|
pub impl Datelike for NaiveDate with fn weekday(self) {
  NaiveDate::weekday(self)
}

///|
pub impl Datelike for NaiveDateTime with fn year(self) {
  NaiveDateTime::year(self)
}

///|
pub impl Datelike for NaiveDateTime with fn month(self) {
  NaiveDateTime::month(self)
}

///|
pub impl Datelike for NaiveDateTime with fn day(self) {
  NaiveDateTime::day(self)
}

///|
pub impl Datelike for NaiveDateTime with fn ordinal(self) {
  NaiveDateTime::ordinal(self)
}

///|
pub impl Datelike for NaiveDateTime with fn weekday(self) {
  NaiveDateTime::weekday(self)
}

///|
/// Read-only access to the time-of-day components of a value, so generic
/// code can accept a `NaiveTime`, a `NaiveDateTime` or a `DateTime` alike.
/// Implemented by `NaiveTime`, `NaiveDateTime` and `tz`'s `DateTime[Tz]`,
/// which reports its local time. Only `hour`, `minute`, `second` and
/// `nanosecond` are required; the rest derive from them. A method added later
/// always has a default, so adding one never breaks an implementation.
/// `nanosecond` may reach `1_999_999_999` during a leap second.
pub(open) trait Timelike {
  fn hour(Self) -> Int
  fn minute(Self) -> Int
  fn second(Self) -> Int
  fn nanosecond(Self) -> Int
  fn hour12(Self) -> ClockHour12 = _
  fn num_seconds_from_midnight(Self) -> Int = _
}

///|
impl Timelike with fn hour12(self) -> ClockHour12 {
  let hour = self.hour()
  let clock = if hour % 12 == 0 { 12 } else { hour % 12 }
  ClockHour12::{ is_pm: hour >= 12, hour: clock, }
}

///|
impl Timelike with fn num_seconds_from_midnight(self) -> Int {
  self.hour() * 3600 + self.minute() * 60 + self.second()
}

///|
pub impl Timelike for NaiveTime with fn hour(self) {
  NaiveTime::hour(self)
}

///|
pub impl Timelike for NaiveTime with fn minute(self) {
  NaiveTime::minute(self)
}

///|
pub impl Timelike for NaiveTime with fn second(self) {
  NaiveTime::second(self)
}

///|
pub impl Timelike for NaiveTime with fn nanosecond(self) {
  NaiveTime::nanosecond(self)
}

///|
pub impl Timelike for NaiveDateTime with fn hour(self) {
  NaiveDateTime::hour(self)
}

///|
pub impl Timelike for NaiveDateTime with fn minute(self) {
  NaiveDateTime::minute(self)
}

///|
pub impl Timelike for NaiveDateTime with fn second(self) {
  NaiveDateTime::second(self)
}

///|
pub impl Timelike for NaiveDateTime with fn nanosecond(self) {
  NaiveDateTime::nanosecond(self)
}
