///|
struct DateFacts {
  year : Int
  month : @core.Month
  month0 : Int
  day : Int
  day0 : Int
  ordinal : Int
  ordinal0 : Int
  weekday : @core.Weekday
  quarter : Int
  year_ce : @core.YearCe
  num_days_from_ce : Int
  num_days_in_month : Int
  leap_year : Bool
  iso_week : @core.IsoWeek
} derive(Eq, Debug)

///|
fn[T : @core.Datelike] date_facts(value : T) -> DateFacts {
  {
    year: value.year(),
    month: value.month(),
    month0: value.month0(),
    day: value.day(),
    day0: value.day0(),
    ordinal: value.ordinal(),
    ordinal0: value.ordinal0(),
    weekday: value.weekday(),
    quarter: value.quarter(),
    year_ce: value.year_ce(),
    num_days_from_ce: value.num_days_from_ce(),
    num_days_in_month: value.num_days_in_month(),
    leap_year: value.leap_year(),
    iso_week: value.iso_week(),
  }
}

///|
struct TimeFacts {
  hour : Int
  hour12 : @core.ClockHour12
  minute : Int
  second : Int
  nanosecond : Int
  num_seconds_from_midnight : Int
} derive(Eq, Debug)

///|
fn[T : @core.Timelike] time_facts(value : T) -> TimeFacts {
  {
    hour: value.hour(),
    hour12: value.hour12(),
    minute: value.minute(),
    second: value.second(),
    nanosecond: value.nanosecond(),
    num_seconds_from_midnight: value.num_seconds_from_midnight(),
  }
}

///|
let sample_dates : Array[(Int, Int, Int)] = [
  (2024, 2, 29),
  (2023, 12, 31),
  (2021, 1, 3),
  (1, 1, 1),
  (0, 12, 31),
  (-44, 3, 15),
  (1900, 3, 1),
  (2000, 12, 31),
  (2020, 12, 31),
  (2021, 1, 1),
  (2026, 12, 31),
  (2024, 12, 30),
  (2025, 1, 1),
  (2015, 12, 28),
  (-1, 1, 1),
]

///|
let sample_times : Array[(Int, Int, Int, Int)] = [
  (0, 0, 0, 0),
  (9, 30, 15, 123_456_789),
  (12, 0, 0, 0),
  (13, 5, 59, 999_999_999),
  (23, 59, 59, 0),
  (23, 59, 59, 1_500_000_000),
]

///|
test "a @core.NaiveDate read through @core.Datelike reports the same facts as its own accessors" {
  for ymd in sample_dates {
    let (y, m, d) = ymd
    let date = @core.NaiveDate::from_ymd(y, m, d).unwrap()
    let expected : DateFacts = {
      year: date.year(),
      month: date.month(),
      month0: date.month0(),
      day: date.day(),
      day0: date.day0(),
      ordinal: date.ordinal(),
      ordinal0: date.ordinal0(),
      weekday: date.weekday(),
      quarter: date.quarter(),
      year_ce: date.year_ce(),
      num_days_from_ce: date.num_days_from_ce(),
      num_days_in_month: date.num_days_in_month(),
      leap_year: date.leap_year(),
      iso_week: date.iso_week(),
    }
    assert_eq(date_facts(date), expected)
  }
}

///|
test "a @core.NaiveDateTime read through @core.Datelike reports the facts of its date" {
  for ymd in sample_dates {
    let (y, m, d) = ymd
    let date = @core.NaiveDate::from_ymd(y, m, d).unwrap()
    let dt = @core.NaiveDateTime::new(
      date,
      @core.NaiveTime::from_hms(18, 45, 7).unwrap(),
    )
    assert_eq(date_facts(dt), date_facts(date))
  }
}

