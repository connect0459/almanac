///|
/// Parses a `%`-specifier format string into a sequence of `Item`s,
/// coalescing consecutive literal characters into a single `Literal` item
/// and expanding `%F`/`%T` into their equivalent specifier sequences.
pub fn tokenize(fmt : String) -> Array[Item] raise ParseError {
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
    match chars[i + 1] {
      '%' => literal.write_char('%')
      'Y' => {
        flush_literal()
        items.push(Numeric(Year))
      }
      'm' => {
        flush_literal()
        items.push(Numeric(Month))
      }
      'd' => {
        flush_literal()
        items.push(Numeric(Day))
      }
      'j' => {
        flush_literal()
        items.push(Numeric(Ordinal))
      }
      'H' => {
        flush_literal()
        items.push(Numeric(Hour))
      }
      'M' => {
        flush_literal()
        items.push(Numeric(Minute))
      }
      'S' => {
        flush_literal()
        items.push(Numeric(Second))
      }
      'f' => {
        flush_literal()
        items.push(Numeric(Nanosecond))
      }
      'A' => {
        flush_literal()
        items.push(Fixed(LongWeekdayName))
      }
      'a' => {
        flush_literal()
        items.push(Fixed(ShortWeekdayName))
      }
      'Z' => {
        flush_literal()
        items.push(Fixed(TimezoneName))
      }
      'z' => {
        flush_literal()
        items.push(Fixed(TimezoneOffset))
      }
      'B' => {
        flush_literal()
        items.push(Fixed(LongMonthName))
      }
      'b' | 'h' => {
        flush_literal()
        items.push(Fixed(ShortMonthName))
      }
      'P' => {
        flush_literal()
        items.push(Fixed(AmPmLower))
      }
      'p' => {
        flush_literal()
        items.push(Fixed(AmPmUpper))
      }
      'I' => {
        flush_literal()
        items.push(Numeric(Hour12))
      }
      'l' => {
        flush_literal()
        items.push(Numeric(Hour12Blank))
      }
      's' => {
        flush_literal()
        items.push(Numeric(Timestamp))
      }
      'G' => {
        flush_literal()
        items.push(Numeric(IsoYear))
      }
      'g' => {
        flush_literal()
        items.push(Numeric(IsoYear2))
      }
      'V' => {
        flush_literal()
        items.push(Numeric(IsoWeekNumber))
      }
      'C' => {
        flush_literal()
        items.push(Numeric(Century))
      }
      'y' => {
        flush_literal()
        items.push(Numeric(YearMod100))
      }
      'q' => {
        flush_literal()
        items.push(Numeric(Quarter))
      }
      'e' => {
        flush_literal()
        items.push(Numeric(DayBlank))
      }
      'w' => {
        flush_literal()
        items.push(Numeric(WeekdayNumberSunday0))
      }
      'u' => {
        flush_literal()
        items.push(Numeric(WeekdayNumberMonday1))
      }
      'U' => {
        flush_literal()
        items.push(Numeric(WeekSunday))
      }
      'W' => {
        flush_literal()
        items.push(Numeric(WeekMonday))
      }
      'F' => {
        flush_literal()
        items.push(Numeric(Year))
        items.push(Literal("-"))
        items.push(Numeric(Month))
        items.push(Literal("-"))
        items.push(Numeric(Day))
      }
      'T' => {
        flush_literal()
        items.push(Numeric(Hour))
        items.push(Literal(":"))
        items.push(Numeric(Minute))
        items.push(Literal(":"))
        items.push(Numeric(Second))
      }
      'D' | 'x' => {
        flush_literal()
        items.push(Numeric(Month))
        items.push(Literal("/"))
        items.push(Numeric(Day))
        items.push(Literal("/"))
        items.push(Numeric(YearMod100))
      }
      'v' => {
        flush_literal()
        items.push(Numeric(DayBlank))
        items.push(Literal("-"))
        items.push(Fixed(ShortMonthName))
        items.push(Literal("-"))
        items.push(Numeric(Year))
      }
      'R' => {
        flush_literal()
        items.push(Numeric(Hour))
        items.push(Literal(":"))
        items.push(Numeric(Minute))
      }
      'X' => {
        flush_literal()
        items.push(Numeric(Hour))
        items.push(Literal(":"))
        items.push(Numeric(Minute))
        items.push(Literal(":"))
        items.push(Numeric(Second))
      }
      'r' => {
        flush_literal()
        items.push(Numeric(Hour12))
        items.push(Literal(":"))
        items.push(Numeric(Minute))
        items.push(Literal(":"))
        items.push(Numeric(Second))
        items.push(Literal(" "))
        items.push(Fixed(AmPmUpper))
      }
      'c' => {
        flush_literal()
        items.push(Fixed(ShortWeekdayName))
        items.push(Literal(" "))
        items.push(Fixed(ShortMonthName))
        items.push(Literal(" "))
        items.push(Numeric(DayBlank))
        items.push(Literal(" "))
        items.push(Numeric(Hour))
        items.push(Literal(":"))
        items.push(Numeric(Minute))
        items.push(Literal(":"))
        items.push(Numeric(Second))
        items.push(Literal(" "))
        items.push(Numeric(Year))
      }
      '+' => {
        flush_literal()
        items.push(Rfc3339)
      }
      '.' =>
        if i + 2 < n && chars[i + 2] == 'f' {
          flush_literal()
          items.push(Numeric(DotFraction))
          continue i + 3
        } else {
          raise UnknownSpecifier('.')
        }
      '3' =>
        if i + 2 < n && chars[i + 2] == 'f' {
          flush_literal()
          items.push(Numeric(Nanosecond3))
          continue i + 3
        } else {
          raise UnknownSpecifier('3')
        }
      '6' =>
        if i + 2 < n && chars[i + 2] == 'f' {
          flush_literal()
          items.push(Numeric(Nanosecond6))
          continue i + 3
        } else {
          raise UnknownSpecifier('6')
        }
      '9' =>
        if i + 2 < n && chars[i + 2] == 'f' {
          flush_literal()
          // %9f is the same fixed 9-digit fraction as bare %f.
          items.push(Numeric(Nanosecond))
          continue i + 3
        } else {
          raise UnknownSpecifier('9')
        }
      c => raise UnknownSpecifier(c)
    }
    continue i + 2
  }
  flush_literal()
  items
}
