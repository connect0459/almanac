///|
fn ascii_lower(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
fn is_ascii_letter(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn match_name_ignoring_case(
  chars : Array[Char],
  pos : Int,
  name : String,
) -> Int? {
  let name_chars = name.to_array()
  let len = name_chars.length()
  if pos + len > chars.length() {
    None
  } else {
    for i = 0 {
      if i >= len {
        break Some(pos + len)
      }
      if ascii_lower(chars[pos + i]) != ascii_lower(name_chars[i]) {
        break None
      }
      continue i + 1
    }
  }
}

///|
fn skip_whitespace(chars : Array[Char], pos : Int) -> Int {
  for i = pos {
    if i >= chars.length() || !chars[i].is_whitespace() {
      break i
    }
    continue i + 1
  }
}

///|
fn require_whitespace(chars : Array[Char], pos : Int) -> Int? {
  let end = skip_whitespace(chars, pos)
  if end == pos {
    None
  } else {
    Some(end)
  }
}

///|
fn match_short_weekday_ignoring_case(
  chars : Array[Char],
  pos : Int,
) -> (@core.Weekday, Int)? {
  for entry in weekday_names() {
    let (wd, _, short_name) = entry
    match match_name_ignoring_case(chars, pos, short_name) {
      Some(p) => return Some((wd, p))
      None => ()
    }
  }
  None
}

///|
fn match_short_month_ignoring_case(
  chars : Array[Char],
  pos : Int,
) -> (@core.Month, Int)? {
  for entry in month_names() {
    let (m, _, short_name) = entry
    match match_name_ignoring_case(chars, pos, short_name) {
      Some(p) => return Some((m, p))
      None => ()
    }
  }
  None
}

///|
fn parse_windowed_year(chars : Array[Char], pos : Int) -> (Int, Int)? {
  let end = for i = pos {
    if i >= chars.length() || !is_ascii_digit(chars[i]) {
      break i
    }
    continue i + 1
  }
  let width = end - pos
  if width < 2 || width > 4 {
    return None
  }
  let (value, _) = parse_fixed_digits(chars, pos, width).unwrap()
  let year = if width == 2 {
    if value < 50 {
      value + 2000
    } else {
      value + 1900
    }
  } else if width == 3 {
    value + 1900
  } else {
    value
  }
  Some((year, end))
}

///|
fn legacy_zone_offset_seconds(lower_name : String) -> Int? {
  match lower_name {
    "gmt" | "ut" | "z" => Some(0)
    "edt" => Some(-4 * 3600)
    "est" | "cdt" => Some(-5 * 3600)
    "cst" | "mdt" => Some(-6 * 3600)
    "mst" | "pdt" => Some(-7 * 3600)
    "pst" => Some(-8 * 3600)
    lower => if lower.length() == 1 && lower != "j" { Some(0) } else { None }
  }
}

///|
fn parse_obsolete_zone(chars : Array[Char], pos : Int) -> (Int, Int)? {
  let end = for i = pos {
    if i >= chars.length() || !is_ascii_letter(chars[i]) {
      break i
    }
    continue i + 1
  }
  if end == pos {
    parse_offset_no_colon(chars, pos)
  } else {
    let name = StringBuilder()
    for i in pos..<end {
      name.write_char(ascii_lower(chars[i]))
    }
    legacy_zone_offset_seconds(name.to_string()).map(secs => (secs, end))
  }
}

///|
fn skip_comment(chars : Array[Char], pos : Int) -> Int? {
  let start = skip_whitespace(chars, pos)
  if start >= chars.length() || chars[start] != '(' {
    return None
  }
  for i = start + 1, depth = 1 {
    if i >= chars.length() {
      break None
    }
    match chars[i] {
      '\\' => continue i + 2, depth
      '(' => continue i + 1, depth + 1
      ')' =>
        if depth == 1 {
          break Some(i + 1)
        } else {
          continue i + 1, depth - 1
        }
      _ => continue i + 1, depth
    }
  }
}

///|
fn skip_comments(chars : Array[Char], pos : Int) -> Int {
  for p = pos {
    match skip_comment(chars, p) {
      Some(next) => continue next
      None => break p
    }
  }
}

///|
/// Parses an RFC 2822 date-and-time string including the "obsolete
/// syntax" that `parse_rfc2822` rejects, as a separate, opt-in reader.
/// Every date `to_rfc2822` renders reads back unchanged.
///
/// Accepted beyond the strict shape:
/// - the day of week may be omitted; when present it is written as a short
///   name directly followed by a comma and must match the date;
/// - the seconds may be omitted and read as `00`;
/// - any run of Unicode whitespace may stand for a single space, may
///   precede the first field, and may surround the `:` separators of the
///   time;
/// - month, weekday and zone names are matched ignoring ASCII case;
/// - a two-digit year below 50 reads as 20xx, from 50 as 19xx, and a
///   three-digit year as 1900 plus the year; a four-digit year is taken as
///   written, and one digit or more than four digits is rejected;
/// - the zone may be `GMT`, `UT`, `EST`, `EDT`, `CST`, `CDT`, `MST`, `MDT`,
///   `PST` or `PDT`, or a single letter other than `J`, which reads as
///   `+0000` as RFC 2822 recommends for military zones;
/// - any number of nested, backslash-escapable parenthesized comments may
///   follow the zone, separated by whitespace.
///
/// Whitespace after the last field or comment is not accepted, and neither
/// is a leap second (`:60`), as with `parse_rfc2822`.
///
/// A superset of `parse_rfc2822`: every string `parse_rfc2822` reads is read
/// the same way here. Raises `InvalidRfc2822` on any mismatch.
pub fn parse_rfc2822_lenient(
  s : String,
) -> @tz.DateTime[@tz.FixedOffset] raise FormatError {
  let chars = s.to_array()
  let p0 = skip_whitespace(chars, 0)
  let (weekday, p1) = match match_short_weekday_ignoring_case(chars, p0) {
    Some((wd, after_name)) =>
      (Some(wd), rfc2822_require(expect_char(chars, after_name, ',')))
    None => (None, p0)
  }
  let p2 = skip_whitespace(chars, p1)
  let (day, p3) = rfc2822_require(parse_one_or_two_digits(chars, p2))
  let p4 = rfc2822_require(require_whitespace(chars, p3))
  let (month, p5) = rfc2822_require(match_short_month_ignoring_case(chars, p4))
  let p6 = rfc2822_require(require_whitespace(chars, p5))
  let (year, p7) = rfc2822_require(parse_windowed_year(chars, p6))
  let p8 = rfc2822_require(require_whitespace(chars, p7))
  let (hour, p9) = rfc2822_require(parse_fixed_digits(chars, p8, 2))
  let p10 = skip_whitespace(
    chars,
    rfc2822_require(expect_char(chars, skip_whitespace(chars, p9), ':')),
  )
  let (minute, p11) = rfc2822_require(parse_fixed_digits(chars, p10, 2))
  let (second, p12) = match
    expect_char(chars, skip_whitespace(chars, p11), ':') {
    Some(after_colon) =>
      rfc2822_require(
        parse_fixed_digits(chars, skip_whitespace(chars, after_colon), 2),
      )
    None => (0, p11)
  }
  let p13 = rfc2822_require(require_whitespace(chars, p12))
  let (offset_secs, p14) = rfc2822_require(parse_obsolete_zone(chars, p13))
  if skip_comments(chars, p14) != chars.length() {
    raise InvalidRfc2822
  }
  let date = rfc2822_require(
    @core.NaiveDate::from_ymd(year, month.number(), day),
  )
  match weekday {
    Some(wd) if wd != date.weekday() => raise InvalidRfc2822
    _ => ()
  }
  let time = rfc2822_require(@core.NaiveTime::from_hms(hour, minute, second))
  let offset = rfc2822_require(@tz.FixedOffset::east(offset_secs))
  @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(date, time).sub_seconds(offset_secs.to_int64()),
    offset,
  )
}
