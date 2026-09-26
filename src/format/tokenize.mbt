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
      c => raise UnknownSpecifier(c)
    }
    continue i + 2
  }
  flush_literal()
  items
}
