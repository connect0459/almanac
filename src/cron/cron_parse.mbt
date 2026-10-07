///|
fn split_on(text : String, separator : Char) -> Array[String] {
  let parts : Array[String] = []
  let current = StringBuilder()
  for c in text {
    if c == separator {
      parts.push(current.to_string())
      current.reset()
    } else {
      current.write_char(c)
    }
  }
  parts.push(current.to_string())
  parts
}

///|
fn split_whitespace(text : String) -> Array[String] {
  let tokens : Array[String] = []
  let current = StringBuilder()
  for c in text {
    if c == ' ' || c == '\t' {
      if current.to_string() != "" {
        tokens.push(current.to_string())
        current.reset()
      }
    } else {
      current.write_char(c)
    }
  }
  if current.to_string() != "" {
    tokens.push(current.to_string())
  }
  tokens
}

///|
fn parse_number(text : String) -> Int? {
  if text.length() == 0 || text.length() > 4 {
    return None
  }
  let mut value = 0
  for c in text {
    if c < '0' || c > '9' {
      return None
    }
    value = value * 10 + (c.to_int() - '0'.to_int())
  }
  Some(value)
}

///|
fn parse_value(text : String, names : Array[String], names_start : Int) -> Int? {
  match parse_number(text) {
    Some(n) => Some(n)
    None => {
      let lower = text.to_lower()
      for i in 0..<names.length() {
        if names[i] == lower {
          return Some(names_start + i)
        }
      }
      None
    }
  }
}

///|
priv struct FieldSpec {
  field : CronField
  min : Int
  max : Int
  names : Array[String]
  names_start : Int
  allows_question : Bool
}

///|
fn FieldSpec::parse_item(
  self : FieldSpec,
  item : String,
) -> (Int, Int, Int) raise CronError {
  let invalid = InvalidField(self.field)
  let slash = split_on(item, '/')
  let (range_text, step) = match slash {
    [range] => (range, None)
    [range, step_text] =>
      match parse_number(step_text) {
        Some(n) if n >= 1 => (range, Some(n))
        _ => raise invalid
      }
    _ => raise invalid
  }
  let step_value = step.unwrap_or(1)
  if range_text == "*" {
    return (self.min, self.max, step_value)
  }
  let ends = split_on(range_text, '-')
  match ends {
    [single] =>
      match parse_value(single, self.names, self.names_start) {
        Some(v) if v >= self.min && v <= self.max && step is None => (v, v, 1)
        _ => raise invalid
      }
    [low_text, high_text] =>
      match
        (
          parse_value(low_text, self.names, self.names_start),
          parse_value(high_text, self.names, self.names_start),
        ) {
        (Some(low), Some(high)) if low >= self.min &&
          high <= self.max &&
          low <= high => (low, high, step_value)
        _ => raise invalid
      }
    _ => raise invalid
  }
}

///|
fn FieldSpec::parse(
  self : FieldSpec,
  text : String,
) -> (Int64, Bool) raise CronError {
  if text == "?" && self.allows_question {
    return (all_bits(self.min, self.max), true)
  }
  let mut bits = 0L
  for item in split_on(text, ',') {
    let (low, high, step) = self.parse_item(item)
    let mut v = low
    while v <= high {
      bits = bits | (1L << v)
      v += step
    }
  }
  (bits, text.length() > 0 && text[0] == '*')
}

///|
fn all_bits(min : Int, max : Int) -> Int64 {
  let mut bits = 0L
  for v in min..<=max {
    bits = bits | (1L << v)
  }
  bits
}

///|
fn has_bit(bits : Int64, n : Int) -> Bool {
  ((bits >> n) & 1L) != 0L
}

///|
fn shorthand_expansion(text : String) -> String? {
  match text.to_lower() {
    "@yearly" | "@annually" => Some("0 0 1 1 *")
    "@monthly" => Some("0 0 1 * *")
    "@weekly" => Some("0 0 * * 0")
    "@daily" | "@midnight" => Some("0 0 * * *")
    "@hourly" => Some("0 * * * *")
    _ => None
  }
}

///|
fn month_names() -> Array[String] {
  [
    "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov",
    "dec",
  ]
}

///|
fn weekday_names() -> Array[String] {
  ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
}

///|
/// Reads a cron expression: five fields (`minute hour day-of-month month
/// day-of-week`), six with seconds in front, or one of the shorthands
/// `@yearly` (`@annually`), `@monthly`, `@weekly`, `@daily` (`@midnight`) and
/// `@hourly`, either case.
///
/// Each field is a comma list of `*`, `n`, `a-b`, `*/n` or `a-b/n`. Month and
/// weekday fields also take English names (`JAN`, `mon-fri`), either case.
/// Day-of-month and day-of-week also take `?`, which means `*`. Both `0` and
/// `7` are Sunday. Fields are separated by runs of spaces or tabs.
///
/// Raises `InvalidField` naming the first field that cannot be read.
pub fn Cron::parse(expression : String) -> Cron raise CronError {
  let tokens = split_whitespace(expression)
  if tokens.length() == 0 {
    raise InvalidField(FieldCount)
  }
  if tokens[0].length() > 0 && tokens[0][0] == '@' {
    if tokens.length() != 1 {
      raise InvalidField(FieldCount)
    }
    return match shorthand_expansion(tokens[0]) {
      Some(expanded) => Cron::parse(expanded)
      None => raise InvalidField(Shorthand)
    }
  }
  if tokens.length() != 5 && tokens.length() != 6 {
    raise InvalidField(FieldCount)
  }
  let offset = tokens.length() - 5
  let seconds = if offset == 1 {
    FieldSpec::{
      field: Second,
      min: 0,
      max: 59,
      names: [],
      names_start: 0,
      allows_question: false,
    }.parse(tokens[0]).0
  } else {
    1L
  }
  let minutes = FieldSpec::{
      field: Minute,
      min: 0,
      max: 59,
      names: [],
      names_start: 0,
      allows_question: false,
    }.parse(tokens[offset]).0
  let hours = FieldSpec::{
      field: Hour,
      min: 0,
      max: 23,
      names: [],
      names_start: 0,
      allows_question: false,
    }.parse(tokens[offset + 1]).0
  let (days, day_star) = FieldSpec::{
    field: DayOfMonth,
    min: 1,
    max: 31,
    names: [],
    names_start: 0,
    allows_question: true,
  }.parse(tokens[offset + 2])
  let months = FieldSpec::{
      field: Month,
      min: 1,
      max: 12,
      names: month_names(),
      names_start: 1,
      allows_question: false,
    }.parse(tokens[offset + 3]).0
  let (weekday_bits, weekday_star) = FieldSpec::{
    field: DayOfWeek,
    min: 0,
    max: 7,
    names: weekday_names(),
    names_start: 0,
    allows_question: true,
  }.parse(tokens[offset + 4])
  let weekdays = (weekday_bits & 0x7FL) | ((weekday_bits >> 7) & 1L)
  { seconds, minutes, hours, days, months, weekdays, day_star, weekday_star, }
}
