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
  /// `%I`/`%l`: the hour on a 12-hour clock (`1..=12`), reconciled with
  /// `is_pm` (and cross-checked against `hour`, if also present) by
  /// `resolve_hour`.
  hour12 : Int?
  /// `%p`/`%P`: whether the 12-hour clock reading is PM.
  is_pm : Bool?
  /// `%C`: the calendar year divided by 100, reconciled with `year`
  /// and/or `year_mod_100` by `resolve_year`.
  year_div_100 : Int?
  /// `%y`: the calendar year modulo 100. See `resolve_year`.
  year_mod_100 : Int?
  /// `%q`: cross-checked, like `ordinal`/`weekday`, against an
  /// already-determined date rather than used to construct one (a
  /// quarter alone doesn't determine a day).
  quarter : Int?
  /// `%U`: the Sunday-based week number, combined with `weekday` by
  /// `resolve_date_from_week` when no month/day/ordinal is present, or
  /// else cross-checked against the constructed date.
  week_sunday : Int?
  /// `%W`: the Monday-based week number. See `week_sunday`.
  week_monday : Int?
  /// `%Z`: the zone name text as it appeared (never validated). Only
  /// `parse_date_time_in` consults it, to resolve an abbreviation through
  /// the target zone; every other entry point discards it.
  zone_name : String?
  /// `%G`: the ISO week-based year, combined with `iso_week` and `weekday`
  /// by `resolve_date_from_iso_week`, or else cross-checked against the
  /// constructed date.
  iso_year : Int?
  /// `%g`: the ISO week-based year modulo 100. See `resolve_iso_year`.
  iso_year_mod_100 : Int?
  /// `%V`: the ISO week number. See `iso_year`.
  iso_week : Int?
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
    hour12: None,
    is_pm: None,
    year_div_100: None,
    year_mod_100: None,
    quarter: None,
    week_sunday: None,
    week_monday: None,
    zone_name: None,
    iso_year: None,
    iso_year_mod_100: None,
    iso_week: None,
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
/// Parses `%:z`'s `±HH:MM`, colon mandatory (exactly this project's own
/// rendered shape — unlike chrono's shared offset parser, which tolerates
/// a missing or space colon across every `%z` variant).
fn parse_offset_colon(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] != '+' && chars[pos] != '-' {
    None
  } else {
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
  }
}

