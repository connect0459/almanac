///|
/// A time of day, without a date or time zone.
///
/// Internally represented as whole seconds since midnight (`0..=86399`) plus
/// a nanosecond component. The nanosecond component is normally
/// `0..=999_999_999`, but may reach `1_999_999_999` to represent a leap
/// second at `second() == 59` (see `nanosecond`).
pub struct NaiveTime {
  priv secs : Int
  priv frac : Int
} derive(Eq, Compare, @debug.Debug)

///|
pub extend NaiveTime with Eq::{equal}

///|
pub extend NaiveTime with Eq::{not_equal}

///|
pub extend NaiveTime with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend NaiveTime with @debug.Debug::{to_repr}

///|
/// Constructs the time for a given `hour`/`minute`/`second`/`nanosecond`,
/// or `None` if `hour` is outside `0..=23`, `minute` or `second` are outside
/// `0..=59`, or `nanosecond` is outside `0..=1_999_999_999`. A `nanosecond`
/// of `1_000_000_000` or above represents a leap second (see `nanosecond`).
pub fn NaiveTime::from_hms_nano(
  hour : Int,
  min : Int,
  sec : Int,
  nano : Int,
) -> NaiveTime? {
  if hour < 0 || hour > 23 {
    None
  } else if min < 0 || min > 59 {
    None
  } else if sec < 0 || sec > 59 {
    None
  } else if nano < 0 || nano >= 2_000_000_000 {
    None
  } else {
    Some(NaiveTime::{ secs: hour * 3600 + min * 60 + sec, frac: nano, })
  }
}

///|
/// Constructs the time for a given `hour`/`minute`/`second`, or `None` if
/// any component is outside its valid range. See `from_hms_nano` for the
/// exact ranges.
pub fn NaiveTime::from_hms(hour : Int, min : Int, sec : Int) -> NaiveTime? {
  NaiveTime::from_hms_nano(hour, min, sec, 0)
}

///|
/// Constructs the time for a given `hour`/`minute`/`second` plus a
/// millisecond component, or `None` if any component is outside its valid
/// range (`milli` outside `0..=1999`; see `from_hms_nano`).
pub fn NaiveTime::from_hms_milli(
  hour : Int,
  min : Int,
  sec : Int,
  milli : Int,
) -> NaiveTime? {
  NaiveTime::from_hms_nano(hour, min, sec, milli * 1_000_000)
}

///|
/// Constructs the time for a given `hour`/`minute`/`second` plus a
/// microsecond component, or `None` if any component is outside its valid
/// range (`micro` outside `0..=1_999_999`; see `from_hms_nano`).
pub fn NaiveTime::from_hms_micro(
  hour : Int,
  min : Int,
  sec : Int,
  micro : Int,
) -> NaiveTime? {
  NaiveTime::from_hms_nano(hour, min, sec, micro * 1000)
}

///|
/// Constructs the time for a given count of seconds since midnight plus a
/// nanosecond component, or `None` if `secs` is outside `0..=86399` or
/// `nano` is outside `0..=1_999_999_999`.
pub fn NaiveTime::from_num_seconds_from_midnight(
  secs : Int,
  nano : Int,
) -> NaiveTime? {
  if secs < 0 || secs > 86399 {
    None
  } else if nano < 0 || nano >= 2_000_000_000 {
    None
  } else {
    Some(NaiveTime::{ secs, frac: nano, })
  }
}

///|
/// The hour of the day, `0..=23`.
pub fn NaiveTime::hour(self : NaiveTime) -> Int {
  self.secs / 3600
}

///|
/// The minute of the hour, `0..=59`.
pub fn NaiveTime::minute(self : NaiveTime) -> Int {
  self.secs / 60 % 60
}

///|
/// The second of the minute, `0..=59`. Never reports `60` for a leap
/// second; use `nanosecond` to detect one.
pub fn NaiveTime::second(self : NaiveTime) -> Int {
  self.secs % 60
}

///|
/// The nanosecond component, normally `0..=999_999_999`. A value of
/// `1_000_000_000` or above indicates this time represents a leap second
/// (displayed as `second() + 1`, i.e. `:60`), with the leap second's own
/// fractional part equal to `nanosecond() - 1_000_000_000`.
pub fn NaiveTime::nanosecond(self : NaiveTime) -> Int {
  self.frac
}

///|
/// The count of seconds since midnight, `0..=86399`. Does not account for a
/// leap second's extra elapsed second; use `nanosecond` for that.
pub fn NaiveTime::num_seconds_from_midnight(self : NaiveTime) -> Int {
  self.secs
}

///|
/// The hour of the day on a 12-hour clock, paired with whether it is PM.
/// Midnight and noon both report hour `12` (`(false, 12)` and `(true, 12)`
/// respectively).
pub fn NaiveTime::hour12(self : NaiveTime) -> (Bool, Int) {
  let hour = self.hour()
  let is_pm = hour >= 12
  let hour12 = hour % 12
  (is_pm, if hour12 == 0 { 12 } else { hour12 })
}

///|
/// This time advanced by the signed duration `delta`, wrapping across
/// midnight. Returns the wrapped time together with the number of whole
/// days the addition crossed (negative if `delta` is negative enough to
/// cross backward).
///
/// A zero `delta` returns this time unchanged, exactly preserving a leap
/// second. Any other `delta` resolves the arithmetic assuming no day has a
/// leap second, since `NaiveTime` carries no calendar context to know
/// whether a nearby day actually has one; a leap second's extra elapsed
/// second is treated as consumed once time moves away from it in either
/// direction.
pub fn NaiveTime::overflowing_add_signed(
  self : NaiveTime,
  delta : TimeDelta,
) -> (NaiveTime, Int64) {
  if delta.is_zero() {
    (self, 0L)
  } else {
    let leap = self.frac >= 1_000_000_000
    let self_extra_secs = if leap { 1 } else { 0 }
    let frac_rem = if leap { self.frac - 1_000_000_000 } else { self.frac }
    let delta_secs = delta.num_seconds()
    let delta_nanos = delta.subsec_nanoseconds()
    let delta_days = floor_div64(delta_secs, 86400L)
    let delta_secs_in_day = floor_mod64(delta_secs, 86400L).to_int()
    let secs_sum = self.secs + self_extra_secs + delta_secs_in_day
    let nanos_sum = frac_rem + delta_nanos
    let nanos_carry = floor_div(nanos_sum, 1_000_000_000)
    let final_nanos = floor_mod(nanos_sum, 1_000_000_000)
    let total_secs_of_day = secs_sum + nanos_carry
    let extra_days = floor_div(total_secs_of_day, 86400)
    let wrapped_secs = floor_mod(total_secs_of_day, 86400)
    let total_days = delta_days + extra_days.to_int64()
    (NaiveTime::{ secs: wrapped_secs, frac: final_nanos, }, total_days)
  }
}

///|
/// This time moved back by the signed duration `delta`. See
/// `overflowing_add_signed` for the wrapping and leap-second rules.
pub fn NaiveTime::overflowing_sub_signed(
  self : NaiveTime,
  delta : TimeDelta,
) -> (NaiveTime, Int64) {
  self.overflowing_add_signed(delta.neg())
}
