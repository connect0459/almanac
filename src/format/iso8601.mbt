///|
/// The shapes `parse_iso8601` distinguishes: which of a date, a time of day
/// and an offset the text carried.
pub(all) enum Iso8601 {
  /// A date and a time of day with an offset: an instant.
  Zoned(@tz.DateTime[@tz.FixedOffset])
  /// A date and a time of day with no offset: a wall clock.
  Local(@core.NaiveDateTime)
  /// A date alone.
  DateOnly(@core.NaiveDate)
  /// A time of day alone.
  TimeOnly(@core.NaiveTime)
} derive(Eq, @debug.Debug)

///|
pub extend Iso8601 with Eq::{equal}

///|
pub extend Iso8601 with Eq::{not_equal}

///|
pub extend Iso8601 with @debug.Debug::{to_repr}

///|
fn parse_iso8601_time_of_day(
  chars : Array[Char],
  pos : Int,
) -> (@core.NaiveTime, Int)? {
  guard parse_fixed_digits(chars, pos, 2) is Some((hour, p1)) else { None }
  guard expect_char(chars, p1, ':') is Some(p2) else { None }
  guard parse_fixed_digits(chars, p2, 2) is Some((minute, p3)) else { None }
  let (second, frac_nanos, end) = match expect_char(chars, p3, ':') {
    None => (0, 0, p3)
    Some(p4) => {
      guard parse_fixed_digits(chars, p4, 2) is Some((second, p5)) else {
        return None
      }
      guard second <= 60 else { return None }
      guard parse_rfc3339_fraction(chars, p5) is Some((frac_nanos, p6)) else {
        return None
      }
      (second, frac_nanos, p6)
    }
  }
  let (clock_second, nano) = if second == 60 {
    (59, frac_nanos + 1_000_000_000)
  } else {
    (second, frac_nanos)
  }
  match @core.NaiveTime::from_hms_nano(hour, minute, clock_second, nano) {
    Some(time) => Some((time, end))
    None => None
  }
}

///|
fn try_parse_iso8601(s : String) -> Iso8601? {
  let chars = s.to_array()
  let len = chars.length()
  if len >= 3 && chars[2] == ':' {
    guard parse_iso8601_time_of_day(chars, 0) is Some((time, end)) else {
      return None
    }
    return if end == len { Some(TimeOnly(time)) } else { None }
  }
  guard parse_rfc3339_date(chars, 0) is Some((date, p1)) else { return None }
  if p1 == len {
    return Some(DateOnly(date))
  }
  let separated = chars[p1] == 'T' || chars[p1] == 't' || chars[p1] == ' '
  guard separated else { return None }
  guard parse_iso8601_time_of_day(chars, p1 + 1) is Some((time, p2)) else {
    return None
  }
  let wall_clock = @core.NaiveDateTime::new(date, time)
  if p2 == len {
    return Some(Local(wall_clock))
  }
  guard parse_rfc3339_offset(chars, p2) is Some((offset_secs, p3)) else {
    return None
  }
  guard p3 == len else { return None }
  guard @tz.FixedOffset::east(offset_secs) is Some(offset) else { return None }
  Some(
    Zoned(
      @tz.DateTime::from_utc(
        wall_clock.sub_seconds(offset_secs.to_int64()),
        offset,
      ),
    ),
  )
}

///|
/// Parses an ISO 8601 date and/or time more leniently than `parse_rfc3339`:
/// the date and time are joined by `T`, `t` or one space, the seconds may be
/// left off (`09:30`), and the offset (`Z`/`z` or `±HH:MM`) may be absent.
/// The result says which parts were present: a date-time with an offset is
/// `Zoned`, without one `Local`, and a bare date or time of day is
/// `DateOnly` or `TimeOnly`. An offset on a bare date or time is rejected.
/// Fractional seconds follow `parse_rfc3339` (any number of digits,
/// truncated to nanoseconds, only after the seconds field), as does second
/// `60` for a leap second. Raises `InvalidIso8601` on any other input.
pub fn parse_iso8601(s : String) -> Iso8601 raise FormatError {
  match try_parse_iso8601(s) {
    Some(parsed) => parsed
    None => raise InvalidIso8601
  }
}
