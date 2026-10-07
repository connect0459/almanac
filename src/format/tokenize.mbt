///|
/// Resolves the specifier starting at `chars[pos]` (the character right
/// after `%`, or right after a padding flag) into the `Item`(s) it
/// produces and the position just past the consumed specifier text.
/// Shared by `tokenize`'s normal path and its padding-flag path (`%-`/
/// `%0`/`%_`), which needs to resolve *what follows the flag* the same
/// way, to decide whether wrapping it in `PaddedNumeric` is valid.
fn resolve_specifier(
  chars : Array[Char],
  pos : Int,
  n : Int,
  locale : Locale,
) -> (Array[Item], Int) raise FormatError {
  match chars[pos] {
    'Y' => ([Numeric(Year)], pos + 1)
    'm' => ([Numeric(Month)], pos + 1)
    'd' => ([Numeric(Day)], pos + 1)
    'j' => ([Numeric(Ordinal)], pos + 1)
    'H' => ([Numeric(Hour)], pos + 1)
    'M' => ([Numeric(Minute)], pos + 1)
    'S' => ([Numeric(Second)], pos + 1)
    'f' => ([Numeric(Nanosecond9)], pos + 1)
    'A' => ([Fixed(LongWeekdayName)], pos + 1)
    'a' => ([Fixed(ShortWeekdayName)], pos + 1)
    'Z' => ([Fixed(TimezoneName)], pos + 1)
    'z' => ([Fixed(TimezoneOffset)], pos + 1)
    ':' => {
      let colon_end = for j = pos {
        if j < n && chars[j] == ':' {
          continue j + 1
        } else {
          break j
        }
      }
      if colon_end < n && chars[colon_end] == 'z' {
        match colon_end - pos {
          1 => ([Fixed(TimezoneOffsetColonMinutes)], colon_end + 1)
          2 => ([Fixed(TimezoneOffsetColonSeconds)], colon_end + 1)
          3 => ([Fixed(TimezoneOffsetColonHours)], colon_end + 1)
          _ => raise UnknownSpecifier(':')
        }
      } else {
        raise UnknownSpecifier(':')
      }
    }
    '#' =>
      if pos + 1 < n && chars[pos + 1] == 'z' {
        ([Fixed(TimezoneOffsetPermissive)], pos + 2)
      } else {
        raise UnknownSpecifier('#')
      }
    'B' => ([Fixed(LongMonthName)], pos + 1)
    'b' | 'h' => ([Fixed(ShortMonthName)], pos + 1)
    'P' => ([Fixed(AmPmLower)], pos + 1)
    'p' => ([Fixed(AmPmUpper)], pos + 1)
    'I' => ([Numeric(Hour12)], pos + 1)
    'l' => ([Numeric(Hour12Blank)], pos + 1)
    'k' => ([Numeric(HourBlank)], pos + 1)
    'n' => ([Literal("\n")], pos + 1)
    't' => ([Literal("\t")], pos + 1)
    's' => ([Numeric(Timestamp)], pos + 1)
    'G' => ([Numeric(IsoYear)], pos + 1)
    'g' => ([Numeric(IsoYearMod100)], pos + 1)
    'V' => ([Numeric(IsoWeekNumber)], pos + 1)
    'C' => ([Numeric(Century)], pos + 1)
    'y' => ([Numeric(YearMod100)], pos + 1)
    'q' => ([Numeric(Quarter)], pos + 1)
    'e' => ([Numeric(DayBlank)], pos + 1)
    'w' => ([Numeric(WeekdayNumberSunday0)], pos + 1)
    'u' => ([Numeric(WeekdayNumberMonday1)], pos + 1)
    'U' => ([Numeric(WeekSunday)], pos + 1)
    'W' => ([Numeric(WeekMonday)], pos + 1)
    'F' =>
      (
        [
          Numeric(Year),
          Literal("-"),
          Numeric(Month),
          Literal("-"),
          Numeric(Day),
        ],
        pos + 1,
      )
    'T' =>
      (
        [
          Numeric(Hour),
          Literal(":"),
          Numeric(Minute),
          Literal(":"),
          Numeric(Second),
        ],
        pos + 1,
      )
    'x' => (tokenize(locale.date_format(), locale~), pos + 1)
    'X' => (tokenize(locale.time_format(), locale~), pos + 1)
    'c' => (tokenize(locale.date_time_format(), locale~), pos + 1)
    'r' => (tokenize(locale.time_format_12h(), locale~), pos + 1)
    'D' =>
      (
        [
          Numeric(Month),
          Literal("/"),
          Numeric(Day),
          Literal("/"),
          Numeric(YearMod100),
        ],
        pos + 1,
      )
    'v' =>
      (
        [
          Numeric(DayBlank),
          Literal("-"),
          Fixed(ShortMonthName),
          Literal("-"),
          Numeric(Year),
        ],
        pos + 1,
      )
    'R' => ([Numeric(Hour), Literal(":"), Numeric(Minute)], pos + 1)
    '+' => ([Rfc3339], pos + 1)
    '.' =>
      if pos + 1 < n && chars[pos + 1] == 'f' {
        ([Numeric(DotFraction)], pos + 2)
      } else if pos + 2 < n && chars[pos + 2] == 'f' && chars[pos + 1] == '3' {
        ([Numeric(DotNanosecond3)], pos + 3)
      } else if pos + 2 < n && chars[pos + 2] == 'f' && chars[pos + 1] == '6' {
        ([Numeric(DotNanosecond6)], pos + 3)
      } else if pos + 2 < n && chars[pos + 2] == 'f' && chars[pos + 1] == '9' {
        ([Numeric(DotNanosecond9)], pos + 3)
      } else {
        raise UnknownSpecifier('.')
      }
    '3' =>
      if pos + 1 < n && chars[pos + 1] == 'f' {
        ([Numeric(Nanosecond3)], pos + 2)
      } else {
        raise UnknownSpecifier('3')
      }
    '6' =>
      if pos + 1 < n && chars[pos + 1] == 'f' {
        ([Numeric(Nanosecond6)], pos + 2)
      } else {
        raise UnknownSpecifier('6')
      }
    '9' =>
      if pos + 1 < n && chars[pos + 1] == 'f' {
        // %9f is the same fixed 9-digit fraction as bare %f.
        ([Numeric(Nanosecond9)], pos + 2)
      } else {
        raise UnknownSpecifier('9')
      }
    c => raise UnknownSpecifier(c)
  }
}

