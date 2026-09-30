///|
/// Renders `dt` as RFC 2822 (`"Tue, 1 Jul 2003 10:52:37 +0200"`,
/// `%a, %d %b %Y %H:%M:%S %z` with the day unpadded — one or two digits,
/// never a leading zero), shifted to local wall-clock time, bypassing
/// the general token engine.
///
/// Unlike `to_rfc3339` (total), raises `InvalidRfc2822` if the year is
/// outside RFC 2822's own `0..=9999` range.
pub fn[Tz : @tz.TimeZone] to_rfc2822(
  dt : @tz.DateTime[Tz],
) -> String raise ParseError {
  let wall_clock = dt.naive_local()
  let date = wall_clock.date()
  let time = wall_clock.time()
  let year = date.year()
  if year < 0 || year > 9999 {
    raise InvalidRfc2822
  }
  let seconds = time.second() + time.nanosecond() / 1_000_000_000
  weekday_short_name(date.weekday()) +
  ", " +
  date.day().to_string() +
  " " +
  month_short_name(date.month()) +
  " " +
  pad_int(year, 4) +
  " " +
  pad_int(time.hour(), 2) +
  ":" +
  pad_int(time.minute(), 2) +
  ":" +
  pad_int(seconds, 2) +
  " " +
  format_offset_no_colon(dt.offset().local_minus_utc())
}

///|
/// Parses a 1- or 2-digit unsigned decimal run (RFC 2822's day field,
/// which — unlike this project's other fixed-width numeric fields — has
/// no leading zero when rendered, though a leading zero is still
/// accepted on parse).
fn parse_one_or_two_digits(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() || !is_ascii_digit(chars[pos]) {
    None
  } else if pos + 1 < chars.length() && is_ascii_digit(chars[pos + 1]) {
    Some((digit_value(chars[pos]) * 10 + digit_value(chars[pos + 1]), pos + 2))
  } else {
    Some((digit_value(chars[pos]), pos + 1))
  }
}

///|
/// Unwraps a positional parser's result, raising `InvalidRfc2822` on
/// `None` — keeps `parse_from_rfc2822` a flat sequence of steps instead
/// of a deeply nested `match` chain.
fn[T] rfc2822_require(opt : T?) -> T raise ParseError {
  match opt {
    None => raise InvalidRfc2822
    Some(v) => v
  }
}

///|
/// Parses an RFC 2822 date-and-time string (`"Tue, 1 Jul 2003 10:52:37
/// +0200"`), bypassing the general token engine.
///
/// Strict: this project supports only the exact shape `to_rfc2822` renders (day-of-week and
/// seconds mandatory, single-space separators, a 4-digit year, a numeric
/// `±HHMM` offset), not RFC 2822's "obsolete format" (optional
/// day-of-week, arbitrary whitespace, 2-/3-digit year windowing, named
/// legacy zones such as `GMT`/`EST`, or parenthesized comments) — mirrors
/// this project's existing RFC 3339 fast path, which is likewise strict
/// rather than maximally lenient.
pub fn parse_from_rfc2822(
  s : String,
) -> @tz.DateTime[@tz.FixedOffset] raise ParseError {
  let chars = s.to_array()
  let (_, p1) = rfc2822_require(match_weekday_name(chars, 0))
  let p2 = rfc2822_require(expect_char(chars, p1, ','))
  let p3 = rfc2822_require(expect_char(chars, p2, ' '))
  let (day, p4) = rfc2822_require(parse_one_or_two_digits(chars, p3))
  let p5 = rfc2822_require(expect_char(chars, p4, ' '))
  let (month, p6) = rfc2822_require(match_month_name(chars, p5))
  let p7 = rfc2822_require(expect_char(chars, p6, ' '))
  let (year, p8) = rfc2822_require(parse_fixed_digits(chars, p7, 4))
  let p9 = rfc2822_require(expect_char(chars, p8, ' '))
  let (hour, p10) = rfc2822_require(parse_fixed_digits(chars, p9, 2))
  let p11 = rfc2822_require(expect_char(chars, p10, ':'))
  let (minute, p12) = rfc2822_require(parse_fixed_digits(chars, p11, 2))
  let p13 = rfc2822_require(expect_char(chars, p12, ':'))
  let (second, p14) = rfc2822_require(parse_fixed_digits(chars, p13, 2))
  let p15 = rfc2822_require(expect_char(chars, p14, ' '))
  let (offset_secs, p16) = rfc2822_require(parse_offset_no_colon(chars, p15))
  if p16 != chars.length() {
    raise InvalidRfc2822
  }
  let date = rfc2822_require(
    @core.NaiveDate::from_ymd(year, month.number_from_month(), day),
  )
  let time = rfc2822_require(@core.NaiveTime::from_hms(hour, minute, second))
  let offset = rfc2822_require(@tz.FixedOffset::east(offset_secs))
  let local_naive = @core.NaiveDateTime::new(date, time)
  @tz.DateTime::from_utc(local_naive.sub_seconds(offset_secs), offset)
}
