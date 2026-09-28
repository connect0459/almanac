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

///|
/// A rounding/truncation granularity, classified into the only two shapes
/// `TimeDelta::round`/`truncate` support: a whole number of sub-second
/// nanoseconds, or a whole-second-or-larger multiple. A granularity
/// combining both (e.g. 1.5 seconds) is rejected by `classify_granularity`
/// rather than represented here: supporting it in general would require
/// arbitrary-precision arithmetic, since `TimeDelta`'s `seconds` component
/// is far too large to convert to a single nanosecond count (see
/// `num_nanoseconds`, which is already `Option`-returning for exactly this
/// reason).
priv enum Granularity {
  SubSecond(Int)
  WholeSeconds(Int64)
}

///|
/// Classifies `granularity` for `TimeDelta::round`/`truncate`, or reports
/// `None` if it is zero, negative, or mixes a whole-second part with a
/// sub-second remainder (see `Granularity`).
fn classify_granularity(granularity : TimeDelta) -> Granularity? {
  if granularity.seconds < 0L {
    None
  } else if granularity.seconds == 0L {
    if granularity.nanoseconds > 0 {
      Some(SubSecond(granularity.nanoseconds))
    } else {
      None
    }
  } else if granularity.nanoseconds == 0 {
    Some(WholeSeconds(granularity.seconds))
  } else {
    None
  }
}

///|
/// The remainder of dividing the non-negative magnitude `mag` by the
/// granularity `kind`, itself non-negative and strictly less than the
/// granularity. Computed without ever converting `mag` to a single
/// nanosecond count, which could overflow `Int64` for a `TimeDelta` far
/// from zero.
fn remainder_magnitude(mag : TimeDelta, kind : Granularity) -> TimeDelta {
  match kind {
    SubSecond(nanos_per_unit) => {
      let unit = nanos_per_unit.to_int64()
      // `mag.seconds % unit` is bounded by `unit < NANOS_PER_SEC`, so
      // multiplying it back out by `NANOS_PER_SEC` stays well within
      // Int64's range regardless of how large `mag.seconds` itself is.
      let seconds_remainder = mag.seconds % unit
      let combined = (
          seconds_remainder * NANOS_PER_SEC + mag.nanoseconds.to_int64()
        ) %
        unit
      TimeDelta::{ seconds: 0L, nanoseconds: combined.to_int(), }
    }
    WholeSeconds(seconds_per_unit) =>
      TimeDelta::{
        seconds: mag.seconds % seconds_per_unit,
        nanoseconds: mag.nanoseconds,
      }
  }
}

///|
/// The signed remainder of dividing `td` by the granularity `kind`,
/// carrying the same sign as `td` (or zero). Its magnitude is always
/// strictly less than `td`'s own, so subtracting it from `td` can never
/// push the result outside `TimeDelta`'s representable range.
fn signed_remainder(td : TimeDelta, kind : Granularity) -> TimeDelta {
  let remainder = remainder_magnitude(td.abs(), kind)
  if td.seconds < 0L {
    remainder.neg()
  } else {
    remainder
  }
}

///|
/// The granularity `kind` itself, expressed as a `TimeDelta` magnitude.
fn granularity_magnitude(kind : Granularity) -> TimeDelta {
  match kind {
    SubSecond(nanos_per_unit) =>
      TimeDelta::{ seconds: 0L, nanoseconds: nanos_per_unit, }
    WholeSeconds(seconds_per_unit) =>
      TimeDelta::{ seconds: seconds_per_unit, nanoseconds: 0, }
  }
}

///|
/// Twice a non-negative `TimeDelta` magnitude, carrying any nanosecond
/// overflow into `seconds`. Never overflows `Int64`: `seconds` is already
/// far below `Int64`'s range at `TimeDelta`'s own bounds (`MAX_SECS`), and
/// doubling it once more still is.
fn double_magnitude(mag : TimeDelta) -> TimeDelta {
  let doubled_nanos = mag.nanoseconds.to_int64() * 2L
  if doubled_nanos >= NANOS_PER_SEC {
    TimeDelta::{
      seconds: mag.seconds * 2L + 1L,
      nanoseconds: (doubled_nanos - NANOS_PER_SEC).to_int(),
    }
  } else {
    TimeDelta::{
      seconds: mag.seconds * 2L,
      nanoseconds: doubled_nanos.to_int(),
    }
  }
}

///|
/// Lexicographic comparison of two non-negative `TimeDelta` magnitudes:
/// negative if `a < b`, positive if `a > b`, zero if equal.
fn compare_magnitude(a : TimeDelta, b : TimeDelta) -> Int {
  if a.seconds != b.seconds {
    if a.seconds < b.seconds {
      -1
    } else {
      1
    }
  } else if a.nanoseconds != b.nanoseconds {
    if a.nanoseconds < b.nanoseconds {
      -1
    } else {
      1
    }
  } else {
    0
  }
}

///|
/// This duration truncated toward zero to the nearest multiple of
/// `granularity`. Returns `None` if `granularity` is zero, negative, or
/// mixes a whole-second part with a sub-second remainder (e.g. 1.5
/// seconds) — see `Granularity`.
pub fn TimeDelta::truncate(
  self : TimeDelta,
  granularity : TimeDelta,
) -> TimeDelta? {
  match classify_granularity(granularity) {
    None => None
    Some(kind) => self.sub(signed_remainder(self, kind))
  }
}

///|
/// This duration rounded to the nearest multiple of `granularity`, ties
/// (an exact half-multiple) breaking away from zero. See `truncate` for the
/// conditions under which `granularity` is rejected.
pub fn TimeDelta::round(
  self : TimeDelta,
  granularity : TimeDelta,
) -> TimeDelta? {
  match classify_granularity(granularity) {
    None => None
    Some(kind) => {
      let remainder = signed_remainder(self, kind)
      let truncated = self.sub(remainder)
      if compare_magnitude(
          double_magnitude(remainder.abs()),
          granularity_magnitude(kind),
        ) <
        0 {
        truncated
      } else if self.seconds < 0L {
        truncated.bind(t => t.sub(granularity_magnitude(kind)))
      } else {
        truncated.bind(t => t.add(granularity_magnitude(kind)))
      }
    }
  }
}
