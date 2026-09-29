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
fn month_short_name(m : @core.Month) -> String {
  match m {
    Jan => "Jan"
    Feb => "Feb"
    Mar => "Mar"
    Apr => "Apr"
    May => "May"
    Jun => "Jun"
    Jul => "Jul"
    Aug => "Aug"
    Sep => "Sep"
    Oct => "Oct"
    Nov => "Nov"
    Dec => "Dec"
  }
}

///|
/// Space-pads a non-negative integer to `width` characters (strftime's
/// `%l`, unlike `pad_int`'s zero-padding). `hour12()`'s values (`1..=12`)
/// never need a sign.
fn pad_int_blank(n : Int, width : Int) -> String {
  let digits = n.to_string()
  let spaces = width - digits.length()
  if spaces <= 0 {
    digits
  } else {
    String::make(spaces, ' ') + digits
  }
}

///|
/// The week number (`%U`/`%W`, `0..=53`) of the date whose 1-based
/// ordinal day is `yday`, under a week-numbering scheme whose weeks
/// start on the weekday indexed `0` by `wday_x` (that date's own
/// `Weekday::num_days_from_sunday()`/`num_days_from_monday()`, matching
/// `%U`'s Sunday start or `%W`'s Monday start respectively): days before
/// the year's first such start day fall in week `0`.
fn week_number(yday : Int, wday_x : Int) -> Int {
  (yday - 1 - wday_x + 7) / 7
}

///|
/// Renders a signed offset (in seconds) as strftime's `%z`: a sign
/// followed by a zero-padded `HHMM`, with no colon and no sub-minute
/// seconds component.
fn format_offset_no_colon(secs : Int) -> String {
  let sign = if secs < 0 { "-" } else { "+" }
  let magnitude = if secs < 0 { -secs } else { secs }
  let hours = magnitude / 3600
  let minutes = magnitude % 3600 / 60
  sign + pad_int(hours, 2) + pad_int(minutes, 2)
}