///|
test "@core.Datelike gives the calendar facts of a leap day" {
  let facts = date_facts(@core.NaiveDate::from_ymd(2024, 2, 29).unwrap())
  assert_eq(facts.month0, 1)
  assert_eq(facts.day0, 28)
  assert_eq(facts.ordinal, 60)
  assert_eq(facts.ordinal0, 59)
  assert_eq(facts.quarter, 1)
  assert_eq(facts.num_days_in_month, 29)
  assert_true(facts.leap_year)
  assert_eq(facts.weekday, Thu)
}

///|
test "a @core.NaiveTime read through @core.Timelike reports the same facts as its own accessors" {
  for hmsn in sample_times {
    let (h, m, s, n) = hmsn
    let time = @core.NaiveTime::from_hms_nano(h, m, s, n).unwrap()
    let expected : TimeFacts = {
      hour: time.hour(),
      hour12: time.hour12(),
      minute: time.minute(),
      second: time.second(),
      nanosecond: time.nanosecond(),
      num_seconds_from_midnight: time.num_seconds_from_midnight(),
    }
    assert_eq(time_facts(time), expected)
  }
}

///|
test "a @core.NaiveDateTime read through @core.Timelike reports the facts of its time" {
  for hmsn in sample_times {
    let (h, m, s, n) = hmsn
    let time = @core.NaiveTime::from_hms_nano(h, m, s, n).unwrap()
    let dt = @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 1).unwrap(),
      time,
    )
    assert_eq(time_facts(dt), time_facts(time))
  }
}

///|
test "@core.Timelike keeps a leap second's nanosecond field above one second" {
  let time = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(time_facts(time).nanosecond, 1_500_000_000)
  assert_eq(time_facts(time).num_seconds_from_midnight, 86399)
}

///|
struct CalendarStamp {
  date : @core.NaiveDate
  time : @core.NaiveTime
}

///|
impl @core.Datelike for CalendarStamp with fn year(self) {
  self.date.year()
}

///|
impl @core.Datelike for CalendarStamp with fn month(self) {
  self.date.month()
}

///|
impl @core.Datelike for CalendarStamp with fn day(self) {
  self.date.day()
}

///|
impl @core.Datelike for CalendarStamp with fn ordinal(self) {
  self.date.ordinal()
}

///|
impl @core.Datelike for CalendarStamp with fn weekday(self) {
  self.date.weekday()
}

///|
impl @core.Timelike for CalendarStamp with fn hour(self) {
  self.time.hour()
}

///|
impl @core.Timelike for CalendarStamp with fn minute(self) {
  self.time.minute()
}

///|
impl @core.Timelike for CalendarStamp with fn second(self) {
  self.time.second()
}

///|
impl @core.Timelike for CalendarStamp with fn nanosecond(self) {
  self.time.nanosecond()
}

///|
test "a caller-defined type gains every provided Datelike method from the required ones" {
  for ymd in sample_dates {
    let (y, m, d) = ymd
    let date = @core.NaiveDate::from_ymd(y, m, d).unwrap()
    let stamp = CalendarStamp::{ date, time: @core.NaiveTime::midnight(), }
    assert_eq(date_facts(stamp), date_facts(date))
  }
}

///|
test "a caller-defined type gains every provided Timelike method from the required ones" {
  for hmsn in sample_times {
    let (h, m, s, n) = hmsn
    let time = @core.NaiveTime::from_hms_nano(h, m, s, n).unwrap()
    let stamp = CalendarStamp::{
      date: @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
      time,
    }
    assert_eq(time_facts(stamp), time_facts(time))
  }
}

///|
test "Datelike derives the ISO week and day count of a date at the edges of a year without a NaiveDate" {
  let stamp = CalendarStamp::{
    date: @core.NaiveDate::from_ymd(2021, 1, 3).unwrap(),
    time: @core.NaiveTime::midnight(),
  }
  assert_eq(@core.Datelike::iso_week(stamp).year(), 2020)
  assert_eq(@core.Datelike::iso_week(stamp).week(), 53)
  assert_eq(@core.Datelike::num_days_from_ce(stamp), 737793)
}
