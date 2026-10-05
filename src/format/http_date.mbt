///|
/// Renders the UTC instant of `dt` as an HTTP IMF-fixdate (RFC 9110
/// section 5.6.7), e.g. `"Sun, 06 Nov 1994 08:49:37 GMT"`: fixed width,
/// English names, a zero-padded day and always `GMT`. A fractional second
/// is dropped and a leap second is written as `:60`.
///
/// Raises `InvalidHttpDate` if the year is outside `0..=9999`.
pub fn[Tz] to_http_date(dt : @tz.DateTime[Tz]) -> String raise FormatError {
  let utc = dt.naive_utc()
  let date = utc.date()
  let time = utc.time()
  let year = date.year()
  if year < 0 || year > 9999 {
    raise InvalidHttpDate
  }
  let seconds = time.second() + time.nanosecond() / 1_000_000_000
  weekday_short_name(date.weekday()) +
  ", " +
  pad_int(date.day(), 2) +
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
  " GMT"
}

///|
fn[T] http_require(opt : T?) -> T raise FormatError {
  match opt {
    None => raise InvalidHttpDate
    Some(v) => v
  }
}

///|
fn match_weekday_form(
  chars : Array[Char],
  pos : Int,
  long_form : Bool,
) -> (@core.Weekday, Int)? {
  for entry in weekday_names() {
    let (wd, long_name, short_name) = entry
    match
      match_literal(chars, pos, if long_form { long_name } else { short_name }) {
      Some(p) => return Some((wd, p))
      None => ()
    }
  }
  None
}

///|
fn match_month_short(chars : Array[Char], pos : Int) -> (Int, Int)? {
  for entry in month_names() {
    let (m, _, short_name) = entry
    match match_literal(chars, pos, short_name) {
      Some(p) => return Some((m.number(), p))
      None => ()
    }
  }
  None
}

///|
fn parse_space_padded_day(chars : Array[Char], pos : Int) -> (Int, Int)? {
  match expect_char(chars, pos, ' ') {
    Some(p) =>
      if p < chars.length() && is_ascii_digit(chars[p]) {
        Some((digit_value(chars[p]), p + 1))
      } else {
        None
      }
    None => parse_fixed_digits(chars, pos, 2)
  }
}

///|
fn resolve_two_digit_year(yy : Int, reference_year : Int?) -> Int {
  match reference_year {
    None => yy + (if yy < 70 { 2000 } else { 1900 })
    Some(reference) => {
      let candidate = reference - (reference % 100 + 100) % 100 + yy
      if candidate - reference > 50 {
        candidate - 100
      } else {
        candidate
      }
    }
  }
}

///|
fn parse_clock(
  chars : Array[Char],
  pos : Int,
) -> (Int, Int, Int, Int) raise FormatError {
  let (hour, p1) = http_require(parse_fixed_digits(chars, pos, 2))
  let p2 = http_require(expect_char(chars, p1, ':'))
  let (minute, p3) = http_require(parse_fixed_digits(chars, p2, 2))
  let p4 = http_require(expect_char(chars, p3, ':'))
  let (second, p5) = http_require(parse_fixed_digits(chars, p4, 2))
  (hour, minute, second, p5)
}

///|
fn parse_http_gmt(chars : Array[Char], pos : Int) -> Int? {
  match match_literal(chars, pos, "GMT") {
    Some(p) => if p == chars.length() { Some(p) } else { None }
    None => None
  }
}

///|
fn parse_imf_fixdate(
  chars : Array[Char],
) -> (@core.Weekday, Int, Int, Int, Int, Int, Int) raise FormatError {
  let (wd, p1) = http_require(match_weekday_form(chars, 0, false))
  let p2 = http_require(expect_char(chars, p1, ','))
  let p3 = http_require(expect_char(chars, p2, ' '))
  let (day, p4) = http_require(parse_fixed_digits(chars, p3, 2))
  let p5 = http_require(expect_char(chars, p4, ' '))
  let (month, p6) = http_require(match_month_short(chars, p5))
  let p7 = http_require(expect_char(chars, p6, ' '))
  let (year, p8) = http_require(parse_fixed_digits(chars, p7, 4))
  let p9 = http_require(expect_char(chars, p8, ' '))
  let (hour, minute, second, p10) = parse_clock(chars, p9)
  let p11 = http_require(expect_char(chars, p10, ' '))
  http_require(parse_http_gmt(chars, p11)) |> ignore
  (wd, year, month, day, hour, minute, second)
}

