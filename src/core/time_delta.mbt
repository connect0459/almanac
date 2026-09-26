///|
/// Nanoseconds per second.
const NANOS_PER_SEC : Int64 = 1_000_000_000L

///|
/// Bound for the `seconds` component, chosen so `num_milliseconds` always
/// fits in `Int64` (`Int64::max_value / 1000`, with headroom so the
/// nanosecond remainder can never push the millisecond count past
/// `Int64::max_value`). Symmetric with the lower bound so `abs` is always
/// total.
const MAX_SECS : Int64 = 9_223_372_036_854_774L

///|
const MIN_SECS : Int64 = -9_223_372_036_854_774L

///|
/// A signed duration, precise to the nanosecond.
///
/// Internally represented as whole seconds plus a non-negative nanosecond
/// remainder (`0..=999_999_999`); the sign of the duration is carried
/// entirely by the seconds component.
pub struct TimeDelta {
  priv seconds : Int64
  priv nanoseconds : Int
} derive(Eq, @debug.Debug)

///|
pub extend TimeDelta with Eq::{equal}

///|
pub extend TimeDelta with Eq::{not_equal}

///|
pub extend TimeDelta with @debug.Debug::{to_repr}

///|
/// Builds a `TimeDelta` from a whole-seconds component and a nanosecond
/// component of arbitrary sign and magnitude, normalizing the nanoseconds
/// into the `0..=999_999_999` range and carrying the excess into `seconds`.
/// Returns `None` if the normalized seconds fall outside the representable
/// range.
fn from_secs_nanos(secs : Int64, nanos : Int64) -> TimeDelta? {
  let extra_secs = floor_div64(nanos, NANOS_PER_SEC)
  let rem_nanos = floor_mod64(nanos, NANOS_PER_SEC)
  match checked_add64(secs, extra_secs) {
    None => None
    Some(total_secs) =>
      if total_secs < MIN_SECS || total_secs > MAX_SECS {
        None
      } else {
        Some(TimeDelta::{
          seconds: total_secs,
          nanoseconds: rem_nanos.to_int(),
        })
      }
  }
}

///|
/// The duration of the given number of whole weeks, or `None` if it does
/// not fit in the representable range.
pub fn TimeDelta::weeks(n : Int64) -> TimeDelta? {
  match checked_mul64(n, 604800L) {
    None => None
    Some(secs) => from_secs_nanos(secs, 0L)
  }
}

///|
/// The duration of the given number of whole days, or `None` if it does
/// not fit in the representable range.
pub fn TimeDelta::days(n : Int64) -> TimeDelta? {
  match checked_mul64(n, 86400L) {
    None => None
    Some(secs) => from_secs_nanos(secs, 0L)
  }
}

///|
/// The duration of the given number of whole hours, or `None` if it does
/// not fit in the representable range.
pub fn TimeDelta::hours(n : Int64) -> TimeDelta? {
  match checked_mul64(n, 3600L) {
    None => None
    Some(secs) => from_secs_nanos(secs, 0L)
  }
}

///|
/// The duration of the given number of whole minutes, or `None` if it does
/// not fit in the representable range.
pub fn TimeDelta::minutes(n : Int64) -> TimeDelta? {
  match checked_mul64(n, 60L) {
    None => None
    Some(secs) => from_secs_nanos(secs, 0L)
  }
}

///|
/// The duration of the given number of whole seconds, or `None` if it does
/// not fit in the representable range.
pub fn TimeDelta::seconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(n, 0L)
}

///|
/// The duration of the given number of whole milliseconds, or `None` if it
/// does not fit in the representable range.
pub fn TimeDelta::milliseconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(0L, n * 1_000_000L)
}

///|
/// The duration of the given number of whole microseconds, or `None` if it
/// does not fit in the representable range.
pub fn TimeDelta::microseconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(0L, n * 1_000L)
}

///|
/// The duration of the given number of whole nanoseconds, or `None` if it
/// does not fit in the representable range.
pub fn TimeDelta::nanoseconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(0L, n)
}

///|
/// The duration of zero length.
pub fn TimeDelta::zero() -> TimeDelta {
  TimeDelta::{ seconds: 0L, nanoseconds: 0, }
}

///|
/// The most negative representable duration.
pub fn TimeDelta::min_value() -> TimeDelta {
  TimeDelta::{ seconds: MIN_SECS, nanoseconds: 0, }
}

///|
/// The most positive representable duration.
pub fn TimeDelta::max_value() -> TimeDelta {
  TimeDelta::{ seconds: MAX_SECS, nanoseconds: 999_999_999, }
}

///|
/// The number of whole seconds in this duration, truncated toward zero
/// (e.g. a duration of `-1.7s` reports `-1`, not `-2`).
pub fn TimeDelta::num_seconds(self : TimeDelta) -> Int64 {
  if self.seconds < 0L && self.nanoseconds > 0 {
    self.seconds + 1L
  } else {
    self.seconds
  }
}

///|
/// The nanosecond remainder such that
/// `self.num_seconds() * 1_000_000_000 + self.subsec_nanoseconds()` equals
/// this duration's total nanosecond count. Carries the same sign as the
/// overall duration, so it may be negative even though the internal
/// representation's nanosecond component is always non-negative.
pub fn TimeDelta::subsec_nanoseconds(self : TimeDelta) -> Int {
  if self.seconds < 0L && self.nanoseconds > 0 {
    self.nanoseconds - 1_000_000_000
  } else {
    self.nanoseconds
  }
}

