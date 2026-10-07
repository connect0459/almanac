///|
fn check_range(value : Int, low : Int, high : Int) -> Unit raise FormatError {
  if value < low || value > high {
    raise FieldOutOfRange
  }
}

///|
/// A `Parsed` with no field populated, to be filled by the `set_*` methods.
/// Each `set_*` returns a new `Parsed`, leaving the receiver unchanged, and
/// rejects a value outside its field's range when set, whereas parsing keeps
/// the raw value and rejects it on resolution.
pub fn Parsed::new() -> Parsed {
  Parsed::{
    year: None,
    month: None,
    day: None,
    ordinal: None,
    hour: None,
    minute: None,
    second: None,
    nanosecond: None,
    weekday: None,
    offset_secs: None,
    hour12: None,
    is_pm: None,
    year_div_100: None,
    year_mod_100: None,
    quarter: None,
    week_sunday: None,
    week_monday: None,
    zone_name: None,
    timestamp: None,
    iso_year: None,
    iso_year_mod_100: None,
    iso_week: None,
  }
}

///|
/// Returns a copy that reads `year` as the calendar year (`%Y`). Raises
/// `InconsistentFields` if a different year was already set.
pub fn Parsed::set_year(self : Parsed, year : Int) -> Parsed raise FormatError {
  { ..self, year: merge_field(self.year, year), }
}

///|
/// Returns a copy that reads `century` as the calendar year divided by 100
/// (`%C`). Raises `FieldOutOfRange` if it is negative.
pub fn Parsed::set_year_div_100(
  self : Parsed,
  century : Int,
) -> Parsed raise FormatError {
  if century < 0 {
    raise FieldOutOfRange
  }
  { ..self, year_div_100: merge_field(self.year_div_100, century), }
}

///|
/// Returns a copy that reads `value` as the calendar year modulo 100 (`%y`).
/// Raises `FieldOutOfRange` outside `0..=99`.
pub fn Parsed::set_year_mod_100(
  self : Parsed,
  value : Int,
) -> Parsed raise FormatError {
  check_range(value, 0, 99)
  { ..self, year_mod_100: merge_field(self.year_mod_100, value), }
}

///|
/// Returns a copy that reads `year` as the ISO week-based year (`%G`).
pub fn Parsed::set_iso_year(
  self : Parsed,
  year : Int,
) -> Parsed raise FormatError {
  { ..self, iso_year: merge_field(self.iso_year, year), }
}

///|
/// Returns a copy that reads `value` as the ISO week-based year modulo 100
/// (`%g`). Raises `FieldOutOfRange` outside `0..=99`.
pub fn Parsed::set_iso_year_mod_100(
  self : Parsed,
  value : Int,
) -> Parsed raise FormatError {
  check_range(value, 0, 99)
  { ..self, iso_year_mod_100: merge_field(self.iso_year_mod_100, value), }
}

///|
/// Returns a copy that reads `week` as the ISO week number (`%V`). Raises
/// `FieldOutOfRange` outside `1..=53`.
pub fn Parsed::set_iso_week(
  self : Parsed,
  week : Int,
) -> Parsed raise FormatError {
  check_range(week, 1, 53)
  { ..self, iso_week: merge_field(self.iso_week, week), }
}

///|
/// Returns a copy that reads `quarter` as the quarter of the year (`%q`),
/// which is cross-checked against the date rather than building one. Raises
/// `FieldOutOfRange` outside `1..=4`.
pub fn Parsed::set_quarter(
  self : Parsed,
  quarter : Int,
) -> Parsed raise FormatError {
  check_range(quarter, 1, 4)
  { ..self, quarter: merge_field(self.quarter, quarter), }
}

///|
/// Returns a copy that reads `month` as the month of the year (`%m`). Raises
/// `FieldOutOfRange` outside `1..=12`.
pub fn Parsed::set_month(
  self : Parsed,
  month : Int,
) -> Parsed raise FormatError {
  check_range(month, 1, 12)
  { ..self, month: merge_field(self.month, month), }
}

///|
/// Returns a copy that reads `week` as the Sunday-based week number (`%U`).
/// Raises `FieldOutOfRange` outside `0..=53`.
pub fn Parsed::set_week_from_sunday(
  self : Parsed,
  week : Int,
) -> Parsed raise FormatError {
  check_range(week, 0, 53)
  { ..self, week_sunday: merge_field(self.week_sunday, week), }
}

///|
/// Returns a copy that reads `week` as the Monday-based week number (`%W`).
/// Raises `FieldOutOfRange` outside `0..=53`.
pub fn Parsed::set_week_from_monday(
  self : Parsed,
  week : Int,
) -> Parsed raise FormatError {
  check_range(week, 0, 53)
  { ..self, week_monday: merge_field(self.week_monday, week), }
}

