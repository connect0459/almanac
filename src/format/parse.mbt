///|
/// An accumulator for fields discovered while walking a token sequence
/// against input text. Every field is optional until its specifier is
/// actually seen; `resolve_date`/`resolve_time`/`resolve_offset` decide
/// afterward whether enough fields were populated, and whether they
/// agree with each other.
priv struct Parsed {
  year : Int?
  month : Int?
  day : Int?
  ordinal : Int?
  hour : Int?
  minute : Int?
  second : Int?
  nanosecond : Int?
  weekday : @core.Weekday?
  offset_secs : Int?
}

///|
fn Parsed::empty() -> Parsed {
  Parsed::{
    year: None,
    month: None,
    day: None,
    ordinal: None,
    hour: None,
    minute: None,
    second: None,
    nanosecond: None,
    weekday: None,
    offset_secs: None,
  }
}

///|
/// Records `value` for a field that hasn't been seen yet, or confirms it
/// against an already-recorded value for one seen again (e.g. the same
/// specifier twice, or two specifiers that both determine it, like `%j`
/// alongside `%m`/`%d`). Raises `InconsistentFields` on disagreement.
fn[T : Eq] merge_field(existing : T?, value : T) -> T? raise ParseError {
  match existing {
    None => Some(value)
    Some(v) => if v == value { Some(v) } else { raise InconsistentFields }
  }
}

///|
/// Matches `literal` verbatim at `pos`, or `None` if it doesn't fit or
/// doesn't match.
fn match_literal(chars : Array[Char], pos : Int, literal : String) -> Int? {
  let lit_chars = literal.to_array()
  let len = lit_chars.length()
  if pos + len > chars.length() {
    None
  } else {
    for i = 0 {
      if i >= len {
        break Some(pos + len)
      }
      if chars[pos + i] != lit_chars[i] {
        break None
      }
      continue i + 1
    }
  }
}

///|
/// Parses `%Y`'s variable-width, optionally-signed decimal field: an
/// optional `-`, then one or more digits, greedily. Unlike every other
/// numeric specifier, `%Y`'s render width isn't fixed (a year can exceed
/// 4 digits), so it isn't parsed via `parse_fixed_digits`.
fn parse_signed_greedy_digits(chars : Array[Char], pos : Int) -> (Int, Int)? {
  let (sign, p0) = if pos < chars.length() && chars[pos] == '-' {
    (-1, pos + 1)
  } else {
    (1, pos)
  }
  for i = p0, acc = 0, count = 0 {
    if i < chars.length() && is_ascii_digit(chars[i]) {
      continue i + 1, acc * 10 + digit_value(chars[i]), count + 1
    } else if count == 0 {
      break None
    } else {
      break Some((sign * acc, i))
    }
  }
}

///|
/// Parses `%z`'s numeric offset (`±HHMM`, no colon — the strftime form,
/// distinct from RFC 3339's colon-separated one).
fn parse_offset_no_colon(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] != '+' && chars[pos] != '-' {
    None
  } else {
    let sign = if chars[pos] == '-' { -1 } else { 1 }
    match parse_fixed_digits(chars, pos + 1, 2) {
      None => None
      Some((hour, p1)) =>
        match parse_fixed_digits(chars, p1, 2) {
          None => None
          Some((minute, p2)) =>
            if minute > 59 {
              None
            } else {
              Some((sign * (hour * 3600 + minute * 60), p2))
            }
        }
    }
  }
}

///|
fn weekday_names() -> Array[(@core.Weekday, String, String)] {
  [
    (@core.Mon, "Monday", "Mon"),
    (@core.Tue, "Tuesday", "Tue"),
    (@core.Wed, "Wednesday", "Wed"),
    (@core.Thu, "Thursday", "Thu"),
    (@core.Fri, "Friday", "Fri"),
    (@core.Sat, "Saturday", "Sat"),
    (@core.Sun, "Sunday", "Sun"),
  ]
}

