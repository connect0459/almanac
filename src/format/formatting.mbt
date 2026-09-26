///|
fn pad_int(n : Int, width : Int) -> String {
  let sign = if n < 0 { "-" } else { "" }
  let magnitude = if n < 0 { -n } else { n }
  let digits = magnitude.to_string()
  let zeros = width - digits.length()
  if zeros <= 0 {
    sign + digits
  } else {
    sign + String::make(zeros, '0') + digits
  }
}

///|
fn weekday_long_name(w : @core.Weekday) -> String {
  match w {
    Mon => "Monday"
    Tue => "Tuesday"
    Wed => "Wednesday"
    Thu => "Thursday"
    Fri => "Friday"
    Sat => "Saturday"
    Sun => "Sunday"
  }
}

///|
fn weekday_short_name(w : @core.Weekday) -> String {
  match w {
    Mon => "Mon"
    Tue => "Tue"
    Wed => "Wed"
    Thu => "Thu"
    Fri => "Fri"
    Sat => "Sat"
    Sun => "Sun"
  }
}

///|
fn render(
  items : Array[Item],
  date : @core.NaiveDate?,
  time : @core.NaiveTime?,
) -> String raise ParseError {
  let out = StringBuilder()
  for item in items {
    match item {
      Literal(s) => out.write_string(s)
      Numeric(Year) =>
        match date {
          Some(d) => out.write_string(pad_int(d.year(), 4))
          None => raise MissingField(item)
        }
      Numeric(Month) =>
        match date {
          Some(d) => out.write_string(pad_int(d.month().number_from_month(), 2))
          None => raise MissingField(item)
        }
      Numeric(Day) =>
        match date {
          Some(d) => out.write_string(pad_int(d.day(), 2))
          None => raise MissingField(item)
        }
      Numeric(Ordinal) =>
        match date {
          Some(d) => out.write_string(pad_int(d.ordinal(), 3))
          None => raise MissingField(item)
        }
      Numeric(Hour) =>
        match time {
          Some(t) => out.write_string(pad_int(t.hour(), 2))
          None => raise MissingField(item)
        }
      Numeric(Minute) =>
        match time {
          Some(t) => out.write_string(pad_int(t.minute(), 2))
          None => raise MissingField(item)
        }
      Numeric(Second) =>
        match time {
          Some(t) =>
            out.write_string(
              pad_int(t.second() + t.nanosecond() / 1_000_000_000, 2),
            )
          None => raise MissingField(item)
        }
      Numeric(Nanosecond) =>
        match time {
          Some(t) =>
            out.write_string(pad_int(t.nanosecond() % 1_000_000_000, 9))
          None => raise MissingField(item)
        }
      Fixed(LongWeekdayName) =>
        match date {
          Some(d) => out.write_string(weekday_long_name(d.weekday()))
          None => raise MissingField(item)
        }
      Fixed(ShortWeekdayName) =>
        match date {
          Some(d) => out.write_string(weekday_short_name(d.weekday()))
          None => raise MissingField(item)
        }
      Fixed(TimezoneName) => raise MissingField(item)
      Fixed(TimezoneOffset) => raise MissingField(item)
    }
  }
  out.to_string()
}

///|
pub fn format_date(
  date : @core.NaiveDate,
  fmt : String,
) -> String raise ParseError {
  render(tokenize(fmt), Some(date), None)
}

///|
pub fn format_time(
  time : @core.NaiveTime,
  fmt : String,
) -> String raise ParseError {
  render(tokenize(fmt), None, Some(time))
}

///|
pub fn format_date_time(
  dt : @core.NaiveDateTime,
  fmt : String,
) -> String raise ParseError {
  render(tokenize(fmt), Some(dt.date()), Some(dt.time()))
}