///|
/// Returns a copy that reads `weekday` as the day of the week (`%a`/`%A`/
/// `%u`/`%w`).
pub fn Parsed::set_weekday(
  self : Parsed,
  weekday : @core.Weekday,
) -> Parsed raise FormatError {
  { ..self, weekday: merge_field(self.weekday, weekday), }
}

///|
/// Returns a copy that reads `ordinal` as the day of the year (`%j`). Raises
/// `FieldOutOfRange` outside `1..=366`.
pub fn Parsed::set_ordinal(
  self : Parsed,
  ordinal : Int,
) -> Parsed raise FormatError {
  check_range(ordinal, 1, 366)
  { ..self, ordinal: merge_field(self.ordinal, ordinal), }
}

///|
/// Returns a copy that reads `day` as the day of the month (`%d`). Raises
/// `FieldOutOfRange` outside `1..=31`.
pub fn Parsed::set_day(self : Parsed, day : Int) -> Parsed raise FormatError {
  check_range(day, 1, 31)
  { ..self, day: merge_field(self.day, day), }
}

///|
/// Returns a copy that reads whether the 12-hour clock reading is PM
/// (`%p`/`%P`).
pub fn Parsed::set_pm(self : Parsed, is_pm : Bool) -> Parsed raise FormatError {
  { ..self, is_pm: merge_field(self.is_pm, is_pm), }
}

///|
/// Returns a copy that reads `hour` as the hour on a 12-hour clock (`%I`).
/// Raises `FieldOutOfRange` outside `1..=12`.
pub fn Parsed::set_hour12(
  self : Parsed,
  hour : Int,
) -> Parsed raise FormatError {
  check_range(hour, 1, 12)
  { ..self, hour12: merge_field(self.hour12, hour), }
}

///|
/// Returns a copy that reads `hour` as the hour on a 24-hour clock (`%H`).
/// Raises `FieldOutOfRange` outside `0..=23`.
pub fn Parsed::set_hour(self : Parsed, hour : Int) -> Parsed raise FormatError {
  check_range(hour, 0, 23)
  { ..self, hour: merge_field(self.hour, hour), }
}

///|
/// Returns a copy that reads `minute` as the minute of the hour (`%M`).
/// Raises `FieldOutOfRange` outside `0..=59`.
pub fn Parsed::set_minute(
  self : Parsed,
  minute : Int,
) -> Parsed raise FormatError {
  check_range(minute, 0, 59)
  { ..self, minute: merge_field(self.minute, minute), }
}

///|
/// Returns a copy that reads `second` as the second of the minute (`%S`);
/// `60` stands for a leap second. Raises `FieldOutOfRange` outside `0..=60`.
pub fn Parsed::set_second(
  self : Parsed,
  second : Int,
) -> Parsed raise FormatError {
  check_range(second, 0, 60)
  { ..self, second: merge_field(self.second, second), }
}

///|
/// Returns a copy that reads `nanosecond` as the fraction of the second, in
/// nanoseconds. Raises `FieldOutOfRange` outside `0..=999_999_999`.
pub fn Parsed::set_nanosecond(
  self : Parsed,
  nanosecond : Int,
) -> Parsed raise FormatError {
  check_range(nanosecond, 0, 999_999_999)
  { ..self, nanosecond: merge_field(self.nanosecond, nanosecond), }
}

///|
/// Returns a copy that reads `timestamp` as the Unix timestamp in whole
/// seconds (`%s`), naming a UTC instant.
pub fn Parsed::set_timestamp(
  self : Parsed,
  timestamp : Int64,
) -> Parsed raise FormatError {
  { ..self, timestamp: merge_field(self.timestamp, timestamp), }
}

///|
/// Returns a copy that reads `seconds` as the UTC offset in seconds east of
/// UTC (`%z`). Raises `FieldOutOfRange` outside `±86399` (`±23:59:59`), the
/// range a `FixedOffset` can hold.
pub fn Parsed::set_offset(
  self : Parsed,
  seconds : Int,
) -> Parsed raise FormatError {
  check_range(seconds, -86399, 86399)
  { ..self, offset_secs: merge_field(self.offset_secs, seconds), }
}

///|
/// Returns a copy that reads `name` as the zone name text (`%Z`), unvalidated.
pub fn Parsed::set_zone_name(
  self : Parsed,
  name : String,
) -> Parsed raise FormatError {
  { ..self, zone_name: merge_field(self.zone_name, name), }
}
