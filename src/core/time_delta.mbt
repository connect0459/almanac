///|
/// Nanoseconds per second.
const NANOS_PER_SEC : Int64 = 1_000_000_000L

///|
/// Bound on a duration's magnitude in seconds, chosen so `num_milliseconds`
/// always fits in `Int64` (`Int64::max_value / 1000`, with headroom). The
/// representable range is exactly `-MAX_SECS..=MAX_SECS` seconds, so a
/// duration is valid when its absolute value does not exceed `MAX_SECS`
/// seconds; that symmetry is what makes `neg` and `abs` total.
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
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend TimeDelta with Eq::{equal}

///|
pub extend TimeDelta with Eq::{not_equal}

///|
pub extend TimeDelta with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend TimeDelta with Hash::{hash, hash_combine}

///|
/// The zero-length duration; see `zero`.
pub impl Default for TimeDelta with fn default() {
  TimeDelta::zero()
}

///|
pub extend TimeDelta with Default::{default}

///|
pub extend TimeDelta with @debug.Debug::{to_repr}

///|
/// Renders the duration compactly: an optional leading
/// `-`, then hours, minutes and seconds (`1h2m3.5s`) with hours as the
/// largest unit, no fractional part's trailing zeros, and every unit between
/// the largest and the seconds kept even when zero (`1h0m0s`). A duration
/// under one second uses `ns`, `us` or `ms` instead (`1.5ms`), and zero is
/// `0s`.
pub impl Show for TimeDelta with fn output(self, logger) {
  let magnitude = self.abs()
  if self.seconds < 0L {
    logger.write_char('-')
  }
  if magnitude.seconds == 0L {
    write_subsecond(magnitude.nanoseconds, logger)
  } else {
    let secs = magnitude.seconds
    let hours = secs / 3600L
    let minutes = secs % 3600L / 60L
    if hours > 0L {
      logger.write_string(hours.to_string() + "h")
    }
    if hours > 0L || minutes > 0L {
      logger.write_string(minutes.to_string() + "m")
    }
    logger.write_string((secs % 60L).to_string())
    write_fraction(magnitude.nanoseconds, 9, logger)
    logger.write_char('s')
  }
}

///|
pub extend TimeDelta with Show::{to_string, output}

///|
fn write_subsecond(nanos : Int, logger : &Logger) -> Unit {
  if nanos == 0 {
    logger.write_string("0s")
  } else if nanos < 1_000 {
    logger.write_string(nanos.to_string() + "ns")
  } else if nanos < 1_000_000 {
    logger.write_string((nanos / 1_000).to_string())
    write_fraction(nanos % 1_000, 3, logger)
    logger.write_string("us")
  } else {
    logger.write_string((nanos / 1_000_000).to_string())
    write_fraction(nanos % 1_000_000, 6, logger)
    logger.write_string("ms")
  }
}

///|
fn write_fraction(value : Int, width : Int, logger : &Logger) -> Unit {
  if value != 0 {
    let mut digits = value.to_string()
    while digits.length() < width {
      digits = "0" + digits
    }
    let mut end = digits.length()
    while digits[end - 1] == '0' {
      end -= 1
    }
    logger.write_char('.')
    logger.write_string(digits[:end].to_owned())
  }
}

