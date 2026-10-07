///|
fn iso_duration_scan_number(
  chars : Array[Char],
  start : Int,
) -> (Int64, Int64, Bool, Int) raise FormatError {
  let len = chars.length()
  let mut pos = start
  let mut whole = 0L
  let mut has_whole = false
  while pos < len && is_ascii_digit(chars[pos]) {
    let digit = (chars[pos].to_int() - '0'.to_int()).to_int64()
    whole = duration_require(
      add_nonneg(duration_require(mul_nonneg(whole, 10L)), digit),
    )
    has_whole = true
    pos += 1
  }
  if !has_whole {
    raise InvalidDuration
  }
  let mut fraction = 0L
  let mut has_fraction = false
  if pos < len && (chars[pos] == '.' || chars[pos] == ',') {
    pos += 1
    let mut kept = 0
    while pos < len && is_ascii_digit(chars[pos]) {
      if kept < 9 {
        fraction = fraction * 10L +
          (chars[pos].to_int() - '0'.to_int()).to_int64()
        kept += 1
      }
      has_fraction = true
      pos += 1
    }
    if !has_fraction {
      raise InvalidDuration
    }
    while kept < 9 {
      fraction = fraction * 10L
      kept += 1
    }
  }
  (whole, fraction, has_fraction, pos)
}

///|
/// Renders `td` as an ISO 8601 duration made of a single seconds component:
/// `"PT<seconds>S"` with the fractional second written without trailing
/// zeros, e.g. `"PT1.5S"` or `"PT3600S"`. Zero is written `"P0D"`, and a
/// negative duration carries a leading `-` (`"-PT1.5S"`). No hour, minute or
/// day designator is written, because ISO 8601's longer units are not fixed
/// lengths. `parse_iso8601_duration` reads the result back unchanged.
pub fn to_iso8601_duration(td : @core.TimeDelta) -> String {
  if td.is_zero() {
    return "P0D"
  }
  let magnitude = td.abs()
  let sign = if td < @core.TimeDelta::zero() { "-" } else { "" }
  let digits = pad_int(magnitude.subsec_nanoseconds(), 9)
  let mut keep = digits.length()
  while keep > 0 && digits[keep - 1] == '0' {
    keep -= 1
  }
  let fraction = digits[:keep].to_owned()
  let seconds = magnitude.num_seconds().to_string()
  if keep == 0 {
    sign + "PT" + seconds + "S"
  } else {
    sign + "PT" + seconds + "." + fraction + "S"
  }
}

///|
/// Parses an ISO 8601 duration of the shape
/// `[+|-]P[<n>D][T[<n>H][<n>M][<n>S]]`, such as `"PT1H30M"`, `"P1DT2H"`,
/// `"-PT1.5S"` or `"P0D"`. The designators are upper-case, appear in that
/// order at most once each, and at least one component is required; a `T`
/// must be followed by a component. A day is exactly 24 hours. The last
/// component may carry a fraction (`.` or `,` as the decimal mark) except a
/// day. Digits beyond the ninth after the decimal mark are dropped before the
/// unit is applied, so a fractional hour or minute is exact only to the ninth
/// decimal of that unit (up to 3.6 microseconds for an hour, 60 nanoseconds
/// for a minute); a fractional second is exact to the nanosecond. A leading
/// sign applies to the whole duration.
///
/// Year, month and week designators are rejected, as their length depends on
/// the calendar and a `TimeDelta` is a fixed length of time.
///
/// Raises `InvalidDuration` for anything else, or for a value outside
/// `TimeDelta`'s representable range.
pub fn parse_iso8601_duration(
  input : String,
) -> @core.TimeDelta raise FormatError {
  let chars = input.to_array()
  let len = chars.length()
  let mut pos = 0
  let mut negative = false
  if pos < len && (chars[pos] == '-' || chars[pos] == '+') {
    negative = chars[pos] == '-'
    pos += 1
  }
  if pos >= len || chars[pos] != 'P' {
    raise InvalidDuration
  }
  pos += 1
  let mut in_time = false
  let mut last_rank = -1
  let mut components = 0
  let mut total = @core.TimeDelta::zero()
  while pos < len {
    if chars[pos] == 'T' {
      if in_time || pos + 1 >= len {
        raise InvalidDuration
      }
      in_time = true
      pos += 1
      continue
    }
    let (whole, fraction, has_fraction, after) = iso_duration_scan_number(
      chars, pos,
    )
    if after >= len {
      raise InvalidDuration
    }
    let (rank, unit_nanos) = match (in_time, chars[after]) {
      (false, 'D') => (0, 86_400_000_000_000L)
      (true, 'H') => (1, 3_600_000_000_000L)
      (true, 'M') => (2, 60_000_000_000L)
      (true, 'S') => (3, 1_000_000_000L)
      _ => raise InvalidDuration
    }
    pos = after + 1
    if rank <= last_rank || (has_fraction && (rank == 0 || pos < len)) {
      raise InvalidDuration
    }
    last_rank = rank
    components += 1
    total = duration_require(
      total.checked_add(duration_component(whole, fraction, unit_nanos)),
    )
  }
  if components == 0 {
    raise InvalidDuration
  }
  if negative {
    total.neg()
  } else {
    total
  }
}
