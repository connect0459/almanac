///|
fn is_ascii_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn pow10(n : Int) -> Int {
  for i = 0, acc = 1 {
    if i >= n {
      break acc
    }
    continue i + 1, acc * 10
  }
}

///|
fn digit_value(c : Char) -> Int {
  c.to_int() - '0'.to_int()
}

///|
/// A fixed-width, unsigned digit run. `None` if fewer than `width` ASCII
/// digits remain from `pos`.
fn parse_fixed_digits(
  chars : Array[Char],
  pos : Int,
  width : Int,
) -> (Int, Int)? {
  for i = pos, acc = 0 {
    if i >= pos + width {
      break Some((acc, i))
    }
    if i >= chars.length() || !is_ascii_digit(chars[i]) {
      break None
    }
    continue i + 1, acc * 10 + digit_value(chars[i])
  }
}

///|
fn expect_char(chars : Array[Char], pos : Int, c : Char) -> Int? {
  if pos < chars.length() && chars[pos] == c {
    Some(pos + 1)
  } else {
    None
  }
}

///|
fn expect_char_ci(
  chars : Array[Char],
  pos : Int,
  upper : Char,
  lower : Char,
) -> Int? {
  if pos < chars.length() && (chars[pos] == upper || chars[pos] == lower) {
    Some(pos + 1)
  } else {
    None
  }
}

///|
fn parse_rfc3339_date(
  chars : Array[Char],
  pos : Int,
) -> (@core.NaiveDate, Int)? {
  match parse_fixed_digits(chars, pos, 4) {
    None => None
    Some((year, p1)) =>
      match expect_char(chars, p1, '-') {
        None => None
        Some(p2) =>
          match parse_fixed_digits(chars, p2, 2) {
            None => None
            Some((month, p3)) =>
              match expect_char(chars, p3, '-') {
                None => None
                Some(p4) =>
                  match parse_fixed_digits(chars, p4, 2) {
                    None => None
                    Some((day, p5)) =>
                      match @core.NaiveDate::from_ymd(year, month, day) {
                        None => None
                        Some(date) => Some((date, p5))
                      }
                  }
              }
          }
      }
  }
}

///|
/// Parses `HH:MM:SS` (`SS` up to `60`, for a leap second — the caller
/// maps that to `NaiveTime`'s `second() == 59, nanosecond() >=
/// 1_000_000_000` convention once it knows the fractional-second
/// component).
fn parse_rfc3339_time_of_day(
  chars : Array[Char],
  pos : Int,
) -> (Int, Int, Int, Int)? {
  match parse_fixed_digits(chars, pos, 2) {
    None => None
    Some((hour, p1)) =>
      match expect_char(chars, p1, ':') {
        None => None
        Some(p2) =>
          match parse_fixed_digits(chars, p2, 2) {
            None => None
            Some((minute, p3)) =>
              match expect_char(chars, p3, ':') {
                None => None
                Some(p4) =>
                  match parse_fixed_digits(chars, p4, 2) {
                    None => None
                    Some((second, p5)) =>
                      if second <= 60 {
                        Some((hour, minute, second, p5))
                      } else {
                        None
                      }
                  }
              }
          }
      }
  }
}

///|
/// Parses an optional `.` followed by one or more digits, truncated to
/// nanosecond (9-digit) precision. `Some((0, pos))` (no advance) if `pos`
/// isn't a `.`; `None` if a `.` is present but no digit follows it.
fn parse_rfc3339_fraction(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() || chars[pos] != '.' {
    Some((0, pos))
  } else {
    for i = pos + 1, acc = 0, count = 0 {
      if i < chars.length() && is_ascii_digit(chars[i]) && count < 9 {
        continue i + 1, acc * 10 + digit_value(chars[i]), count + 1
      } else if i < chars.length() && is_ascii_digit(chars[i]) {
        continue i + 1, acc, count
      } else if count == 0 {
        break None
      } else {
        break Some((acc * pow10(9 - count), i))
      }
    }
  }
}

///|
/// Parses `Z`/`z` (offset zero) or a signed `HH:MM` offset.
fn parse_rfc3339_offset(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] == 'Z' || chars[pos] == 'z' {
    Some((0, pos + 1))
  } else if chars[pos] == '+' || chars[pos] == '-' {
    let sign = if chars[pos] == '-' { -1 } else { 1 }
    match parse_fixed_digits(chars, pos + 1, 2) {
      None => None
      Some((hour, p1)) =>
        match expect_char(chars, p1, ':') {
          None => None
          Some(p2) =>
            match parse_fixed_digits(chars, p2, 2) {
              None => None
              Some((minute, p3)) =>
                if minute > 59 {
                  None
                } else {
                  Some((sign * (hour * 3600 + minute * 60), p3))
                }
            }
        }
    }
  } else {
    None
  }
}

