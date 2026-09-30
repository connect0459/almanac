///|
/// Parses a whole UTC offset string into a `FixedOffset`: `±HH:MM:SS`,
/// `±HH:MM`, `±HHMM`, `±HH`, or `Z`/`z` for zero. Every form `Show` for
/// `FixedOffset` renders is accepted, so the two round-trip.
///
/// Raises `InputMismatch` if `input` is not exactly one of those forms
/// (including a minutes or seconds field above 59), and
/// `InconsistentFields` if it is well-shaped but beyond `FixedOffset`'s
/// `±23:59:59` range.
pub fn parse_fixed_offset(input : String) -> @tz.FixedOffset raise ParseError {
  let chars = input.to_array()
  let parsers = [
    parse_offset_double_colon, parse_offset_colon, parse_offset_no_colon, parse_offset_triple_colon,
  ]
  let secs = if chars.length() == 1 && (chars[0] == 'Z' || chars[0] == 'z') {
    0
  } else {
    let matched = for i = 0 {
      if i >= parsers.length() {
        break None
      }
      match parsers[i](chars, 0) {
        Some((value, end)) if end == chars.length() => break Some(value)
        _ => continue i + 1
      }
    }
    match matched {
      Some(value) => value
      None => raise InputMismatch
    }
  }
  match @tz.FixedOffset::east(secs) {
    Some(offset) => offset
    None => raise InconsistentFields
  }
}