///|
/// Parses `%::z`'s `±HH:MM:SS`, seconds mandatory.
fn parse_offset_double_colon(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] != '+' && chars[pos] != '-' {
    None
  } else {
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
                  match expect_char(chars, p3, ':') {
                    None => None
                    Some(p4) =>
                      match parse_fixed_digits(chars, p4, 2) {
                        None => None
                        Some((second, p5)) =>
                          if second > 59 {
                            None
                          } else {
                            Some(
                              (sign * (hour * 3600 + minute * 60 + second), p5),
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

///|
/// Parses `%:::z`'s `±HH`, hours only — no minutes or seconds field at
/// all (matching its own rendered shape).
fn parse_offset_triple_colon(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] != '+' && chars[pos] != '-' {
    None
  } else {
    let sign = if chars[pos] == '-' { -1 } else { 1 }
    match parse_fixed_digits(chars, pos + 1, 2) {
      None => None
      Some((hour, p1)) => Some((sign * hour * 3600, p1))
    }
  }
}

///|
/// Skips a run of zero or more `:`/space/tab characters (`%#z`'s
/// permissive hour/minute separator — mirrors chrono's `colon_or_space`).
fn skip_offset_separator(chars : Array[Char], pos : Int) -> Int {
  for i = pos {
    if i < chars.length() &&
      (chars[i] == ':' || chars[i] == ' ' || chars[i] == '\t') {
      continue i + 1
    } else {
      break i
    }
  }
}

///|
/// Parses `%#z`'s permissive offset: `Z`/`z` for zero, else a sign (`+`,
/// `-`, or U+2212 MINUS SIGN, matching chrono) plus 2-digit hours, then
/// optionally (after any run of `:`/space/tab) 2-digit minutes — absent
/// minutes default to `0`. No seconds field, matching chrono's own `%#z`
/// (its shared parsing engine doesn't read one either).
fn parse_offset_permissive(chars : Array[Char], pos : Int) -> (Int, Int)? {
  if pos < chars.length() && (chars[pos] == 'Z' || chars[pos] == 'z') {
    Some((0, pos + 1))
  } else if pos >= chars.length() {
    None
  } else if chars[pos] != '+' && chars[pos] != '-' && chars[pos] != '\u{2212}' {
    None
  } else {
    let sign = if chars[pos] == '+' { 1 } else { -1 }
    match parse_fixed_digits(chars, pos + 1, 2) {
      None => None
      Some((hour, p1)) => {
        let p2 = skip_offset_separator(chars, p1)
        match parse_fixed_digits(chars, p2, 2) {
          Some((minute, p3)) =>
            if minute > 59 {
              None
            } else {
              Some((sign * (hour * 3600 + minute * 60), p3))
            }
          None => Some((sign * hour * 3600, p2))
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
fn month_names() -> Array[(@core.Month, String, String)] {
  [
    (@core.Jan, "January", "Jan"),
    (@core.Feb, "February", "Feb"),
    (@core.Mar, "March", "Mar"),
    (@core.Apr, "April", "Apr"),
    (@core.May, "May", "May"),
    (@core.Jun, "June", "Jun"),
    (@core.Jul, "July", "Jul"),
    (@core.Aug, "August", "Aug"),
    (@core.Sep, "September", "Sep"),
    (@core.Oct, "October", "Oct"),
    (@core.Nov, "November", "Nov"),
    (@core.Dec, "December", "Dec"),
  ]
}

///|
/// Matches either the long (`%B`) or short (`%b`/`%h`) name of any month
/// at `pos` (whichever fits — mirrors `match_weekday_name`).
fn match_month_name(chars : Array[Char], pos : Int) -> (@core.Month, Int)? {
  let names = month_names()
  for i = 0 {
    if i >= names.length() {
      break None
    }
    let (m, long_name, short_name) = names[i]
    match match_literal(chars, pos, long_name) {
      Some(p) => break Some((m, p))
      None =>
        match match_literal(chars, pos, short_name) {
          Some(p) => break Some((m, p))
          None => continue i + 1
        }
    }
  }
}

///|
/// A month name resolves directly into `parsed.month` (unlike a weekday
/// name, which only cross-checks an already-constructed date): a format
/// like `"%B %d %Y"` has no other field that could supply the month.
fn apply_month_name_specifier(
  chars : Array[Char],
  pos : Int,
  parsed : Parsed,
) -> (Parsed, Int) raise ParseError {
  match match_month_name(chars, pos) {
    None => raise InputMismatch
    Some((m, p)) =>
      (
        { ..parsed, month: merge_field(parsed.month, m.number_from_month()), },
        p,
      )
  }
}

///|
/// Matches `"am"`/`"pm"` case-insensitively at `pos`, regardless of
/// whether the format used `%p` or `%P` to render it — the two specifiers
/// differ only in rendered case, not in the value they carry.
fn match_ampm(chars : Array[Char], pos : Int) -> (Bool, Int)? {
  match expect_char_ci(chars, pos, 'A', 'a') {
    Some(p1) =>
      match expect_char_ci(chars, p1, 'M', 'm') {
        Some(p2) => Some((false, p2))
        None => None
      }
    None =>
      match expect_char_ci(chars, pos, 'P', 'p') {
        Some(p1) =>
          match expect_char_ci(chars, p1, 'M', 'm') {
            Some(p2) => Some((true, p2))
            None => None
          }
        None => None
      }
  }
}

///|
fn apply_ampm_specifier(
  chars : Array[Char],
  pos : Int,
  parsed : Parsed,
) -> (Parsed, Int) raise ParseError {
  match match_ampm(chars, pos) {
    None => raise InputMismatch
    Some((is_pm, p)) =>
      ({ ..parsed, is_pm: merge_field(parsed.is_pm, is_pm), }, p)
  }
}

///|
/// Parses `%l`'s blank-padded 2-character field: either two digits (like
/// `%I`) or a leading space followed by one digit.
fn parse_blank_or_zero_padded_digits(
  chars : Array[Char],
  pos : Int,
  width : Int,
) -> (Int, Int)? {
  if pos < chars.length() && chars[pos] == ' ' {
    parse_fixed_digits(chars, pos + 1, width - 1)
  } else {
    parse_fixed_digits(chars, pos, width)
  }
}

///|
/// Applies a single token against `input` at `pos`, returning the
/// updated accumulator and the new position. `%Z` consumes and discards a
/// run of one or more non-whitespace characters: a zone name (an IANA
/// abbreviation, `"UTC"`, or a bare offset's own string) has no generically
/// parseable shape, so it is neither validated nor kept.
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
    // A padding flag only affects rendering — chrono's parser reads the
    // same width/logic regardless of Pad, so this delegates verbatim to
    // the unwrapped specifier's own parsing.
    PaddedNumeric(kind, _) => apply_item(Numeric(kind), parsed, chars, pos)
    Rfc3339 =>
      match parse_rfc3339_datetime(chars, pos) {
        None => raise InputMismatch
        Some((date, time, offset_secs, p)) => {
          let seconds = time.second() + time.nanosecond() / 1_000_000_000
          let nanos = time.nanosecond() % 1_000_000_000
          (
            {
              ..parsed,
              year: merge_field(parsed.year, date.year()),
              month: merge_field(parsed.month, date.month().number_from_month()),
              day: merge_field(parsed.day, date.day()),
              hour: merge_field(parsed.hour, time.hour()),
              minute: merge_field(parsed.minute, time.minute()),
              second: merge_field(parsed.second, seconds),
              nanosecond: merge_field(parsed.nanosecond, nanos),
              offset_secs: merge_field(parsed.offset_secs, offset_secs),
            },
            p,
          )
        }
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
    Numeric(DotFraction) =>
      match parse_rfc3339_fraction(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, nanosecond: merge_field(parsed.nanosecond, value), }, p)
      }
    Numeric(Nanosecond3) =>
      match parse_fixed_digits(chars, pos, 3) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            {
              ..parsed,
              nanosecond: merge_field(parsed.nanosecond, value * 1_000_000),
            },
            p,
          )
      }
    Numeric(Nanosecond6) =>
      match parse_fixed_digits(chars, pos, 6) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            {
              ..parsed,
              nanosecond: merge_field(parsed.nanosecond, value * 1_000),
            },
            p,
          )
      }
    Fixed(LongWeekdayName) => apply_weekday_specifier(chars, pos, parsed)
    Fixed(ShortWeekdayName) => apply_weekday_specifier(chars, pos, parsed)
    Fixed(TimezoneName) => {
      let end = for p = pos {
        if p < chars.length() && !chars[p].is_whitespace() {
          continue p + 1
        }
        break p
      }
      if end == pos {
        raise InputMismatch
      }
      let name = String::from_array(chars[pos:end])
      ({ ..parsed, zone_name: merge_field(parsed.zone_name, name), }, end)
    }
    Fixed(TimezoneOffset) =>
      match parse_offset_no_colon(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
    Fixed(TimezoneOffsetColonMinutes) =>
      match parse_offset_colon(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
    Fixed(TimezoneOffsetColonSeconds) =>
      match parse_offset_double_colon(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
    Fixed(TimezoneOffsetColonHours) =>
      match parse_offset_triple_colon(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
    Fixed(TimezoneOffsetPermissive) =>
      match parse_offset_permissive(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, offset_secs: merge_field(parsed.offset_secs, value), },
            p,
          )
      }
    Fixed(LongMonthName) => apply_month_name_specifier(chars, pos, parsed)
    Fixed(ShortMonthName) => apply_month_name_specifier(chars, pos, parsed)
    Fixed(AmPmLower) => apply_ampm_specifier(chars, pos, parsed)
    Fixed(AmPmUpper) => apply_ampm_specifier(chars, pos, parsed)
    Numeric(Hour12) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, hour12: merge_field(parsed.hour12, value), }, p)
      }
    Numeric(Hour12Blank) =>
      match parse_blank_or_zero_padded_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, hour12: merge_field(parsed.hour12, value), }, p)
      }
    Numeric(HourBlank) =>
      match parse_blank_or_zero_padded_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, hour: merge_field(parsed.hour, value), }, p)
      }
    Numeric(Timestamp) => raise InputMismatch
    Numeric(IsoYear) =>
      match parse_signed_greedy_digits(chars, pos) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, iso_year: merge_field(parsed.iso_year, value), }, p)
      }
    Numeric(IsoYear2) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            {
              ..parsed,
              iso_year_mod_100: merge_field(parsed.iso_year_mod_100, value),
            },
            p,
          )
      }
    Numeric(IsoWeekNumber) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, iso_week: merge_field(parsed.iso_week, value), }, p)
      }
    Numeric(Century) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, year_div_100: merge_field(parsed.year_div_100, value), },
            p,
          )
      }
    Numeric(YearMod100) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, year_mod_100: merge_field(parsed.year_mod_100, value), },
            p,
          )
      }
    Numeric(Quarter) =>
      match parse_fixed_digits(chars, pos, 1) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, quarter: merge_field(parsed.quarter, value), }, p)
      }
    Numeric(DayBlank) =>
      match parse_blank_or_zero_padded_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          ({ ..parsed, day: merge_field(parsed.day, value), }, p)
      }
    Numeric(WeekdayNumberSunday0) =>
      match parse_fixed_digits(chars, pos, 1) {
        None => raise InputMismatch
        Some((value, p)) =>
          match @core.Weekday::from_num_days_from_sunday(value) {
            None => raise InconsistentFields
            Some(wd) =>
              ({ ..parsed, weekday: merge_field(parsed.weekday, wd), }, p)
          }
      }
    Numeric(WeekdayNumberMonday1) =>
      match parse_fixed_digits(chars, pos, 1) {
        None => raise InputMismatch
        Some((value, p)) =>
          match @core.Weekday::from_number_from_monday(value) {
            None => raise InconsistentFields
            Some(wd) =>
              ({ ..parsed, weekday: merge_field(parsed.weekday, wd), }, p)
          }
      }
    Numeric(WeekSunday) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, week_sunday: merge_field(parsed.week_sunday, value), },
            p,
          )
      }
    Numeric(WeekMonday) =>
      match parse_fixed_digits(chars, pos, 2) {
        None => raise InputMismatch
        Some((value, p)) =>
          (
            { ..parsed, week_monday: merge_field(parsed.week_monday, value), },
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
/// Resolves the actual calendar year from `%Y` (`year`) and/or `%C`/`%y`
/// (`year_div_100`/`year_mod_100`), cross-checking every present field
/// against the others (mirrors `merge_field`'s disagreement-raises
/// philosophy, applied across specifiers rather than within one). A
/// negative `%Y` combined with either `%C` or `%y` is rejected outright,
/// rather than silently reconciled, since a negative year has no
/// well-defined century/modulo split. `%y` alone (no `%C`, no `%Y`) is
/// interpreted via the conventional two-digit-year pivot (`< 70` -> 20xx,
/// `>= 70` -> 19xx), matching strftime/chrono convention. `None` when
/// none of the three fields is present at all.
fn resolve_year(parsed : Parsed) -> Int? raise ParseError {
  match (parsed.year, parsed.year_div_100, parsed.year_mod_100) {
    (Some(y), None, None) => Some(y)
    (Some(y), q, r) => {
      if y < 0 {
        raise InconsistentFields
      }
      let q_ = y / 100
      let r_ = y % 100
      if q.unwrap_or(q_) != q_ || r.unwrap_or(r_) != r_ {
        raise InconsistentFields
      }
      Some(y)
    }
    (None, None, None) => None
    (None, Some(q), Some(r)) => Some(q * 100 + r)
    (None, None, Some(r)) => Some(r + (if r < 70 { 2000 } else { 1900 }))
    (None, Some(_), None) => raise IncompleteFields
  }
}

///|
/// The 1-based ordinal day of the date in `year` whose weekday is
/// `weekday` and whose `%U`/`%W`-style week number is `week`, under a
/// week-numbering scheme whose weeks start on the weekday indexed `0` by
/// `wday_x` (see `week_number`, this function's inverse). Not
/// range-checked against `year`'s actual length — `resolve_date_from_week`
/// delegates that to `NaiveDate::from_yo`.
fn week_based_yday(first_day_wday_x : Int, week : Int, wday_x : Int) -> Int {
  let first_anchor_yday = (7 - first_day_wday_x) % 7 + 1
  first_anchor_yday + (week - 1) * 7 + wday_x
}

///|
/// Constructs a date from `%U`/`%W` (a week number) plus a weekday
/// (`%A`/`%a`/`%w`/`%u`), for when no month/day/ordinal was given at all.
/// Used only by `resolve_date`'s `(None, None)` branch; `%q` has no role
/// here (a quarter alone never determines a day, so it's cross-checked
/// against the finished date instead, like `ordinal`/`weekday`).
fn resolve_date_from_week(
  year : Int,
  parsed : Parsed,
) -> @core.NaiveDate raise ParseError {
  let weekday = match parsed.weekday {
    None => raise IncompleteFields
    Some(wd) => wd
  }
  // `from_ymd(year, 1, 1)` never fails: day 1 is always valid in month 1,
  // for any year.
  let jan1 = @core.NaiveDate::from_ymd(year, 1, 1).unwrap()
  let from_sunday = parsed.week_sunday.map(week => {
    week_based_yday(
      jan1.weekday().num_days_from_sunday(),
      week,
      weekday.num_days_from_sunday(),
    )
  })
  let from_monday = parsed.week_monday.map(week => {
    week_based_yday(
      jan1.weekday().num_days_from_monday(),
      week,
      weekday.num_days_from_monday(),
    )
  })
  let yday = match (from_sunday, from_monday) {
    (None, None) => raise IncompleteFields
    (Some(y), None) => y
    (None, Some(y)) => y
    (Some(a), Some(b)) => if a == b { a } else { raise InconsistentFields }
  }
  match @core.NaiveDate::from_yo(year, yday) {
    None => raise InconsistentFields
    Some(d) => d
  }
}

///|
/// Resolves the ISO week-based year from `%G` (`iso_year`) and/or `%g`
/// (`iso_year_mod_100`), cross-checking both when both are present. A lone
/// `%g` uses the same two-digit-year pivot as `resolve_year`. `None` when
/// neither field is present.
fn resolve_iso_year(parsed : Parsed) -> Int? raise ParseError {
  match (parsed.iso_year, parsed.iso_year_mod_100) {
    (None, None) => None
    (Some(y), None) => Some(y)
    (Some(y), Some(r)) => {
      if y < 0 || y % 100 != r {
        raise InconsistentFields
      }
      Some(y)
    }
    (None, Some(r)) => Some(r + (if r < 70 { 2000 } else { 1900 }))
  }
}

///|
/// Constructs a date from `%G`/`%g` (an ISO year) plus `%V` (an ISO week)
/// and a weekday (`%A`/`%a`/`%w`/`%u`). Used by `resolve_date` only when no
/// month/day/ordinal was given at all.
fn resolve_date_from_iso_week(
  iso_year : Int,
  iso_week : Int,
  parsed : Parsed,
) -> @core.NaiveDate raise ParseError {
  let weekday = match parsed.weekday {
    None => raise IncompleteFields
    Some(wd) => wd
  }
  match @core.NaiveDate::from_isoywd(iso_year, iso_week, weekday) {
    None => raise InconsistentFields
    Some(d) => d
  }
}

///|
fn require_year(year : Int?) -> Int raise ParseError {
  match year {
    None => raise IncompleteFields
    Some(y) => y
  }
}

///|
fn resolve_date(parsed : Parsed) -> @core.NaiveDate raise ParseError {
  let year = resolve_year(parsed)
  let iso_year = resolve_iso_year(parsed)
  let date = match (parsed.month, parsed.day) {
    (Some(month), Some(day)) =>
      match @core.NaiveDate::from_ymd(require_year(year), month, day) {
        None => raise InconsistentFields
        Some(d) => d
      }
    (None, None) =>
      match parsed.ordinal {
        Some(ordinal) =>
          match @core.NaiveDate::from_yo(require_year(year), ordinal) {
            None => raise InconsistentFields
            Some(d) => d
          }
        None =>
          match (iso_year, parsed.iso_week) {
            (Some(iy), Some(iw)) => resolve_date_from_iso_week(iy, iw, parsed)
            _ => resolve_date_from_week(require_year(year), parsed)
          }
      }
    _ => raise IncompleteFields
  }
  match year {
    None => ()
    Some(y) => if date.year() != y { raise InconsistentFields }
  }
  match iso_year {
    None => ()
    Some(iy) => if date.iso_week().year() != iy { raise InconsistentFields }
  }
  match parsed.iso_week {
    None => ()
    Some(iw) => if date.iso_week().week() != iw { raise InconsistentFields }
  }
  match parsed.ordinal {
    None => ()
    Some(ordinal) => if date.ordinal() != ordinal { raise InconsistentFields }
  }
  match parsed.weekday {
    None => ()
    Some(wd) => if date.weekday() != wd { raise InconsistentFields }
  }
  match parsed.quarter {
    None => ()
    Some(q) => if date.quarter() != q { raise InconsistentFields }
  }
  match parsed.week_sunday {
    None => ()
    Some(week) =>
      if week_number(date.ordinal(), date.weekday().num_days_from_sunday()) !=
        week {
        raise InconsistentFields
      }
  }
  match parsed.week_monday {
    None => ()
    Some(week) =>
      if week_number(date.ordinal(), date.weekday().num_days_from_monday()) !=
        week {
        raise InconsistentFields
      }
  }
  date
}

///|
/// Resolves the 24-hour `hour` field from `%H` and/or the `%I`/`%l`
/// (`hour12`) + `%p`/`%P` (`is_pm`) pair, cross-checking both against each
/// other when both are present (mirrors `merge_field`'s
/// disagreement-raises philosophy, applied across specifiers rather than
/// within one). `hour12` alone (no am/pm marker) or `is_pm` alone (no
/// 12-hour value) is incomplete: neither determines an hour by itself.
fn resolve_hour(parsed : Parsed) -> Int raise ParseError {
  let from_12h = match (parsed.hour12, parsed.is_pm) {
    (None, None) => None
    (Some(hour12), Some(is_pm)) => {
      if hour12 < 1 || hour12 > 12 {
        raise InconsistentFields
      }
      let base = if hour12 == 12 { 0 } else { hour12 }
      Some(if is_pm { base + 12 } else { base })
    }
    _ => raise IncompleteFields
  }
  match (parsed.hour, from_12h) {
    (None, None) => raise IncompleteFields
    (Some(h), None) => h
    (None, Some(h)) => h
    (Some(h), Some(h2)) => if h == h2 { h } else { raise InconsistentFields }
  }
}

///|
/// Resolves `parsed`'s time fields into a `NaiveTime`: an hour (via
/// `resolve_hour`), `minute`, and `second` are required; `nanosecond`
/// defaults to `0`. A `second` of `60` (a leap second) maps to
/// `NaiveTime`'s `second() == 59, nanosecond() >= 1_000_000_000`
/// convention.
fn resolve_time(parsed : Parsed) -> @core.NaiveTime raise ParseError {
  let hour = resolve_hour(parsed)
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
  @tz.DateTime::from_utc(
    local_naive.sub_seconds(offset.local_minus_utc()),
    offset,
  )
}

///|
/// Parses `input` against a zone-less `fmt` (date and time-of-day fields
/// only) and resolves the reading as wall-clock time in `tz`, surfacing DST
/// ambiguity as `MappedLocalTime` (`Ambiguous` in a fold, `Absent` in a
/// gap). Raises `InconsistentFields` if `fmt` yields an offset (`%z` and
/// friends, or a compound like `%+`), since it would be silently discarded
/// or contradict `tz`.
///
/// A `%Z` zone name that `tz` recognizes (`TimeZone::offset_from_abbreviation`)
/// fixes the offset, like Go's `ParseInLocation`: the reading is taken as
/// that offset's instant even if the wall clock disagrees, and the result is
/// `Single`, which is how an abbreviation such as `EDT` picks a side of a
/// DST fold. A name `tz` does not recognize is ignored, resolving the
/// reading as usual.
pub fn[Tz : @tz.TimeZone] parse_date_time_in(
  input : String,
  fmt : String,
  tz : Tz,
) -> @tz.MappedLocalTime[@tz.DateTime[Tz]] raise ParseError {
  let parsed = parse_items(tokenize(fmt), input)
  if parsed.offset_secs is Some(_) {
    raise InconsistentFields
  }
  let local_naive = @core.NaiveDateTime::new(
    resolve_date(parsed),
    resolve_time(parsed),
  )
  match parsed.zone_name {
    Some(name) =>
      match tz.offset_from_abbreviation(name, local_naive) {
        Some(offset) =>
          Single(
            @tz.DateTime::from_utc(
              local_naive.sub_seconds(offset.local_minus_utc()),
              tz,
            ),
          )
        None => tz.from_local_datetime(local_naive)
      }
    None => tz.from_local_datetime(local_naive)
  }
}
