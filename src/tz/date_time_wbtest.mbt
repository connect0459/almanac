///|
struct AlwaysAbsent {}

///|
impl TimeZone for AlwaysAbsent with fn offset_from_utc(_self, _dt) {
  FixedOffset::east(3600).unwrap()
}

///|
impl TimeZone for AlwaysAbsent with fn offset_from_local(_self, _dt) {
  Absent
}

///|
impl TimeZone for AlwaysAbsent with fn zone_name(_self, _dt) {
  "ABS"
}

///|
test "from_local_lenient falls back to the offset at the reading itself for a zone that reports a gap without transition bounds" {
  let reading = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = DateTime::from_local_lenient(reading, AlwaysAbsent::{ })
  assert_eq(
    dt.naive_utc(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(11, 0, 0).unwrap(),
    ),
  )
}

///|
fn utc_reading(day : Int, hour : Int, minute : Int) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, day).unwrap(),
    @core.NaiveTime::from_hms(hour, minute, 0).unwrap(),
  )
}

///|
struct TwoGaps {}

///|
fn TwoGaps::first() -> @core.NaiveDateTime {
  utc_reading(1, 10, 0)
}

///|
fn TwoGaps::second() -> @core.NaiveDateTime {
  utc_reading(1, 20, 0)
}

///|
impl TimeZone for TwoGaps with fn offset_from_utc(_self, dt) {
  if dt < TwoGaps::first() {
    FixedOffset::east(0).unwrap()
  } else if dt < TwoGaps::second() {
    FixedOffset::east(3600).unwrap()
  } else {
    FixedOffset::east(7200).unwrap()
  }
}

///|
impl TimeZone for TwoGaps with fn offset_from_local(_self, _dt) {
  Absent
}

///|
impl TimeZone for TwoGaps with fn zone_name(_self, _dt) {
  "TWO"
}

///|
impl TimeZone for TwoGaps with fn transition_bounds(_self, dt) {
  if dt < TwoGaps::first() {
    TransitionBounds::{ start: None, end: Some(TwoGaps::first()), }
  } else if dt < TwoGaps::second() {
    TransitionBounds::{
      start: Some(TwoGaps::first()),
      end: Some(TwoGaps::second()),
    }
  } else {
    TransitionBounds::{ start: Some(TwoGaps::second()), end: None, }
  }
}

///|
test "from_local_lenient finds the gap of an earlier transition when a later one lies within reach of the reading" {
  let dt = DateTime::from_local_lenient(utc_reading(1, 10, 30), TwoGaps::{ })
  assert_eq(dt.naive_utc(), utc_reading(1, 10, 30))
}

///|
test "from_local_lenient falls back to the offset at the reading when no transition's gap contains it" {
  let dt = DateTime::from_local_lenient(utc_reading(2, 12, 0), TwoGaps::{ })
  assert_eq(dt.naive_utc(), utc_reading(2, 10, 0))
}