///|
/// Matches either the long (`%A`) or short (`%a`) name of any weekday at
/// `pos` (whichever fits — the caller doesn't need to know which
/// specifier requested it, since both resolve to the same `Weekday`).
fn match_weekday_name(chars : Array[Char], pos : Int) -> (@core.Weekday, Int)? {
  let names = weekday_names()
  for i = 0 {
    if i >= names.length() {
      break None
    }
    let (wd, long_name, short_name) = names[i]
    match match_literal(chars, pos, long_name) {
      Some(p) => break Some((wd, p))
      None =>
        match match_literal(chars, pos, short_name) {
          Some(p) => break Some((wd, p))
          None => continue i + 1
        }
    }
  }
}

///|
fn apply_weekday_specifier(
  chars : Array[Char],
  pos : Int,
  parsed : Parsed,
) -> (Parsed, Int) raise ParseError {
  match match_weekday_name(chars, pos) {
    None => raise InputMismatch
    Some((wd, p)) =>
      ({ ..parsed, weekday: merge_field(parsed.weekday, wd), }, p)
  }
}

///|
/// Applies a single token against `input` at `pos`, returning the
/// updated accumulator and the new position. `%Z` always raises
/// `InputMismatch`: a zone name (an IANA abbreviation, `"UTC"`, or a bare
/// offset's own string) has no generically parseable shape, matching
/// chrono's own documented behavior for the same specifier.
fn apply_item(
  item : Item,
  parsed : Parsed,
  chars : Array[Char],
  pos : Int,
) -> (Parsed, Int) raise ParseError {
  match item {
    Literal(s) =>
      match match_literal(chars, pos, s) {
        None => raise InputMismatch
        Some(p) => (parsed, p)
      }
    Numeric(Year) =>
      match parse_signed_greedy_digits(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, year: merge_field(parsed.year, value), }, p)
      }
    Numeric(Month) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, month: merge_field(parsed.month, value), }, p)
      }
    Numeric(Day) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, day: merge_field(parsed.day, value), }, p)
      }
    Numeric(Ordinal) =>
      match parse_fixed_digits(chars, pos, 3) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, ordinal: merge_field(parsed.ordinal, value), }, p)
      }
    Numeric(Hour) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, hour: merge_field(parsed.hour, value), }, p)
      }
    Numeric(Minute) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, minute: merge_field(parsed.minute, value), }, p)
      }
    Numeric(Second) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, second: merge_field(parsed.second, value), }, p)
      }
    Numeric(Nanosecond) =>
      match parse_fixed_digits(chars, pos, 9) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, nanosecond: merge_field(parsed.nanosecond, value), }, p)
      }
    Fixed(LongWeekdayName) => apply_weekday_specifier(chars, pos, parsed)
    Fixed(ShortWeekdayName) => apply_weekday_specifier(chars, pos, parsed)
    Fixed(TimezoneName) => raise InputMismatch
    Fixed(TimezoneOffset) =>
      match parse_offset_no_colon(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
  }
}

///|
/// Walks `items` against `input`, raising `InputMismatch` if any literal
/// or specifier fails to match, or if input remains once every item has
/// been consumed.
fn parse_items(items : Array[Item], input : String) -> Parsed raise ParseError {
  let chars = input.to_array()
  let (parsed, pos) = for i = 0, parsed = Parsed::empty(), pos = 0 {
    if i >= items.length() {
      break (parsed, pos)
    }
    let (next_parsed, next_pos) = apply_item(items[i], parsed, chars, pos)
    continue i + 1, next_parsed, next_pos
  }
  if pos != chars.length() {
    raise InputMismatch
  }
  parsed
}