///|
fn try_parse_rfc3339(s : String) -> @tz.DateTime[@tz.FixedOffset]? {
  let chars = s.to_array()
  match parse_rfc3339_date(chars, 0) {
    None => None
    Some((date, p1)) =>
      match expect_char_ci(chars, p1, 'T', 't') {
        None => None
        Some(p2) =>
          match parse_rfc3339_time_of_day(chars, p2) {
            None => None
            Some((hour, minute, second, p3)) =>
              match parse_rfc3339_fraction(chars, p3) {
                None => None
                Some((frac_nanos, p4)) =>
                  match parse_rfc3339_offset(chars, p4) {
                    None => None
                    Some((offset_secs, p5)) =>
                      if p5 != chars.length() {
                        None
                      } else {
                        let (clock_second, nano) = if second == 60 {
                          (59, frac_nanos + 1_000_000_000)
                        } else {
                          (second, frac_nanos)
                        }
                        match
                          @core.NaiveTime::from_hms_nano(
                            hour, minute, clock_second, nano,
                          ) {
                          None => None
                          Some(time) =>
                            match @tz.FixedOffset::east(offset_secs) {
                              None => None
                              Some(offset) => {
                                let local_naive = @core.NaiveDateTime::new(
                                  date, time,
                                )
                                let shift = @core.TimeDelta::seconds(
                                  offset_secs.to_int64(),
                                ).unwrap()
                                Some(
                                  @tz.DateTime::from_utc(
                                    local_naive.sub_signed(shift),
                                    offset,
                                  ),
                                )
                              }
                            }
                        }
                      }
                  }
              }
          }
      }
  }
}

///|
/// Parses an RFC 3339 date-time
/// (`YYYY-MM-DDTHH:MM:SS[.fraction](Z|±HH:MM)`), bypassing the general
/// token engine. Both `T`/`t` and `Z`/`z` are accepted (RFC 3339 permits
/// either case); a fractional-second field beyond 9 digits is truncated
/// to nanosecond precision; `SS == 60` (a leap second) maps to
/// `NaiveTime`'s `second() == 59, nanosecond() >= 1_000_000_000`
/// convention.
pub fn parse_rfc3339(
  s : String,
) -> @tz.DateTime[@tz.FixedOffset] raise ParseError {
  match try_parse_rfc3339(s) {
    Some(dt) => dt
    None => raise InvalidRfc3339
  }
}

///|
fn format_offset_colon(secs : Int) -> String {
  let sign = if secs < 0 { "-" } else { "+" }
  let magnitude = if secs < 0 { -secs } else { secs }
  let hours = magnitude / 3600
  let minutes = magnitude % 3600 / 60
  sign + pad_int(hours, 2) + ":" + pad_int(minutes, 2)
}

///|
/// Renders a nanosecond component (`0..=999_999_999`) as `.` followed by
/// its digits with trailing zeros trimmed, or `""` when it is zero.
fn format_fraction_trimmed(nanos : Int) -> String {
  if nanos == 0 {
    ""
  } else {
    // `nanos != 0` guarantees this always finds a nonzero digit at or
    // before `n == 1`, so `v` never reaches `0` here.
    let significant_digits = for n = 9, v = nanos {
      if v % 10 != 0 {
        break n
      }
      continue n - 1, v / 10
    }
    let digits = pad_int(nanos, 9).to_array()
    "." + String::from_array(digits[0:significant_digits])
  }
}

///|
/// Renders `dt` as RFC 3339
/// (`YYYY-MM-DDTHH:MM:SS[.fraction](Z|±HH:MM)`), bypassing the general
/// token engine. A zero offset renders as `Z`. A leap second renders as
/// `:60`, matching `NaiveTime`'s existing leap-second convention
/// (`second() + nanosecond() / 1_000_000_000`).
pub fn[Tz : @tz.TimeZone] to_rfc3339(dt : @tz.DateTime[Tz]) -> String {
  let wall_clock = dt.naive_local()
  let date = wall_clock.date()
  let time = wall_clock.time()
  let seconds = time.second() + time.nanosecond() / 1_000_000_000
  let fraction_nanos = time.nanosecond() % 1_000_000_000
  let offset_secs = dt.offset().local_minus_utc()
  let offset_str = if offset_secs == 0 {
    "Z"
  } else {
    format_offset_colon(offset_secs)
  }
  pad_int(date.year(), 4) +
  "-" +
  pad_int(date.month().number_from_month(), 2) +
  "-" +
  pad_int(date.day(), 2) +
  "T" +
  pad_int(time.hour(), 2) +
  ":" +
  pad_int(time.minute(), 2) +
  ":" +
  pad_int(seconds, 2) +
  format_fraction_trimmed(fraction_nanos) +
  offset_str
}