///|
/// The `subsec_nanoseconds` remainder expressed in whole milliseconds,
/// truncated toward zero.
pub fn TimeDelta::subsec_milliseconds(self : TimeDelta) -> Int {
  self.subsec_nanoseconds() / 1_000_000
}

///|
/// The `subsec_nanoseconds` remainder expressed in whole microseconds,
/// truncated toward zero.
pub fn TimeDelta::subsec_microseconds(self : TimeDelta) -> Int {
  self.subsec_nanoseconds() / 1_000
}

///|
/// The number of whole weeks in this duration, truncated toward zero.
pub fn TimeDelta::num_weeks(self : TimeDelta) -> Int64 {
  self.num_seconds() / 604800L
}

///|
/// The number of whole days in this duration, truncated toward zero.
pub fn TimeDelta::num_days(self : TimeDelta) -> Int64 {
  self.num_seconds() / 86400L
}

///|
/// The number of whole hours in this duration, truncated toward zero.
pub fn TimeDelta::num_hours(self : TimeDelta) -> Int64 {
  self.num_seconds() / 3600L
}

///|
/// The number of whole minutes in this duration, truncated toward zero.
pub fn TimeDelta::num_minutes(self : TimeDelta) -> Int64 {
  self.num_seconds() / 60L
}

///|
/// The number of whole milliseconds in this duration, truncated toward
/// zero. Always succeeds: the representable range of `TimeDelta` is chosen
/// so this count never overflows `Int64` (unlike `num_microseconds` and
/// `num_nanoseconds`, which can).
pub fn TimeDelta::num_milliseconds(self : TimeDelta) -> Int64 {
  self.num_seconds() * 1000L +
  (self.subsec_nanoseconds() / 1_000_000).to_int64()
}

///|
/// The number of whole microseconds in this duration, truncated toward
/// zero, or `None` if it does not fit in `Int64`.
pub fn TimeDelta::num_microseconds(self : TimeDelta) -> Int64? {
  match checked_mul64(self.num_seconds(), 1_000_000L) {
    None => None
    Some(secs_part) =>
      checked_add64(secs_part, (self.subsec_nanoseconds() / 1_000).to_int64())
  }
}

///|
/// The number of whole nanoseconds in this duration, or `None` if it does
/// not fit in `Int64`.
pub fn TimeDelta::num_nanoseconds(self : TimeDelta) -> Int64? {
  match checked_mul64(self.num_seconds(), NANOS_PER_SEC) {
    None => None
    Some(secs_part) =>
      checked_add64(secs_part, self.subsec_nanoseconds().to_int64())
  }
}

///|
/// The sum of two durations, or `None` if it overflows the representable
/// range.
///
/// The addition of the `seconds` components alone can never overflow
/// `Int64` (both operands are already bounded well within `Int64`'s range
/// by the representable-range check every `TimeDelta` satisfies), so no
/// separate overflow check is needed here beyond the one `from_secs_nanos`
/// already performs.
pub fn TimeDelta::add(self : TimeDelta, other : TimeDelta) -> TimeDelta? {
  from_secs_nanos(
    self.seconds + other.seconds,
    self.nanoseconds.to_int64() + other.nanoseconds.to_int64(),
  )
}

///|
/// The difference of two durations, or `None` if it overflows the
/// representable range.
pub fn TimeDelta::sub(self : TimeDelta, other : TimeDelta) -> TimeDelta? {
  from_secs_nanos(
    self.seconds - other.seconds,
    self.nanoseconds.to_int64() - other.nanoseconds.to_int64(),
  )
}

///|
/// This duration multiplied by the integer `scalar`, or `None` if it
/// overflows the representable range.
///
/// Only the `seconds` component's multiplication needs a checked
/// (`Int64`-overflowing) guard: `nanoseconds` is always below one second,
/// so `nanoseconds * scalar` stays well within `Int64` for any `Int`
/// `scalar`.
pub fn TimeDelta::mul(self : TimeDelta, scalar : Int) -> TimeDelta? {
  let scalar64 = scalar.to_int64()
  match checked_mul64(self.seconds, scalar64) {
    None => None
    Some(secs) => from_secs_nanos(secs, self.nanoseconds.to_int64() * scalar64)
  }
}

///|
/// This duration divided by the integer `scalar`, truncated toward zero, or
/// `None` if `scalar` is zero.
pub fn TimeDelta::div(self : TimeDelta, scalar : Int) -> TimeDelta? {
  if scalar == 0 {
    None
  } else {
    let scalar64 = scalar.to_int64()
    let secs_q = self.seconds / scalar64
    let secs_r = self.seconds % scalar64
    let nanos_total = secs_r * NANOS_PER_SEC + self.nanoseconds.to_int64()
    from_secs_nanos(secs_q, nanos_total / scalar64)
  }
}

///|
/// The negation of this duration. Always representable: the representable
/// range is symmetric around zero specifically so this is total.
pub fn TimeDelta::neg(self : TimeDelta) -> TimeDelta {
  if self.nanoseconds == 0 {
    TimeDelta::{ seconds: -self.seconds, nanoseconds: 0, }
  } else {
    TimeDelta::{
      seconds: -self.seconds - 1L,
      nanoseconds: 1_000_000_000 - self.nanoseconds,
    }
  }
}

///|
/// The absolute value of this duration.
pub fn TimeDelta::abs(self : TimeDelta) -> TimeDelta {
  if self.seconds >= 0L {
    self
  } else {
    self.neg()
  }
}

///|
/// Whether this duration is exactly zero.
pub fn TimeDelta::is_zero(self : TimeDelta) -> Bool {
  self.seconds == 0L && self.nanoseconds == 0
}