///|
/// Resolves `parsed`'s date fields into a `NaiveDate`: `year` plus either
/// `month`+`day` or `ordinal`. Cross-checks a redundantly-present
/// ordinal, and a parsed weekday (`%A`/`%a`), against the constructed
/// date.
fn resolve_date(parsed : Parsed) -> @core.NaiveDate raise ParseError {
  let year = match parsed.year {
    None => raise IncompleteFields
    Some(y) => y
  }
  let date = match (parsed.month, parsed.day) {
    (Some(month), Some(day)) =>
      match @core.NaiveDate::from_ymd(year, month, day) {
        None => raise InconsistentFields
        Some(d) => d
      }
    (None, None) =>
      match parsed.ordinal {
        None => raise IncompleteFields
        Some(ordinal) =>
          match @core.NaiveDate::from_yo(year, ordinal) {
            None => raise InconsistentFields
            Some(d) => d
          }
      }
    _ => raise IncompleteFields
  }
  match parsed.ordinal {
    None => ()
    Some(ordinal) => if date.ordinal() != ordinal { raise InconsistentFields }
  }
  match parsed.weekday {
    None => ()
    Some(wd) => if date.weekday() != wd { raise InconsistentFields }
  }
  date
}

///|
/// Resolves `parsed`'s time fields into a `NaiveTime`: `hour`, `minute`,
/// and `second` are required; `nanosecond` defaults to `0`. A `second`
/// of `60` (a leap second) maps to `NaiveTime`'s `second() == 59,
/// nanosecond() >= 1_000_000_000` convention.
fn resolve_time(parsed : Parsed) -> @core.NaiveTime raise ParseError {
  let hour = match parsed.hour {
    None => raise IncompleteFields
    Some(h) => h
  }
  let minute = match parsed.minute {
    None => raise IncompleteFields
    Some(m) => m
  }
  let second = match parsed.second {
    None => raise IncompleteFields
    Some(s) => s
  }
  let nanosecond = match parsed.nanosecond {
    None => 0
    Some(n) => n
  }
  let (clock_second, nano) = if second == 60 {
    (59, nanosecond + 1_000_000_000)
  } else {
    (second, nanosecond)
  }
  match @core.NaiveTime::from_hms_nano(hour, minute, clock_second, nano) {
    None => raise InconsistentFields
    Some(t) => t
  }
}

///|
/// Resolves `parsed`'s `%z` field into a `FixedOffset`.
fn resolve_offset(parsed : Parsed) -> @tz.FixedOffset raise ParseError {
  match parsed.offset_secs {
    None => raise IncompleteFields
    Some(secs) =>
      match @tz.FixedOffset::east(secs) {
        None => raise InconsistentFields
        Some(offset) => offset
      }
  }
}

///|
/// Parses `input` against `fmt`'s date fields (`%Y` plus `%m`/`%d` or
/// `%j`), via the general token engine (contrast `parse_rfc3339`'s
/// dedicated fast path).
pub fn parse_date(
  input : String,
  fmt : String,
) -> @core.NaiveDate raise ParseError {
  resolve_date(parse_items(tokenize(fmt), input))
}

///|
/// Parses `input` against `fmt`'s time-of-day fields (`%H`/`%M`/`%S`,
/// `%f` optional).
pub fn parse_time(
  input : String,
  fmt : String,
) -> @core.NaiveTime raise ParseError {
  resolve_time(parse_items(tokenize(fmt), input))
}

///|
/// Parses `input` against `fmt`'s date and time-of-day fields together.
pub fn parse_date_time(
  input : String,
  fmt : String,
) -> @core.NaiveDateTime raise ParseError {
  let parsed = parse_items(tokenize(fmt), input)
  @core.NaiveDateTime::new(resolve_date(parsed), resolve_time(parsed))
}

///|
/// Parses `input` against `fmt`'s date, time-of-day, and `%z` offset
/// fields, interpreting the date/time as the zone's local wall-clock
/// reading (mirroring `format_date_time_tz`'s own convention).
pub fn parse_date_time_tz(
  input : String,
  fmt : String,
) -> @tz.DateTime[@tz.FixedOffset] raise ParseError {
  let parsed = parse_items(tokenize(fmt), input)
  let local_naive = @core.NaiveDateTime::new(
    resolve_date(parsed),
    resolve_time(parsed),
  )
  let offset = resolve_offset(parsed)
  let shift = @core.TimeDelta::seconds(offset.local_minus_utc().to_int64()).unwrap()
  @tz.DateTime::from_utc(local_naive.sub_signed(shift), offset)
}