///|
fn is_layout_specifier(c : Char) -> Bool {
  c == 'x' || c == 'X' || c == 'c' || c == 'r'
}

///|
/// Parses a `%`-specifier format string into a sequence of `Item`s,
/// coalescing consecutive literal characters into a single `Literal` item
/// and expanding `%F`/`%T`/`%D`/`%R`/`%v` into their equivalent specifier
/// sequences. `%x`, `%X`, `%c` and `%r` expand to the layouts of `locale`
/// (`Locale::posix()` by default); the names a specifier renders or parses
/// come from the locale when the items are used, not here.
pub fn tokenize(
  fmt : String,
  locale? : Locale = Locale::posix(),
) -> Array[Item] raise FormatError {
  let chars = fmt.to_array()
  let n = chars.length()
  let items = []
  let literal = StringBuilder()
  fn flush_literal() -> Unit {
    if literal.is_empty() {
      ()
    } else {
      items.push(Literal(literal.to_string()))
      literal.reset()
    }
  }

  for i = 0 {
    if i >= n {
      break
    }
    if chars[i] != '%' {
      literal.write_char(chars[i])
      continue i + 1
    }
    if i + 1 >= n {
      raise TrailingPercent
    }
    if chars[i + 1] == '%' {
      literal.write_char('%')
      continue i + 2
    }
    let pad_mode = match chars[i + 1] {
      '-' => Some(NoPad)
      '0' => Some(ZeroPad)
      '_' => Some(SpacePad)
      _ => None
    }
    match pad_mode {
      None => {
        let (resolved, next_pos) = resolve_specifier(chars, i + 1, n, locale)
        flush_literal()
        for item in resolved {
          items.push(item)
        }
        continue next_pos
      }
      Some(mode) => {
        if i + 2 >= n {
          raise TrailingPercent
        }
        let (resolved, next_pos) = resolve_specifier(chars, i + 2, n, locale)
        flush_literal()
        if is_layout_specifier(chars[i + 2]) {
          raise UnknownSpecifier(chars[i + 1])
        }
        if resolved.length() == 1 {
          match resolved[0] {
            // The fractional-second family and %s have no fixed width to
            // override, so a padding flag is rejected on them — see
            // PaddedNumeric's doc comment.
            Numeric(
              Nanosecond9
              | DotFraction
              | Nanosecond3
              | Nanosecond6
              | DotNanosecond3
              | DotNanosecond6
              | DotNanosecond9
              | Timestamp
            ) => raise UnknownSpecifier(chars[i + 1])
            Numeric(kind) => items.push(PaddedNumeric(kind, mode))
            _ => raise UnknownSpecifier(chars[i + 1])
          }
        } else {
          raise UnknownSpecifier(chars[i + 1])
        }
        continue next_pos
      }
    }
  }
  flush_literal()
  items
}
