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
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend NaiveTime with Eq::{equal}

///|
pub extend NaiveTime with Eq::{not_equal}

///|
pub extend NaiveTime with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend NaiveTime with Hash::{hash, hash_combine}

///|
/// The start of the day, `00:00:00` with no fractional part: the earliest
/// time of day.
pub fn NaiveTime::midnight() -> NaiveTime {
  NaiveTime::{ secs: 0, frac: 0, }
}

///|
/// Midnight; see `midnight`.
pub impl Default for NaiveTime with fn default() {
  NaiveTime::midnight()
}

///|
pub extend NaiveTime with Default::{default}

///|
pub extend NaiveTime with @debug.Debug::{to_repr}

///|
/// Renders as `HH:MM:SS`, followed by a fractional part only when the
/// nanoseconds are nonzero, using the fewest of 3, 6 or 9 digits that
/// represent them exactly (`.500`, `.123456`, `.000000789`). A leap second
/// is rendered with second `60`.
pub impl Show for NaiveTime with fn output(self, logger) {
  let leap = self.nanosecond() >= 1_000_000_000
  let second = if leap { self.second() + 1 } else { self.second() }
  let nanos = if leap {
    self.nanosecond() - 1_000_000_000
  } else {
    self.nanosecond()
  }
  logger.write_string(
    pad_zero(self.hour(), 2) +
    ":" +
    pad_zero(self.minute(), 2) +
    ":" +
    pad_zero(second, 2),
  )
  if nanos == 0 {
    ()
  } else if nanos % 1_000_000 == 0 {
    logger.write_string("." + pad_zero(nanos / 1_000_000, 3))
  } else if nanos % 1_000 == 0 {
    logger.write_string("." + pad_zero(nanos / 1_000, 6))
  } else {
    logger.write_string("." + pad_zero(nanos, 9))
  }
}

///|
pub extend NaiveTime with Show::{to_string, output}

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
/// The hour, minute, and second together, as `hour`, `minute`, and `second`
/// report them.
pub fn NaiveTime::hms(self : NaiveTime) -> (Int, Int, Int) {
  (self.hour(), self.minute(), self.second())
}

///|
/// The number of nanoseconds in one unit of the `digits`-th fractional
/// digit, for `digits` in `0..=9`. Aborts for any other `digits`.
fn subsec_granularity_nanos(digits : Int, operation : String) -> Int {
  if digits < 0 || digits > 9 {
    abort(operation + ": digits must be in 0..=9")
  }
  let mut nanos = 1
  for _ in digits..<9 {
    nanos = nanos * 10
  }
  nanos
}

///|
/// This time with a leap second folded into the following second, as its
/// elapsed instant: `23:59:60.5` becomes `00:00:00.5`. An ordinary time is
/// returned unchanged.
fn NaiveTime::fold_leap_second(self : NaiveTime) -> NaiveTime {
  if self.frac >= 1_000_000_000 {
    NaiveTime::{
      secs: (self.secs + 1) % 86400,
      frac: self.frac - 1_000_000_000,
    }
  } else {
    self
  }
}

///|
/// This time truncated to `digits` fractional-second digits (`0..=9`). A time
/// with no digits beyond `digits` is returned unchanged, leap second
/// included (so `9` is always the identity). Otherwise a leap second is
/// treated as its elapsed instant and folded into the following second, so
/// the result is not a leap second.
///
/// Aborts if `digits` is outside `0..=9`.
pub fn NaiveTime::truncate_subsecs(self : NaiveTime, digits : Int) -> NaiveTime {
  let granularity = subsec_granularity_nanos(
    digits, "NaiveTime::truncate_subsecs",
  )
  if self.frac % granularity == 0 {
    return self
  }
  let time = self.fold_leap_second()
  NaiveTime::{ secs: time.secs, frac: time.frac - time.frac % granularity, }
}

