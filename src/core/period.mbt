///|
/// A calendar period of years, months and days.
///
/// Unlike `TimeDelta`, a period has no fixed length: what a month or a year
/// amounts to in days depends on the date it is applied to. Components are
/// kept as given and carry independent signs, so `months=14` and
/// `years=1, months=2` are distinct values.
pub struct Period {
  priv years : Int32
  priv months : Int32
  priv days : Int32
} derive(Eq, Hash, @debug.Debug)

///|
pub extend Period with Eq::{equal, not_equal}

///|
pub extend Period with Hash::{hash, hash_combine}

///|
pub extend Period with @debug.Debug::{to_repr}

///|
pub impl Default for Period with fn default() {
  Period::zero()
}

///|
pub extend Period with Default::{default}

///|
/// Renders the period in the ISO 8601 date-based duration style (`P1Y2M3D`),
/// omitting zero components. The zero period is `P0D`. A negative component
/// keeps its own leading `-` (`P-1Y3D`); that per-component sign is an
/// extension beyond ISO 8601, and `parse_iso8601_duration` does not read
/// this output back.
pub impl Show for Period with fn output(self, logger) {
  if self.is_zero() {
    logger.write_string("P0D")
  } else {
    logger.write_char('P')
    if self.years != 0 {
      logger.write_string(self.years.to_string() + "Y")
    }
    if self.months != 0 {
      logger.write_string(self.months.to_string() + "M")
    }
    if self.days != 0 {
      logger.write_string(self.days.to_string() + "D")
    }
  }
}

///|
pub extend Period with Show::{to_string, output}

///|
/// Builds a period from its components; omitted components are zero.
pub fn Period::new(
  years~ : Int32 = 0,
  months~ : Int32 = 0,
  days~ : Int32 = 0,
) -> Period {
  { years, months, days, }
}

///|
/// The period of zero years, months and days; `Default::default()` returns
/// it.
pub fn Period::zero() -> Period {
  { years: 0, months: 0, days: 0, }
}

///|
pub fn Period::years(self : Period) -> Int32 {
  self.years
}

///|
pub fn Period::months(self : Period) -> Int32 {
  self.months
}

///|
pub fn Period::days(self : Period) -> Int32 {
  self.days
}

///|
/// Whether every component is zero.
pub fn Period::is_zero(self : Period) -> Bool {
  self.years == 0 && self.months == 0 && self.days == 0
}

///|
/// The period with every component negated, or `None` if a component is
/// `Int32::min_value` and so has no representable negation.
pub fn Period::checked_neg(self : Period) -> Period? {
  Period::zero().checked_sub(self)
}

///|
/// The component-wise sum, or `None` if any component overflows.
pub fn Period::checked_add(self : Period, other : Period) -> Period? {
  combine_components(self, other, fn(a, b) { a.to_int64() + b.to_int64() })
}

///|
/// The component-wise difference, or `None` if any component overflows.
pub fn Period::checked_sub(self : Period, other : Period) -> Period? {
  combine_components(self, other, fn(a, b) { a.to_int64() - b.to_int64() })
}

///|
/// Every component multiplied by `scalar`, or `None` if any component
/// overflows.
pub fn Period::checked_mul(self : Period, scalar : Int32) -> Period? {
  let factor = Period::new(years=scalar, months=scalar, days=scalar)
  combine_components(self, factor, fn(a, b) { a.to_int64() * b.to_int64() })
}

///|
fn combine_components(
  a : Period,
  b : Period,
  op : (Int32, Int32) -> Int64,
) -> Period? {
  match
    (
      narrow32(op(a.years, b.years)),
      narrow32(op(a.months, b.months)),
      narrow32(op(a.days, b.days)),
    ) {
    (Some(years), Some(months), Some(days)) =>
      Some(Period::new(years~, months~, days~))
    _ => None
  }
}

///|
fn narrow32(value : Int64) -> Int32? {
  if value < -2147483648L || value > 2147483647L {
    None
  } else {
    Some(value.to_int())
  }
}
