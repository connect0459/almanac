///|
fn period_scan_component(
  chars : Array[Char],
  start : Int32,
  allow_sign : Bool,
) -> (Int64, Char, Int32) raise FormatError {
  let len = chars.length()
  let mut pos = start
  let mut negative = false
  if allow_sign && pos < len && chars[pos] == '-' {
    negative = true
    pos += 1
  }
  let mut magnitude = 0L
  let mut has_digits = false
  while pos < len && is_ascii_digit(chars[pos]) {
    let digit = (chars[pos].to_int() - '0'.to_int()).to_int64()
    magnitude = duration_require(
      add_nonneg(duration_require(mul_nonneg(magnitude, 10L)), digit),
    )
    has_digits = true
    pos += 1
  }
  if !has_digits || pos >= len {
    raise InvalidDuration
  }
  (if negative { -magnitude } else { magnitude }, chars[pos], pos + 1)
}

///|
fn period_narrow(value : Int64, negative : Bool) -> Int32 raise FormatError {
  let signed = if negative { -value } else { value }
  if signed < -2147483648L || signed > 2147483647L {
    raise InvalidDuration
  }
  signed.to_int()
}

///|
/// Renders `period` as an ISO 8601 duration of calendar designators:
/// `"P<y>Y<m>M<d>D"` with zero components omitted, e.g. `"P1Y2M3D"` or
/// `"P14M"`. Components are written as given, without normalizing months
/// into years or days into months. The zero period is `"P0D"`. A period
/// whose components are all zero or negative carries one leading `-`
/// (`"-P1Y3D"`); a period with components of both signs writes each sign on
/// its own component (`"P-1Y3D"`), which is an extension beyond ISO 8601.
/// `parse_iso8601_period` reads the result back unchanged, as it does the
/// output of `Period`'s `Show`. No time part is written, as that belongs to
/// `TimeDelta`.
pub fn to_iso8601_period(period : @core.Period) -> String {
  if period.is_zero() {
    return "P0D"
  }
  let years = period.years().to_int64()
  let months = period.months().to_int64()
  let days = period.days().to_int64()
  let none_positive = years <= 0L && months <= 0L && days <= 0L
  let sign = if none_positive { -1L } else { 1L }
  let buffer = StringBuilder()
  if none_positive {
    buffer.write_char('-')
  }
  buffer.write_char('P')
  for component in [(years, "Y"), (months, "M"), (days, "D")] {
    let (value, designator) = component
    if value != 0L {
      buffer.write_string((value * sign).to_string() + designator)
    }
  }
  buffer.to_string()
}

///|
/// Parses an ISO 8601 duration of calendar designators of the shape
/// `[+|-]P[<n>Y][<n>M][<n>D]`, such as `"P1Y2M3D"`, `"-P1Y3D"` or `"P0D"`.
/// The designators are upper-case, appear in that order at most once each,
/// and at least one component is required. Components are kept as given
/// (`"P14M"` is 14 months, not 1 year and 2 months). A leading sign applies
/// to every component. As an extension beyond ISO 8601, a component may
/// instead carry its own `-` (`"P-1Y3D"`), the form `Period`'s `Show`
/// writes; a leading sign and a component sign cannot be combined.
///
/// A time part (`T`), week designator and fractional number are rejected: the
/// time part belongs to `TimeDelta` (see `parse_iso8601_duration`), and a
/// `Period` counts whole calendar units only.
///
/// Raises `InvalidDuration` for anything else, or for a component outside
/// `Int32`'s range.
pub fn parse_iso8601_period(input : String) -> @core.Period raise FormatError {
  let chars = input.to_array()
  let len = chars.length()
  let mut pos = 0
  let mut leading = false
  let mut negative = false
  if pos < len && (chars[pos] == '-' || chars[pos] == '+') {
    leading = true
    negative = chars[pos] == '-'
    pos += 1
  }
  if pos >= len || chars[pos] != 'P' {
    raise InvalidDuration
  }
  pos += 1
  let mut last_rank = -1
  let mut years = 0
  let mut months = 0
  let mut days = 0
  while pos < len {
    let (value, designator, after) = period_scan_component(chars, pos, !leading)
    let rank = match designator {
      'Y' => 0
      'M' => 1
      'D' => 2
      _ => raise InvalidDuration
    }
    if rank <= last_rank {
      raise InvalidDuration
    }
    last_rank = rank
    pos = after
    let narrowed = period_narrow(value, negative)
    match rank {
      0 => years = narrowed
      1 => months = narrowed
      _ => days = narrowed
    }
  }
  if last_rank < 0 {
    raise InvalidDuration
  }
  @core.Period::new(years~, months~, days~)
}
