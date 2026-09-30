///|
fn mul_nonneg(a : Int64, b : Int64) -> Int64? {
  let product = a * b
  if (a != 0L && product / a != b) || product < 0L {
    None
  } else {
    Some(product)
  }
}

///|
fn add_nonneg(a : Int64, b : Int64) -> Int64? {
  let sum = a + b
  if sum < a {
    None
  } else {
    Some(sum)
  }
}

///|
fn[T] duration_require(value : T?) -> T raise FormatError {
  match value {
    Some(v) => v
    None => raise InvalidDuration
  }
}

///|
/// The nanoseconds in one of `parse_duration`'s units, or `None` for an
/// unknown unit. Units are case-sensitive; microseconds may be spelled
/// `us`, `µs` (U+00B5) or `μs` (U+03BC).
fn duration_unit_nanos(unit : String) -> Int64? {
  match unit {
    "ns" => Some(1L)
    "us" | "\u{B5}s" | "\u{3BC}s" => Some(1_000L)
    "ms" => Some(1_000_000L)
    "s" => Some(1_000_000_000L)
    "m" => Some(60_000_000_000L)
    "h" => Some(3_600_000_000_000L)
    _ => None
  }
}

///|
/// A single `<number><unit>` component as a `TimeDelta`. `fraction` is the
/// number's fractional digits scaled to nine decimal places; precision
/// finer than a nanosecond is truncated toward zero.
fn duration_component(
  whole : Int64,
  fraction : Int64,
  unit_nanos : Int64,
) -> @core.TimeDelta raise FormatError {
  let one_second = 1_000_000_000L
  if unit_nanos >= one_second {
    let secs_per_unit = unit_nanos / one_second
    let secs = duration_require(mul_nonneg(whole, secs_per_unit))
    let whole_part = duration_require(@core.TimeDelta::seconds(secs))
    let fraction_part = duration_require(
      @core.TimeDelta::nanoseconds(fraction * secs_per_unit),
    )
    duration_require(whole_part.checked_add(fraction_part))
  } else {
    let nanos = duration_require(
      add_nonneg(
        duration_require(mul_nonneg(whole, unit_nanos)),
        fraction * unit_nanos / one_second,
      ),
    )
    duration_require(@core.TimeDelta::nanoseconds(nanos))
  }
}

///|
/// Parses a duration written as one or more `<number><unit>` components
/// with an optional leading sign, such as `"1h30m"`, `"-1.5s"` or
/// `"300ms"`. The units are `ns`, `us` (also `µs`/`μs`), `ms`, `s`, `m` and
/// `h`, case-sensitive, and components are summed. A number may have a
/// fractional part (`".5s"`, `"1.5h"`); digits beyond the ninth after the
/// decimal point, and precision finer than a nanosecond, are truncated
/// toward zero. A bare `"0"` (optionally signed) is allowed without a unit.
/// This is the inverse of `TimeDelta`'s `Show` output.
///
/// Raises `InvalidDuration` for malformed input or a value outside
/// `TimeDelta`'s representable range.
pub fn parse_duration(input : String) -> @core.TimeDelta raise FormatError {
  let chars = input.to_array()
  let len = chars.length()
  let mut pos = 0
  let mut negative = false
  if pos < len && (chars[pos] == '-' || chars[pos] == '+') {
    negative = chars[pos] == '-'
    pos += 1
  }
  if pos >= len {
    raise InvalidDuration
  }
  if len - pos == 1 && chars[pos] == '0' {
    return @core.TimeDelta::zero()
  }
  let mut total = @core.TimeDelta::zero()
  while pos < len {
    let mut whole = 0L
    let mut has_digits = false
    while pos < len && is_ascii_digit(chars[pos]) {
      let digit = (chars[pos].to_int() - '0'.to_int()).to_int64()
      whole = duration_require(
        add_nonneg(duration_require(mul_nonneg(whole, 10L)), digit),
      )
      has_digits = true
      pos += 1
    }
    let mut fraction = 0L
    if pos < len && chars[pos] == '.' {
      pos += 1
      let mut kept = 0
      while pos < len && is_ascii_digit(chars[pos]) {
        if kept < 9 {
          fraction = fraction * 10L +
            (chars[pos].to_int() - '0'.to_int()).to_int64()
          kept += 1
        }
        has_digits = true
        pos += 1
      }
      while kept < 9 {
        fraction = fraction * 10L
        kept += 1
      }
    }
    if !has_digits {
      raise InvalidDuration
    }
    let unit = StringBuilder()
    while pos < len && chars[pos] != '.' && !is_ascii_digit(chars[pos]) {
      unit.write_char(chars[pos])
      pos += 1
    }
    let unit_nanos = duration_require(duration_unit_nanos(unit.to_string()))
    total = duration_require(
      total.checked_add(duration_component(whole, fraction, unit_nanos)),
    )
  }
  if negative {
    total.neg()
  } else {
    total
  }
}