///|
fn parse_rfc850(
  chars : Array[Char],
  reference_year : Int?,
) -> (@core.Weekday, Int, Int, Int, Int, Int, Int) raise FormatError {
  let (wd, p1) = http_require(match_weekday_form(chars, 0, true))
  let p2 = http_require(expect_char(chars, p1, ','))
  let p3 = http_require(expect_char(chars, p2, ' '))
  let (day, p4) = http_require(parse_fixed_digits(chars, p3, 2))
  let p5 = http_require(expect_char(chars, p4, '-'))
  let (month, p6) = http_require(match_month_short(chars, p5))
  let p7 = http_require(expect_char(chars, p6, '-'))
  let (yy, p8) = http_require(parse_fixed_digits(chars, p7, 2))
  let p9 = http_require(expect_char(chars, p8, ' '))
  let (hour, minute, second, p10) = parse_clock(chars, p9)
  let p11 = http_require(expect_char(chars, p10, ' '))
  let year = resolve_two_digit_year(yy, reference_year)
  http_require(parse_http_gmt(chars, p11)) |> ignore
  (wd, year, month, day, hour, minute, second)
}

///|
fn parse_asctime(
  chars : Array[Char],
) -> (@core.Weekday, Int, Int, Int, Int, Int, Int) raise FormatError {
  let (wd, p1) = http_require(match_weekday_form(chars, 0, false))
  let p2 = http_require(expect_char(chars, p1, ' '))
  let (month, p3) = http_require(match_month_short(chars, p2))
  let p4 = http_require(expect_char(chars, p3, ' '))
  let (day, p5) = http_require(parse_space_padded_day(chars, p4))
  let p6 = http_require(expect_char(chars, p5, ' '))
  let (hour, minute, second, p7) = parse_clock(chars, p6)
  let p8 = http_require(expect_char(chars, p7, ' '))
  let (year, p9) = http_require(parse_fixed_digits(chars, p8, 4))
  if p9 != chars.length() {
    raise InvalidHttpDate
  }
  (wd, year, month, day, hour, minute, second)
}

///|
/// Parses an HTTP date (RFC 9110 section 5.6.7) into a UTC instant.
///
/// Reads IMF-fixdate (`"Sun, 06 Nov 1994 08:49:37 GMT"`) and, as recipients
/// must, the two obsolete forms: RFC 850 (`"Sunday, 06-Nov-94 08:49:37 GMT"`)
/// and `asctime` (`"Sun Nov  6 08:49:37 1994"`, whose zone is GMT by
/// definition). Every form is exact: English names with their capitalisation,
/// fixed widths, single spaces, and `GMT` as the only zone. The weekday must
/// match the date. A leap second (`:60`) is not read back, as with
/// `parse_rfc2822`.
///
/// RFC 850's two-digit year is read by `reference_year` when given: a year more
/// than 50 years after it reads as the most recent past year with the same
/// last two digits (RFC 9110's rule). Without it the fixed pivot of `%y`
/// applies (`< 70` is 20xx, `>= 70` is 19xx), which ages: after 2070 it
/// disagrees with that rule, so a caller reading live traffic should pass
/// the current year.
///
/// Raises `InvalidHttpDate` for anything else.
pub fn parse_http_date(
  s : String,
  reference_year? : Int,
) -> @tz.DateTime[@tz.Utc] raise FormatError {
  let chars = s.to_array()
  let short_weekday_then = match match_weekday_form(chars, 0, false) {
    Some((_, p)) if p < chars.length() => Some(chars[p])
    _ => None
  }
  let (wd, year, month, day, hour, minute, second) = match short_weekday_then {
    Some(',') => parse_imf_fixdate(chars)
    Some(' ') => parse_asctime(chars)
    _ => parse_rfc850(chars, reference_year)
  }
  let date = http_require(@core.NaiveDate::from_ymd(year, month, day))
  if date.weekday() != wd {
    raise InvalidHttpDate
  }
  let time = http_require(@core.NaiveTime::from_hms(hour, minute, second))
  @tz.DateTime::from_utc(@core.NaiveDateTime::new(date, time), @tz.Utc::new())
}