///|
/// This time rounded to the nearest of `digits` fractional-second digits
/// (`0..=9`), a tie rounding up. A carry moves into the next second, minute,
/// or hour and wraps from the end of the day to midnight. A time with no
/// digits beyond `digits` is returned unchanged, leap second included (so
/// `9` is always the identity). Otherwise a leap second is treated as its
/// elapsed instant and folded into the following second, so the result is
/// not a leap second.
///
/// Aborts if `digits` is outside `0..=9`.
pub fn NaiveTime::round_subsecs(self : NaiveTime, digits : Int) -> NaiveTime {
  let granularity = subsec_granularity_nanos(digits, "NaiveTime::round_subsecs")
  if self.frac % granularity == 0 {
    return self
  }
  let time = self.fold_leap_second()
  let remainder = time.frac % granularity
  let floor = time.frac - remainder
  let rounded = if remainder * 2 >= granularity {
    floor + granularity
  } else {
    floor
  }
  if rounded >= 1_000_000_000 {
    NaiveTime::{ secs: (time.secs + 1) % 86400, frac: 0, }
  } else {
    NaiveTime::{ secs: time.secs, frac: rounded, }
  }
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

///|
/// This time advanced by the signed duration `delta`, wrapping at midnight
/// and discarding the number of days crossed (use `overflowing_add_signed`
/// to get it). See `overflowing_add_signed` for the leap-second rules.
pub fn NaiveTime::wrapping_add_signed(
  self : NaiveTime,
  delta : TimeDelta,
) -> NaiveTime {
  self.overflowing_add_signed(delta).0
}

///|
/// This time moved back by the signed duration `delta`, wrapping at
/// midnight and discarding the number of days crossed. See
/// `wrapping_add_signed`.
pub fn NaiveTime::wrapping_sub_signed(
  self : NaiveTime,
  delta : TimeDelta,
) -> NaiveTime {
  self.overflowing_sub_signed(delta).0
}

///|
/// Same minute, second, and nanosecond, with the hour changed to `hour`, or
/// `None` if `hour` is outside `0..=23`.
pub fn NaiveTime::with_hour(self : NaiveTime, hour : Int) -> NaiveTime? {
  if hour < 0 || hour > 23 {
    None
  } else {
    Some(NaiveTime::{ secs: hour * 3600 + self.secs % 3600, frac: self.frac, })
  }
}

///|
/// Same hour, second, and nanosecond, with the minute changed to `min`, or
/// `None` if `min` is outside `0..=59`.
pub fn NaiveTime::with_minute(self : NaiveTime, min : Int) -> NaiveTime? {
  if min < 0 || min > 59 {
    None
  } else {
    Some(NaiveTime::{
      secs: self.secs / 3600 * 3600 + min * 60 + self.secs % 60,
      frac: self.frac,
    })
  }
}

///|
/// Same hour, minute, and nanosecond, with the second changed to `sec`, or
/// `None` if `sec` is outside `0..=59`. As with `second`, this never
/// represents a leap second itself; use `with_nanosecond` for that.
pub fn NaiveTime::with_second(self : NaiveTime, sec : Int) -> NaiveTime? {
  if sec < 0 || sec > 59 {
    None
  } else {
    Some(NaiveTime::{ secs: self.secs / 60 * 60 + sec, frac: self.frac, })
  }
}

///|
/// Same hour, minute, and second, with the nanosecond component changed to
/// `nano`, or `None` if `nano` is outside `0..=1_999_999_999`. See
/// `nanosecond` for how a value `>= 1_000_000_000` represents a leap second.
pub fn NaiveTime::with_nanosecond(self : NaiveTime, nano : Int) -> NaiveTime? {
  if nano < 0 || nano >= 2_000_000_000 {
    None
  } else {
    Some(NaiveTime::{ secs: self.secs, frac: nano, })
  }
}

///|
/// The signed duration from `other` to `self`, treating a leap second as
/// coinciding with the prior non-leap second: its extra elapsed second is
/// only counted once time moves away from it, in whichever direction.
pub fn NaiveTime::signed_duration_since(
  self : NaiveTime,
  other : NaiveTime,
) -> TimeDelta {
  let mut secs = self.secs.to_int64() - other.secs.to_int64()
  let frac = (self.frac - other.frac).to_int64()
  if self.secs > other.secs && other.frac >= 1_000_000_000 {
    secs += 1L
  } else if self.secs < other.secs && self.frac >= 1_000_000_000 {
    secs -= 1L
  }
  from_secs_nanos(secs, frac).unwrap()
}