///|
fn render(
  items : Array[Item],
  date : @core.NaiveDate?,
  time : @core.NaiveTime?,
  tz_info : (Int, String)?,
  timestamp : Int64?,
) -> String raise ParseError {
  let out = StringBuilder()
  for item in items {
    match item {
      Literal(s) => out.write_string(s)
      Rfc3339 =>
        match (date, time, tz_info) {
          (Some(d), Some(t), Some((offset, _))) =>
            out.write_string(render_rfc3339(d, t, offset))
          _ => raise MissingField(item)
        }
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
      Fixed(TimezoneName) =>
        match tz_info {
          Some((_, name)) => out.write_string(name)
          None => raise MissingField(item)
        }
      Fixed(TimezoneOffset) =>
        match tz_info {
          Some((offset, _)) => out.write_string(format_offset_no_colon(offset))
          None => raise MissingField(item)
        }
      Fixed(LongMonthName) =>
        match date {
          Some(d) => out.write_string(d.month().name())
          None => raise MissingField(item)
        }
      Fixed(ShortMonthName) =>
        match date {
          Some(d) => out.write_string(month_short_name(d.month()))
          None => raise MissingField(item)
        }
      Fixed(AmPmLower) =>
        match time {
          Some(t) => {
            let (is_pm, _) = t.hour12()
            out.write_string(if is_pm { "pm" } else { "am" })
          }
          None => raise MissingField(item)
        }
      Fixed(AmPmUpper) =>
        match time {
          Some(t) => {
            let (is_pm, _) = t.hour12()
            out.write_string(if is_pm { "PM" } else { "AM" })
          }
          None => raise MissingField(item)
        }
      Numeric(Hour12) =>
        match time {
          Some(t) => {
            let (_, hour) = t.hour12()
            out.write_string(pad_int(hour, 2))
          }
          None => raise MissingField(item)
        }
      Numeric(Hour12Blank) =>
        match time {
          Some(t) => {
            let (_, hour) = t.hour12()
            out.write_string(pad_int_blank(hour, 2))
          }
          None => raise MissingField(item)
        }
      Numeric(Timestamp) =>
        match timestamp {
          Some(ts) => out.write_string(ts.to_string())
          None => raise MissingField(item)
        }
      Numeric(IsoYear) =>
        match date {
          Some(d) => out.write_string(pad_int(d.iso_week().year(), 4))
          None => raise MissingField(item)
        }
      Numeric(IsoYear2) =>
        match date {
          Some(d) => out.write_string(pad_int(d.iso_week().year() % 100, 2))
          None => raise MissingField(item)
        }
      Numeric(IsoWeekNumber) =>
        match date {
          Some(d) => out.write_string(pad_int(d.iso_week().week(), 2))
          None => raise MissingField(item)
        }
      Numeric(Century) =>
        match date {
          Some(d) => out.write_string(pad_int(d.year() / 100, 2))
          None => raise MissingField(item)
        }
      Numeric(YearMod100) =>
        match date {
          Some(d) => out.write_string(pad_int(d.year() % 100, 2))
          None => raise MissingField(item)
        }
      Numeric(Quarter) =>
        match date {
          Some(d) => out.write_string(pad_int(d.quarter(), 1))
          None => raise MissingField(item)
        }
      Numeric(DayBlank) =>
        match date {
          Some(d) => out.write_string(pad_int_blank(d.day(), 2))
          None => raise MissingField(item)
        }
      Numeric(WeekdayNumberSunday0) =>
        match date {
          Some(d) =>
            out.write_string(pad_int(d.weekday().num_days_from_sunday(), 1))
          None => raise MissingField(item)
        }
      Numeric(WeekdayNumberMonday1) =>
        match date {
          Some(d) =>
            out.write_string(pad_int(d.weekday().number_from_monday(), 1))
          None => raise MissingField(item)
        }
      Numeric(WeekSunday) =>
        match date {
          Some(d) =>
            out.write_string(
              pad_int(
                week_number(d.ordinal(), d.weekday().num_days_from_sunday()),
                2,
              ),
            )
          None => raise MissingField(item)
        }
      Numeric(WeekMonday) =>
        match date {
          Some(d) =>
            out.write_string(
              pad_int(
                week_number(d.ordinal(), d.weekday().num_days_from_monday()),
                2,
              ),
            )
          None => raise MissingField(item)
        }
    }
  }
  out.to_string()
}

///|
pub fn format_date(
  date : @core.NaiveDate,
  fmt : String,
) -> String raise ParseError {
  render(tokenize(fmt), Some(date), None, None, None)
}

///|
pub fn format_time(
  time : @core.NaiveTime,
  fmt : String,
) -> String raise ParseError {
  render(tokenize(fmt), None, Some(time), None, None)
}

///|
pub fn format_date_time(
  dt : @core.NaiveDateTime,
  fmt : String,
) -> String raise ParseError {
  render(
    tokenize(fmt),
    Some(dt.date()),
    Some(dt.time()),
    None,
    Some(dt.timestamp()),
  )
}

///|
/// Renders a zone-aware `DateTime[Tz]` against `fmt`, in its local
/// (wall-clock) representation. `%Z` renders `tz.tz_name()`; `%z` renders
/// the numeric offset, strftime-style (`+HHMM`, no colon). `%s` renders
/// the underlying UTC instant's timestamp, unaffected by the local zone
/// shift applied to every other field.
pub fn[Tz : @tz.TimeZone] format_date_time_tz(
  dt : @tz.DateTime[Tz],
  fmt : String,
) -> String raise ParseError {
  let wall_clock = dt.naive_local()
  let name = dt.timezone().tz_name(dt.naive_utc())
  let offset = dt.offset().local_minus_utc()
  render(
    tokenize(fmt),
    Some(wall_clock.date()),
    Some(wall_clock.time()),
    Some((offset, name)),
    Some(dt.naive_utc().timestamp()),
  )
}
