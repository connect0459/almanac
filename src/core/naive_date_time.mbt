///|
/// A date and time of day, without a time zone.
pub struct NaiveDateTime {
  priv date : NaiveDate
  priv time : NaiveTime
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend NaiveDateTime with Eq::{equal}

///|
pub extend NaiveDateTime with Eq::{not_equal}

///|
pub extend NaiveDateTime with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend NaiveDateTime with Hash::{hash, hash_combine}

///|
/// The Unix epoch instant, `1970-01-01T00:00:00`: timestamp zero, and the
/// reference point `round`, `round_up` and `truncate` measure a granularity
/// against.
pub fn NaiveDateTime::unix_epoch() -> NaiveDateTime {
  NaiveDateTime::{ date: NaiveDate::default(), time: NaiveTime::midnight(), }
}

///|
/// The Unix epoch instant; see `unix_epoch`.
pub impl Default for NaiveDateTime with fn default() {
  NaiveDateTime::unix_epoch()
}

///|
pub extend NaiveDateTime with Default::{default}

///|
pub extend NaiveDateTime with @debug.Debug::{to_repr}

///|
/// Renders as the date and the time joined by a space, e.g.
/// `2024-01-02 13:45:06.500`; see `NaiveDate` and `NaiveTime`'s `Show`.
pub impl Show for NaiveDateTime with fn output(self, logger) {
  logger.write_string(self.date.to_string() + " " + self.time.to_string())
}

///|
pub extend NaiveDateTime with Show::{to_string, output}

///|
/// Composes a `NaiveDate` and a `NaiveTime` into a `NaiveDateTime`.
pub fn NaiveDateTime::new(date : NaiveDate, time : NaiveTime) -> NaiveDateTime {
  NaiveDateTime::{ date, time, }
}

///|
/// Constructs the datetime for a Unix timestamp given as whole seconds plus
/// a nanosecond component, or `None` if `nanos` is outside
/// `0..=1_999_999_999` (a value at or above `1_000_000_000` represents a
/// leap second; see `NaiveTime::nanosecond`).
pub fn NaiveDateTime::from_timestamp(
  secs : Int64,
  nanos : Int,
) -> NaiveDateTime? {
  let days = floor_div64(secs, 86400L)
  let secs_of_day = floor_mod64(secs, 86400L).to_int()
  match
    (
      NaiveDate::from_epoch_days64(days),
      NaiveTime::from_num_seconds_from_midnight(secs_of_day, nanos),
    ) {
    (Some(date), Some(time)) => Some(NaiveDateTime::{ date, time, })
    _ => None
  }
}

///|
/// Constructs the datetime for a Unix timestamp given in whole
/// milliseconds.
pub fn NaiveDateTime::from_timestamp_millis(millis : Int64) -> NaiveDateTime? {
  NaiveDateTime::from_timestamp(
    floor_div64(millis, 1000L),
    floor_mod64(millis, 1000L).to_int() * 1_000_000,
  )
}

///|
/// Constructs the datetime for a Unix timestamp given in whole
/// microseconds.
pub fn NaiveDateTime::from_timestamp_micros(micros : Int64) -> NaiveDateTime? {
  NaiveDateTime::from_timestamp(
    floor_div64(micros, 1_000_000L),
    floor_mod64(micros, 1_000_000L).to_int() * 1000,
  )
}

///|
/// Constructs the datetime for a Unix timestamp given in whole
/// nanoseconds.
pub fn NaiveDateTime::from_timestamp_nanos(nanos : Int64) -> NaiveDateTime? {
  NaiveDateTime::from_timestamp(
    floor_div64(nanos, 1_000_000_000L),
    floor_mod64(nanos, 1_000_000_000L).to_int(),
  )
}

///|
/// The date component.
pub fn NaiveDateTime::date(self : NaiveDateTime) -> NaiveDate {
  self.date
}

///|
/// The time-of-day component.
pub fn NaiveDateTime::time(self : NaiveDateTime) -> NaiveTime {
  self.time
}

///|
/// The year, month, and day of month together.
pub fn NaiveDateTime::ymd(self : NaiveDateTime) -> (Int, Month, Int) {
  self.date.ymd()
}

///|
/// The hour, minute, and second together.
pub fn NaiveDateTime::hms(self : NaiveDateTime) -> (Int, Int, Int) {
  self.time.hms()
}

///|
/// The calendar year.
pub fn NaiveDateTime::year(self : NaiveDateTime) -> Int {
  self.date.year()
}

///|
/// The calendar month.
pub fn NaiveDateTime::month(self : NaiveDateTime) -> Month {
  self.date.month()
}

///|
/// The day of the month, `1..=31`.
pub fn NaiveDateTime::day(self : NaiveDateTime) -> Int {
  self.date.day()
}

///|
/// The day of the year, `1..=366`.
pub fn NaiveDateTime::ordinal(self : NaiveDateTime) -> Int {
  self.date.ordinal()
}

///|
/// The day of the week.
pub fn NaiveDateTime::weekday(self : NaiveDateTime) -> Weekday {
  self.date.weekday()
}

///|
/// The ISO 8601 week date's year and week number.
pub fn NaiveDateTime::iso_week(self : NaiveDateTime) -> IsoWeek {
  self.date.iso_week()
}

///|
/// Whether the calendar year is a leap year.
pub fn NaiveDateTime::leap_year(self : NaiveDateTime) -> Bool {
  self.date.leap_year()
}

///|
/// The hour, `0..=23`.
pub fn NaiveDateTime::hour(self : NaiveDateTime) -> Int {
  self.time.hour()
}

///|
/// The minute, `0..=59`.
pub fn NaiveDateTime::minute(self : NaiveDateTime) -> Int {
  self.time.minute()
}

///|
/// The second, `0..=59` (never `60`; see `nanosecond` for leap seconds).
pub fn NaiveDateTime::second(self : NaiveDateTime) -> Int {
  self.time.second()
}

///|
/// The nanosecond within the second, `0..=1_999_999_999` (a value at or above
/// `1_000_000_000` represents a leap second).
pub fn NaiveDateTime::nanosecond(self : NaiveDateTime) -> Int {
  self.time.nanosecond()
}

///|
/// This datetime with its year replaced, or `None` if the result is not a valid
/// date. The time of day is unchanged. See `NaiveDate::with_year`.
pub fn NaiveDateTime::with_year(
  self : NaiveDateTime,
  year : Int,
) -> NaiveDateTime? {
  self.date
  .with_year(year)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its month replaced, or `None` if the result is not a valid
/// date. The time of day is unchanged. See `NaiveDate::with_month`.
pub fn NaiveDateTime::with_month(
  self : NaiveDateTime,
  month : Int,
) -> NaiveDateTime? {
  self.date
  .with_month(month)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its day replaced, or `None` if the result is not a valid
/// date. The time of day is unchanged. See `NaiveDate::with_day`.
pub fn NaiveDateTime::with_day(
  self : NaiveDateTime,
  day : Int,
) -> NaiveDateTime? {
  self.date.with_day(day).map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its day of year replaced, or `None` if the result is not a valid
/// date. The time of day is unchanged. See `NaiveDate::with_ordinal`.
pub fn NaiveDateTime::with_ordinal(
  self : NaiveDateTime,
  ordinal : Int,
) -> NaiveDateTime? {
  self.date
  .with_ordinal(ordinal)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// The month of the year, counting from `0`. See `NaiveDate::month0`.
pub fn NaiveDateTime::month0(self : NaiveDateTime) -> Int {
  self.date.month0()
}

///|
/// The day of the month, counting from `0`. See `NaiveDate::day0`.
pub fn NaiveDateTime::day0(self : NaiveDateTime) -> Int {
  self.date.day0()
}

///|
/// The day of the year, counting from `0`. See `NaiveDate::ordinal0`.
pub fn NaiveDateTime::ordinal0(self : NaiveDateTime) -> Int {
  self.date.ordinal0()
}

///|
/// The quarter of the year, `1..=4`. See `NaiveDate::quarter`.
pub fn NaiveDateTime::quarter(self : NaiveDateTime) -> Int {
  self.date.quarter()
}

///|
/// The year as a Common Era flag and a positive year number. See
/// `NaiveDate::year_ce`.
pub fn NaiveDateTime::year_ce(self : NaiveDateTime) -> (Bool, Int) {
  self.date.year_ce()
}

///|
/// The number of days since the start of the Common Era, counting
/// `0001-01-01` as day `1`. See `NaiveDate::num_days_from_ce`.
pub fn NaiveDateTime::num_days_from_ce(self : NaiveDateTime) -> Int {
  self.date.num_days_from_ce()
}

///|
/// The number of days in this datetime's month. See
/// `NaiveDate::num_days_in_month`.
pub fn NaiveDateTime::num_days_in_month(self : NaiveDateTime) -> Int {
  self.date.num_days_in_month()
}

///|
/// The hour on a 12-hour clock as a PM flag and an hour in `1..=12`. See
/// `NaiveTime::hour12`.
pub fn NaiveDateTime::hour12(self : NaiveDateTime) -> (Bool, Int) {
  self.time.hour12()
}

///|
/// The number of seconds since midnight. See
/// `NaiveTime::num_seconds_from_midnight`.
pub fn NaiveDateTime::num_seconds_from_midnight(self : NaiveDateTime) -> Int {
  self.time.num_seconds_from_midnight()
}

///|
/// Like `with_month`, but taking a `0`-based month. The time of day is
/// unchanged.
pub fn NaiveDateTime::with_month0(
  self : NaiveDateTime,
  month0 : Int,
) -> NaiveDateTime? {
  self.date
  .with_month0(month0)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// Like `with_day`, but taking a `0`-based day of the month. The time of
/// day is unchanged.
pub fn NaiveDateTime::with_day0(
  self : NaiveDateTime,
  day0 : Int,
) -> NaiveDateTime? {
  self.date
  .with_day0(day0)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// Like `with_ordinal`, but taking a `0`-based day of the year. The time of
/// day is unchanged.
pub fn NaiveDateTime::with_ordinal0(
  self : NaiveDateTime,
  ordinal0 : Int,
) -> NaiveDateTime? {
  self.date
  .with_ordinal0(ordinal0)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its hour replaced, or `None` if it is out of range. The
/// date and every other time field (including a leap-second nanosecond) are
/// unchanged. See `NaiveTime::with_hour`.
pub fn NaiveDateTime::with_hour(
  self : NaiveDateTime,
  hour : Int,
) -> NaiveDateTime? {
  self.time
  .with_hour(hour)
  .map(time => NaiveDateTime::{ date: self.date, time, })
}

///|
/// This datetime with its minute replaced, or `None` if it is out of range. The
/// date and every other time field (including a leap-second nanosecond) are
/// unchanged. See `NaiveTime::with_minute`.
pub fn NaiveDateTime::with_minute(
  self : NaiveDateTime,
  minute : Int,
) -> NaiveDateTime? {
  self.time
  .with_minute(minute)
  .map(time => NaiveDateTime::{ date: self.date, time, })
}

///|
/// This datetime with its second replaced, or `None` if it is out of range. The
/// date and every other time field (including a leap-second nanosecond) are
/// unchanged. See `NaiveTime::with_second`.
pub fn NaiveDateTime::with_second(
  self : NaiveDateTime,
  second : Int,
) -> NaiveDateTime? {
  self.time
  .with_second(second)
  .map(time => NaiveDateTime::{ date: self.date, time, })
}

///|
/// This datetime with its nanosecond replaced, or `None` if it is out of range. The
/// date and every other time field (including a leap-second nanosecond) are
/// unchanged. See `NaiveTime::with_nanosecond`.
pub fn NaiveDateTime::with_nanosecond(
  self : NaiveDateTime,
  nanosecond : Int,
) -> NaiveDateTime? {
  self.time
  .with_nanosecond(nanosecond)
  .map(time => NaiveDateTime::{ date: self.date, time, })
}

///|
/// The Unix timestamp, in whole seconds, truncated toward negative
/// infinity (i.e. the seconds component of `from_timestamp`'s inverse).
/// Does not account for a leap second's extra elapsed second, matching
/// `NaiveTime::num_seconds_from_midnight`.
pub fn NaiveDateTime::timestamp(self : NaiveDateTime) -> Int64 {
  self.date.epoch_days().to_int64() * 86400L +
  self.time.num_seconds_from_midnight().to_int64()
}

///|
/// The nanosecond component of this instant, `0..=1_999_999_999` (see
/// `NaiveTime::nanosecond` for the leap-second convention).
pub fn NaiveDateTime::timestamp_subsec_nanos(self : NaiveDateTime) -> Int {
  self.time.nanosecond()
}

///|
/// The nanosecond component of this instant, expressed in whole
/// milliseconds.
pub fn NaiveDateTime::timestamp_subsec_millis(self : NaiveDateTime) -> Int {
  self.timestamp_subsec_nanos() / 1_000_000
}

///|
/// The nanosecond component of this instant, expressed in whole
/// microseconds.
pub fn NaiveDateTime::timestamp_subsec_micros(self : NaiveDateTime) -> Int {
  self.timestamp_subsec_nanos() / 1000
}

///|
/// The Unix timestamp in whole milliseconds. Always succeeds: unlike
/// `timestamp_micros`/`timestamp_nanos`, this stays within `Int64` even at
/// the extremes of `NaiveDate`'s representable range.
pub fn NaiveDateTime::timestamp_millis(self : NaiveDateTime) -> Int64 {
  self.timestamp() * 1000L + self.timestamp_subsec_millis().to_int64()
}

///|
/// The Unix timestamp in whole microseconds, or `None` if it does not fit
/// in `Int64` (possible for a date far from the epoch).
pub fn NaiveDateTime::timestamp_micros(self : NaiveDateTime) -> Int64? {
  match checked_mul64(self.timestamp(), 1_000_000L) {
    None => None
    Some(secs_part) =>
      checked_add64(secs_part, self.timestamp_subsec_micros().to_int64())
  }
}

///|
/// The Unix timestamp in whole nanoseconds, or `None` if it does not fit in
/// `Int64` (possible for a date far from the epoch).
pub fn NaiveDateTime::timestamp_nanos(self : NaiveDateTime) -> Int64? {
  match checked_mul64(self.timestamp(), 1_000_000_000L) {
    None => None
    Some(secs_part) =>
      checked_add64(secs_part, self.timestamp_subsec_nanos().to_int64())
  }
}

///|
/// This datetime advanced by the signed duration `delta`, propagating any
/// day overflow from the time-of-day arithmetic into the date. See
/// `NaiveTime::overflowing_add_signed` for the wrapping and leap-second
/// rules.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_signed` to get `None` instead.
pub fn NaiveDateTime::add_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime {
  expect_in_range(self.checked_add_signed(delta), "NaiveDateTime::add_signed")
}

///|
/// This datetime advanced by the signed duration `delta`, or `None` if the
/// resulting date falls outside `NaiveDate`'s representable range. See
/// `add_signed`.
pub fn NaiveDateTime::checked_add_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime? {
  let (time, days) = self.time.overflowing_add_signed(delta)
  self.date.checked_add_days64(days).map(date => NaiveDateTime::{ date, time, })
}

///|
/// This datetime moved back by the signed duration `delta`. See
/// `add_signed`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_signed` to get `None` instead.
pub fn NaiveDateTime::sub_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime {
  expect_in_range(self.checked_sub_signed(delta), "NaiveDateTime::sub_signed")
}

///|
/// This datetime moved back by the signed duration `delta`, or `None` if
/// the resulting date falls outside `NaiveDate`'s representable range.
pub fn NaiveDateTime::checked_sub_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime? {
  self.checked_add_signed(delta.neg())
}

///|
/// This datetime shifted forward by `seconds` whole seconds (backward if
/// negative). A convenience over `add_signed` with a `TimeDelta` built from
/// the same seconds, e.g. to apply a UTC offset; a nonzero shift follows
/// `add_signed`'s leap-second rule, and a zero shift changes nothing.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_seconds` to get `None` instead.
pub fn NaiveDateTime::add_seconds(
  self : NaiveDateTime,
  seconds : Int,
) -> NaiveDateTime {
  expect_in_range(
    self.checked_add_seconds(seconds),
    "NaiveDateTime::add_seconds",
  )
}

///|
/// This datetime shifted backward by `seconds` whole seconds (forward if
/// negative). See `add_seconds`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_seconds` to get `None` instead.
pub fn NaiveDateTime::sub_seconds(
  self : NaiveDateTime,
  seconds : Int,
) -> NaiveDateTime {
  expect_in_range(
    self.checked_sub_seconds(seconds),
    "NaiveDateTime::sub_seconds",
  )
}

///|
/// Like `add_seconds`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn NaiveDateTime::checked_add_seconds(
  self : NaiveDateTime,
  seconds : Int,
) -> NaiveDateTime? {
  self.checked_add_signed(TimeDelta::seconds(seconds.to_int64()).unwrap())
}

///|
/// Like `sub_seconds`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn NaiveDateTime::checked_sub_seconds(
  self : NaiveDateTime,
  seconds : Int,
) -> NaiveDateTime? {
  self.checked_add_signed(TimeDelta::seconds(-seconds.to_int64()).unwrap())
}

///|
/// This datetime with its date advanced by `months` (or moved back, if
/// `months` is negative), keeping the time of day unchanged. See
/// `NaiveDate::add_months` for the day-of-month clamping rule.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_months` to get `None` instead.
pub fn NaiveDateTime::add_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime {
  expect_in_range(self.checked_add_months(months), "NaiveDateTime::add_months")
}

///|
/// Like `add_months`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::checked_add_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime? {
  self.date
  .checked_add_months(months)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its date moved back by `months`. See `add_months`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_months` to get `None` instead.
pub fn NaiveDateTime::sub_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime {
  expect_in_range(self.checked_sub_months(months), "NaiveDateTime::sub_months")
}

///|
/// Like `sub_months`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::checked_sub_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime? {
  self.date
  .checked_sub_months(months)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its date advanced by `days` (or moved back, if
/// `days` is negative), keeping the time of day unchanged.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_days` to get `None` instead.
pub fn NaiveDateTime::add_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime {
  expect_in_range(self.checked_add_days(days), "NaiveDateTime::add_days")
}

///|
/// Like `add_days`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::checked_add_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime? {
  self.date
  .checked_add_days(days)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// This datetime with its date moved back by `days`. See `add_days`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_days` to get `None` instead.
pub fn NaiveDateTime::sub_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime {
  expect_in_range(self.checked_sub_days(days), "NaiveDateTime::sub_days")
}

///|
/// Like `sub_days`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::checked_sub_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime? {
  self.date
  .checked_sub_days(days)
  .map(date => NaiveDateTime::{ date, time: self.time, })
}

///|
/// The signed duration from `other` to `self` (positive if `self` is
/// later). Always succeeds: the difference between any two dates in
/// `NaiveDate`'s representable range comfortably fits `TimeDelta`'s much
/// wider representable range.
pub fn NaiveDateTime::signed_duration_since(
  self : NaiveDateTime,
  other : NaiveDateTime,
) -> TimeDelta {
  let day_diff = self.date.epoch_days().to_int64() -
    other.date.epoch_days().to_int64()
  let self_nanos = self.time.num_seconds_from_midnight().to_int64() *
    1_000_000_000L +
    self.time.nanosecond().to_int64()
  let other_nanos = other.time.num_seconds_from_midnight().to_int64() *
    1_000_000_000L +
    other.time.nanosecond().to_int64()
  TimeDelta::days(day_diff)
  .unwrap()
  .add(TimeDelta::nanoseconds(self_nanos - other_nanos).unwrap())
  .unwrap()
}

///|
/// This datetime truncated toward the Unix epoch to the nearest multiple of
/// `granularity`. See `TimeDelta::truncate` for the conditions under which
/// `granularity` is rejected (returning `None`).
pub fn NaiveDateTime::truncate(
  self : NaiveDateTime,
  granularity : TimeDelta,
) -> NaiveDateTime? {
  self
  .signed_duration_since(NaiveDateTime::unix_epoch())
  .truncate(granularity)
  .map(delta => NaiveDateTime::unix_epoch().add_signed(delta))
}

///|
/// This datetime rounded to the nearest multiple of `granularity` since the
/// Unix epoch, ties breaking away from the epoch. See `TimeDelta::round`
/// for the conditions under which `granularity` is rejected (returning
/// `None`); also `None` if rounding away from the epoch would leave
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::round(
  self : NaiveDateTime,
  granularity : TimeDelta,
) -> NaiveDateTime? {
  self
  .signed_duration_since(NaiveDateTime::unix_epoch())
  .round(granularity)
  .bind(delta => NaiveDateTime::unix_epoch().checked_add_signed(delta))
}

///|
/// This datetime rounded up (toward positive infinity) to the nearest
/// multiple of `granularity` since the Unix epoch: unchanged if already a
/// multiple, otherwise the next one after it. See `TimeDelta::round_up`.
/// Returns `None` if `granularity` is rejected or the result falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDateTime::round_up(
  self : NaiveDateTime,
  granularity : TimeDelta,
) -> NaiveDateTime? {
  self
  .signed_duration_since(NaiveDateTime::unix_epoch())
  .round_up(granularity)
  .bind(delta => NaiveDateTime::unix_epoch().checked_add_signed(delta))
}