///|
/// Builds a `TimeDelta` from a whole-seconds component and a nanosecond
/// component of arbitrary sign and magnitude, normalizing the nanoseconds
/// into the `0..=999_999_999` range and carrying the excess into `seconds`.
/// Returns `None` if the result's magnitude exceeds `MAX_SECS` seconds (a
/// `MAX_SECS` boundary value must have no nanosecond remainder).
fn from_secs_nanos(secs : Int64, nanos : Int64) -> TimeDelta? {
  let extra_secs = floor_div64(nanos, NANOS_PER_SEC)
  let rem_nanos = floor_mod64(nanos, NANOS_PER_SEC)
  match checked_add64(secs, extra_secs) {
    None => None
    Some(total_secs) =>
      if total_secs < MIN_SECS ||
        total_secs > MAX_SECS ||
        (total_secs == MAX_SECS && rem_nanos != 0L) {
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
/// The duration of `seconds` whole seconds plus `nanoseconds`, which must be
/// in `0..=999_999_999`: the sign of the duration is carried entirely by
/// `seconds`, so `new(-1L, 500_000_000)` is minus half a second. Returns
/// `None` if `nanoseconds` is outside that range or the result does not
/// fit in the representable range.
pub fn TimeDelta::new(seconds : Int64, nanoseconds : Int) -> TimeDelta? {
  if nanoseconds < 0 || nanoseconds >= 1_000_000_000 {
    None
  } else {
    from_secs_nanos(seconds, nanoseconds.to_int64())
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
  from_secs_nanos(floor_div64(n, 1_000L), floor_mod64(n, 1_000L) * 1_000_000L)
}

///|
/// The duration of the given number of whole microseconds, or `None` if it
/// does not fit in the representable range.
pub fn TimeDelta::microseconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(
    floor_div64(n, 1_000_000L),
    floor_mod64(n, 1_000_000L) * 1_000L,
  )
}

///|
/// The duration of the given number of whole nanoseconds, or `None` if it
/// does not fit in the representable range.
pub fn TimeDelta::nanoseconds(n : Int64) -> TimeDelta? {
  from_secs_nanos(0L, n)
}

///|
/// The duration of zero length; `Default::default()` returns it.
pub fn TimeDelta::zero() -> TimeDelta {
  TimeDelta::{ seconds: 0L, nanoseconds: 0, }
}

///|
/// The most negative representable duration, exactly `-9_223_372_036_854_774`
/// seconds: the negation of `max_value`. The range is part of the type's
/// contract and will not change.
pub fn TimeDelta::min_value() -> TimeDelta {
  TimeDelta::{ seconds: MIN_SECS, nanoseconds: 0, }
}

///|
/// The most positive representable duration, exactly `9_223_372_036_854_774`
/// seconds with no nanosecond remainder: the negation of `min_value`. The
/// range is part of the type's contract and will not change.
pub fn TimeDelta::max_value() -> TimeDelta {
  TimeDelta::{ seconds: MAX_SECS, nanoseconds: 0, }
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
/// This duration's total length in fractional seconds, as a 64-bit float.
/// Loses precision for a very large duration; never fails.
pub fn TimeDelta::as_seconds_double(self : TimeDelta) -> Double {
  self.seconds.to_double() + self.nanoseconds.to_double() / 1_000_000_000.0
}

///|
/// The duration of `seconds` fractional seconds, rounded to the nearest
/// nanosecond with an exact half-nanosecond tie breaking away from zero (so
/// a decimal such as `0.3` becomes exactly 300 000 000 ns despite its
/// binary representation error). `None` for NaN, an infinity, or a value
/// outside the representable range. A `Double` carries about 15 significant
/// digits, so a very large duration cannot keep nanosecond precision; the
/// nanosecond is exact only while the whole-second part is below about
/// 9 million seconds.
pub fn TimeDelta::from_seconds_double(seconds : Double) -> TimeDelta? {
  if seconds.is_nan() || seconds.is_inf() {
    return None
  }
  let whole = seconds.floor()
  if whole > 9.0e18 || whole < -9.0e18 {
    return None
  }
  let scaled = (seconds - whole) * 1.0e9
  let rounded = scaled.round()
  let nanos = if seconds < 0.0 && rounded - scaled == 0.5 {
    rounded - 1.0
  } else {
    rounded
  }
  from_secs_nanos(whole.to_int64(), nanos.to_int64())
}

///|
/// This duration's total length in fractional minutes, as a 64-bit float.
/// Loses precision for a very large duration; never fails.
pub fn TimeDelta::as_minutes_double(self : TimeDelta) -> Double {
  self.as_seconds_double() / 60.0
}

///|
/// This duration's total length in fractional hours, as a 64-bit float.
/// Loses precision for a very large duration; never fails.
pub fn TimeDelta::as_hours_double(self : TimeDelta) -> Double {
  self.as_seconds_double() / 3600.0
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
/// The total of `deltas`; an empty array totals `zero()`. The result does
/// not depend on the order of `deltas` (see `checked_sum`).
///
/// Aborts if the true total falls outside the representable range; use
/// `checked_sum` to get `None` instead.
pub fn TimeDelta::sum(deltas : Array[TimeDelta]) -> TimeDelta {
  expect_in_range(TimeDelta::checked_sum(deltas), "TimeDelta::sum")
}

///|
/// The sum of two durations.
///
/// Aborts if it overflows the representable range; use `checked_add` to get
/// `None` instead.
pub fn TimeDelta::add(self : TimeDelta, other : TimeDelta) -> TimeDelta {
  expect_in_range(self.checked_add(other), "TimeDelta::add")
}

///|
/// The difference of two durations.
///
/// Aborts if it overflows the representable range; use `checked_sub` to get
/// `None` instead.
pub fn TimeDelta::sub(self : TimeDelta, other : TimeDelta) -> TimeDelta {
  expect_in_range(self.checked_sub(other), "TimeDelta::sub")
}

///|
/// This duration multiplied by the integer `scalar`.
///
/// Aborts if it overflows the representable range; use `checked_mul` to get
/// `None` instead.
pub fn TimeDelta::mul(self : TimeDelta, scalar : Int) -> TimeDelta {
  expect_in_range(self.checked_mul(scalar), "TimeDelta::mul")
}

///|
/// This duration divided by the integer `scalar`, truncated toward zero.
///
/// Aborts if `scalar` is zero; use `checked_div` to get `None` instead.
pub fn TimeDelta::div(self : TimeDelta, scalar : Int) -> TimeDelta {
  if scalar == 0 {
    abort("TimeDelta::div: division by zero")
  }
  expect_in_range(self.checked_div(scalar), "TimeDelta::div")
}

///|
/// The total of `deltas`, or `None` if the true total falls outside the
/// representable range; an empty array totals `zero()`. Unlike folding with
/// `checked_add`, the result does not depend on the order of `deltas`: a partial sum
/// that would leave the range does not make the whole sum `None`, as long
/// as the true total is representable. (Seconds are accumulated as
/// `high * 2^31 + low`, so no partial sum can overflow `Int64` whatever the
/// order or length; `scaled + total_low` cannot overflow either, since
/// `scaled` is a multiple of `2^31` and `total_low` is below it.)
pub fn TimeDelta::checked_sum(deltas : Array[TimeDelta]) -> TimeDelta? {
  let block = 2_147_483_648L
  let mut high = 0L
  let mut low = 0L
  let mut nanos = 0L
  for delta in deltas {
    high += floor_div64(delta.seconds, block)
    low += floor_mod64(delta.seconds, block)
    nanos += delta.nanoseconds.to_int64()
  }
  let total_high = high + floor_div64(low, block)
  let total_low = floor_mod64(low, block)
  checked_mul64(total_high, block).bind(scaled => {
    from_secs_nanos(scaled + total_low, nanos)
  })
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
pub fn TimeDelta::checked_add(
  self : TimeDelta,
  other : TimeDelta,
) -> TimeDelta? {
  from_secs_nanos(
    self.seconds + other.seconds,
    self.nanoseconds.to_int64() + other.nanoseconds.to_int64(),
  )
}

///|
/// The difference of two durations, or `None` if it overflows the
/// representable range.
pub fn TimeDelta::checked_sub(
  self : TimeDelta,
  other : TimeDelta,
) -> TimeDelta? {
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
pub fn TimeDelta::checked_mul(self : TimeDelta, scalar : Int) -> TimeDelta? {
  let scalar64 = scalar.to_int64()
  match checked_mul64(self.seconds, scalar64) {
    None => None
    Some(secs) => from_secs_nanos(secs, self.nanoseconds.to_int64() * scalar64)
  }
}

///|
/// This duration divided by the integer `scalar`, truncated toward zero, or
/// `None` if `scalar` is zero.
pub fn TimeDelta::checked_div(self : TimeDelta, scalar : Int) -> TimeDelta? {
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
/// `a + b`: the sum of two durations. Aborts on overflow; see `add`.
pub impl Add for TimeDelta with fn add(self, other) {
  TimeDelta::add(self, other)
}

///|
/// `a - b`: the difference of two durations. Aborts on overflow; see `sub`.
pub impl Sub for TimeDelta with fn sub(self, other) {
  TimeDelta::sub(self, other)
}

///|
/// `-a`: the negation of a duration; see `neg`.
pub impl Neg for TimeDelta with fn neg(self) {
  TimeDelta::neg(self)
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
/// why it is rejected: `InvalidGranularity` if it is zero or negative,
/// `MixedGranularity` if it mixes a whole-second part with a sub-second
/// remainder (see `Granularity`).
fn classify_granularity(
  granularity : TimeDelta,
) -> Result[Granularity, RoundingError] {
  if granularity.seconds < 0L {
    Err(InvalidGranularity)
  } else if granularity.seconds == 0L {
    if granularity.nanoseconds > 0 {
      Ok(SubSecond(granularity.nanoseconds))
    } else {
      Err(InvalidGranularity)
    }
  } else if granularity.nanoseconds == 0 {
    Ok(WholeSeconds(granularity.seconds))
  } else {
    Err(MixedGranularity)
  }
}

///|
fn[T] in_range(value : T?) -> Result[T, RoundingError] {
  match value {
    Some(v) => Ok(v)
    None => Err(OutOfRange)
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
/// `granularity`. Fails with `InvalidGranularity` if `granularity` is zero
/// or negative, or `MixedGranularity` if it mixes a whole-second part with
/// a sub-second remainder (e.g. 1.5 seconds) — see `Granularity`.
pub fn TimeDelta::truncate(
  self : TimeDelta,
  granularity : TimeDelta,
) -> Result[TimeDelta, RoundingError] {
  let kind = match classify_granularity(granularity) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  in_range(self.checked_sub(signed_remainder(self, kind)))
}

///|
/// This duration rounded to the nearest multiple of `granularity`, ties
/// (an exact half-multiple) breaking away from zero. See `truncate` for the
/// conditions under which `granularity` is rejected.
pub fn TimeDelta::round(
  self : TimeDelta,
  granularity : TimeDelta,
) -> Result[TimeDelta, RoundingError] {
  let kind = match classify_granularity(granularity) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let remainder = signed_remainder(self, kind)
  let truncated = self.checked_sub(remainder)
  in_range(
    if compare_magnitude(
        double_magnitude(remainder.abs()),
        granularity_magnitude(kind),
      ) <
      0 {
      truncated
    } else if self.seconds < 0L {
      truncated.bind(t => t.checked_sub(granularity_magnitude(kind)))
    } else {
      truncated.bind(t => t.checked_add(granularity_magnitude(kind)))
    },
  )
}

///|
/// This duration rounded up (toward positive infinity) to the nearest
/// multiple of `granularity`: unchanged if already a multiple, otherwise
/// the next multiple above it. For a negative duration that is toward zero,
/// the same result as `truncate`. Fails if `granularity` is rejected (see
/// `truncate`), or with `OutOfRange` if rounding up would leave
/// `TimeDelta`'s representable range.
pub fn TimeDelta::round_up(
  self : TimeDelta,
  granularity : TimeDelta,
) -> Result[TimeDelta, RoundingError] {
  let kind = match classify_granularity(granularity) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let remainder = signed_remainder(self, kind)
  in_range(
    if remainder.is_zero() {
      Some(self)
    } else if self.seconds < 0L {
      self.checked_sub(remainder)
    } else {
      self
      .checked_sub(remainder)
      .bind(t => t.checked_add(granularity_magnitude(kind)))
    },
  )
}
