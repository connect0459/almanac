///|
/// The day count (relative to the Unix epoch, `1970-01-01` is day `0`) for
/// `date`.
fn to_epoch_days(date : NaiveDate) -> Int {
  days_from_civil(date.year(), date.month().number_from_month(), date.day())
}

///|
/// The date for a day count relative to the Unix epoch (`1970-01-01` is day
/// `0`). Total: `civil_from_days` always yields a valid proleptic Gregorian
/// `(year, month, day)` triple.
fn from_epoch_days(days : Int) -> NaiveDate {
  let (year, month, day) = civil_from_days(days)
  NaiveDate::from_ymd(year, month, day).unwrap()
}

///|
/// A date and time of day, without a time zone.
pub struct NaiveDateTime {
  priv date : NaiveDate
  priv time : NaiveTime
} derive(Eq, @debug.Debug)

///|
pub extend NaiveDateTime with Eq::{equal}

///|
pub extend NaiveDateTime with Eq::{not_equal}

///|
pub extend NaiveDateTime with @debug.Debug::{to_repr}

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
  let days = floor_div64(secs, 86400L).to_int()
  let secs_of_day = floor_mod64(secs, 86400L).to_int()
  match NaiveTime::from_num_seconds_from_midnight(secs_of_day, nanos) {
    None => None
    Some(time) => Some(NaiveDateTime::{ date: from_epoch_days(days), time, })
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
/// The Unix timestamp, in whole seconds, truncated toward negative
/// infinity (i.e. the seconds component of `from_timestamp`'s inverse).
/// Does not account for a leap second's extra elapsed second, matching
/// `NaiveTime::num_seconds_from_midnight`.
pub fn NaiveDateTime::timestamp(self : NaiveDateTime) -> Int64 {
  to_epoch_days(self.date).to_int64() * 86400L +
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
pub fn NaiveDateTime::add_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime {
  let (time, days) = self.time.overflowing_add_signed(delta)
  NaiveDateTime::{ date: self.date.add_days(days.to_int()), time, }
}

///|
/// This datetime moved back by the signed duration `delta`. See
/// `add_signed`.
pub fn NaiveDateTime::sub_signed(
  self : NaiveDateTime,
  delta : TimeDelta,
) -> NaiveDateTime {
  self.add_signed(delta.neg())
}

///|
/// This datetime with its date advanced by `months` (or moved back, if
/// `months` is negative), keeping the time of day unchanged. See
/// `NaiveDate::add_months` for the day-of-month clamping rule.
pub fn NaiveDateTime::add_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime {
  NaiveDateTime::{ date: self.date.add_months(months), time: self.time, }
}

///|
/// This datetime with its date moved back by `months`. See `add_months`.
pub fn NaiveDateTime::sub_months(
  self : NaiveDateTime,
  months : Int,
) -> NaiveDateTime {
  NaiveDateTime::{ date: self.date.sub_months(months), time: self.time, }
}

///|
/// This datetime with its date advanced by `days` (or moved back, if
/// `days` is negative), keeping the time of day unchanged.
pub fn NaiveDateTime::add_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime {
  NaiveDateTime::{ date: self.date.add_days(days), time: self.time, }
}

///|
/// This datetime with its date moved back by `days`. See `add_days`.
pub fn NaiveDateTime::sub_days(
  self : NaiveDateTime,
  days : Int,
) -> NaiveDateTime {
  NaiveDateTime::{ date: self.date.sub_days(days), time: self.time, }
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
  let day_diff = (to_epoch_days(self.date) - to_epoch_days(other.date)).to_int64()
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
