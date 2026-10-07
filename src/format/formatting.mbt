///|
fn floor_div(a : Int, b : Int) -> Int {
  let q = a / b
  if a % b != 0 && (a < 0) != (b < 0) {
    q - 1
  } else {
    q
  }
}

///|
fn floor_mod(a : Int, b : Int) -> Int {
  a - floor_div(a, b) * b
}

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
/// Renders a calendar or ISO year as `%Y`/`%G` do: zero-padded to `width`
/// digits after a `-` for a negative year, and with an explicit `+` beyond
/// `9999`, as ISO 8601 requires for a year past four digits.
fn year_text(year : Int, width : Int) -> String {
  if year > 9999 {
    "+" + pad_int(year, width)
  } else {
    pad_int(year, width)
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
/// The raw value and default (zero-padded) width for a `Numeric` kind
/// eligible for a `PaddedNumeric` override — every kind except the
/// fractional-second family and `Timestamp` (see `PaddedNumeric`'s own
/// doc comment for why those are excluded). Raises `MissingField` if the
/// date/time context `kind` needs isn't present.
///
/// The excluded kinds still need a match arm (`Numeric` is one type, and
/// `render`'s existing bare-`Numeric` arms already handle them on their
/// own), but `tokenize` never constructs `PaddedNumeric` with one of
/// them, so that arm is unreachable in practice.
fn numeric_value(
  kind : Numeric,
  date : @core.NaiveDate?,
  time : @core.NaiveTime?,
  item : Item,
) -> (Int, Int) raise FormatError {
  match kind {
    Year =>
      match date {
        Some(d) => (d.year(), 4)
        None => raise MissingField(item)
      }
    Month =>
      match date {
        Some(d) => (d.month().number(), 2)
        None => raise MissingField(item)
      }
    Day =>
      match date {
        Some(d) => (d.day(), 2)
        None => raise MissingField(item)
      }
    Ordinal =>
      match date {
        Some(d) => (d.ordinal(), 3)
        None => raise MissingField(item)
      }
    Hour =>
      match time {
        Some(t) => (t.hour(), 2)
        None => raise MissingField(item)
      }
    Minute =>
      match time {
        Some(t) => (t.minute(), 2)
        None => raise MissingField(item)
      }
    Second =>
      match time {
        Some(t) => (t.second() + t.nanosecond() / 1_000_000_000, 2)
        None => raise MissingField(item)
      }
    Hour12 =>
      match time {
        Some(t) => {
          let hour = t.hour12().hour()
          (hour, 2)
        }
        None => raise MissingField(item)
      }
    Hour12Blank =>
      match time {
        Some(t) => {
          let hour = t.hour12().hour()
          (hour, 2)
        }
        None => raise MissingField(item)
      }
    HourBlank =>
      match time {
        Some(t) => (t.hour(), 2)
        None => raise MissingField(item)
      }
    IsoYear =>
      match date {
        Some(d) => (d.iso_week().year(), 4)
        None => raise MissingField(item)
      }
    IsoYearMod100 =>
      match date {
        Some(d) => (floor_mod(d.iso_week().year(), 100), 2)
        None => raise MissingField(item)
      }
    IsoWeekNumber =>
      match date {
        Some(d) => (d.iso_week().week(), 2)
        None => raise MissingField(item)
      }
    Century =>
      match date {
        Some(d) => (floor_div(d.year(), 100), 2)
        None => raise MissingField(item)
      }
    YearMod100 =>
      match date {
        Some(d) => (floor_mod(d.year(), 100), 2)
        None => raise MissingField(item)
      }
    Quarter =>
      match date {
        Some(d) => (d.quarter(), 1)
        None => raise MissingField(item)
      }
    DayBlank =>
      match date {
        Some(d) => (d.day(), 2)
        None => raise MissingField(item)
      }
    WeekdayNumberSunday0 =>
      match date {
        Some(d) => (d.weekday().num_days_from_sunday(), 1)
        None => raise MissingField(item)
      }
    WeekdayNumberMonday1 =>
      match date {
        Some(d) => (d.weekday().number_from_monday(), 1)
        None => raise MissingField(item)
      }
    WeekSunday =>
      match date {
        Some(d) =>
          (week_number(d.ordinal(), d.weekday().num_days_from_sunday()), 2)
        None => raise MissingField(item)
      }
    WeekMonday =>
      match date {
        Some(d) =>
          (week_number(d.ordinal(), d.weekday().num_days_from_monday()), 2)
        None => raise MissingField(item)
      }
    Nanosecond9
    | DotFraction
    | Nanosecond3
    | Nanosecond6
    | DotNanosecond3
    | DotNanosecond6
    | DotNanosecond9
    | Timestamp => raise MissingField(item)
  }
}

///|
fn render_padded(value : Int, default_width : Int, mode : PadMode) -> String {
  match mode {
    NoPad => value.to_string()
    ZeroPad => pad_int(value, default_width)
    SpacePad => pad_int_blank(value, default_width)
  }
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
/// Renders `%::z`'s `±HH:MM:SS`, always including seconds (unlike
/// `FixedOffset::zone_name`, in `tz`, which only extends past minutes when
/// they're nonzero).
fn format_offset_colon_seconds(secs : Int) -> String {
  let sign = if secs < 0 { "-" } else { "+" }
  let magnitude = if secs < 0 { -secs } else { secs }
  let hours = magnitude / 3600
  let minutes = magnitude % 3600 / 60
  let seconds = magnitude % 60
  sign +
  pad_int(hours, 2) +
  ":" +
  pad_int(minutes, 2) +
  ":" +
  pad_int(seconds, 2)
}

///|
/// Renders `%:::z`'s `±HH`: minutes and seconds are dropped entirely, not
/// just omitted when zero.
fn format_offset_hours_only(secs : Int) -> String {
  let sign = if secs < 0 { "-" } else { "+" }
  let magnitude = if secs < 0 { -secs } else { secs }
  sign + pad_int(magnitude / 3600, 2)
}

///|
fn render(
  items : Array[Item],
  date : @core.NaiveDate?,
  time : @core.NaiveTime?,
  tz_info : (Int, String)?,
  timestamp : Int64?,
) -> String raise FormatError {
  let out = StringBuilder()
  for item in items {
    match item {
      Literal(s) => out.write_string(s)
      PaddedNumeric(kind, mode) => {
        let (value, width) = numeric_value(kind, date, time, item)
        let text = render_padded(value, width, mode)
        match kind {
          Year | IsoYear if value > 9999 => out.write_string("+" + text)
          _ => out.write_string(text)
        }
      }
      Rfc3339 =>
        match (date, time, tz_info) {
          (Some(d), Some(t), Some((offset, _))) =>
            out.write_string(render_rfc3339(d, t, offset))
          _ => raise MissingField(item)
        }
      Rfc2822 =>
        match (date, time, tz_info) {
          (Some(d), Some(t), Some((offset, _))) =>
            out.write_string(render_rfc2822(d, t, offset))
          _ => raise MissingField(item)
        }
      Numeric(Year) =>
        match date {
          Some(d) => out.write_string(year_text(d.year(), 4))
          None => raise MissingField(item)
        }
      Numeric(Month) =>
        match date {
          Some(d) => out.write_string(pad_int(d.month().number(), 2))
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
      Numeric(Nanosecond9) =>
        match time {
          Some(t) =>
            out.write_string(pad_int(t.nanosecond() % 1_000_000_000, 9))
          None => raise MissingField(item)
        }
      Numeric(DotFraction) =>
        match time {
          Some(t) =>
            out.write_string(
              format_fraction_auto(t.nanosecond() % 1_000_000_000),
            )
          None => raise MissingField(item)
        }
      Numeric(Nanosecond3) =>
        match time {
          Some(t) =>
            out.write_string(
              pad_int(t.nanosecond() % 1_000_000_000 / 1_000_000, 3),
            )
          None => raise MissingField(item)
        }
      Numeric(Nanosecond6) =>
        match time {
          Some(t) =>
            out.write_string(pad_int(t.nanosecond() % 1_000_000_000 / 1_000, 6))
          None => raise MissingField(item)
        }
      Numeric(DotNanosecond3) =>
        match time {
          Some(t) =>
            out.write_string(
              "." + pad_int(t.nanosecond() % 1_000_000_000 / 1_000_000, 3),
            )
          None => raise MissingField(item)
        }
      Numeric(DotNanosecond6) =>
        match time {
          Some(t) =>
            out.write_string(
              "." + pad_int(t.nanosecond() % 1_000_000_000 / 1_000, 6),
            )
          None => raise MissingField(item)
        }
      Numeric(DotNanosecond9) =>
        match time {
          Some(t) =>
            out.write_string("." + pad_int(t.nanosecond() % 1_000_000_000, 9))
          None => raise MissingField(item)
        }
      Fixed(LongWeekdayName) =>
        match date {
          Some(d) => out.write_string(d.weekday().name())
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
      Fixed(TimezoneOffsetColonMinutes) =>
        match tz_info {
          Some((offset, _)) => out.write_string(format_offset_colon(offset))
          None => raise MissingField(item)
        }
      Fixed(TimezoneOffsetColonSeconds) =>
        match tz_info {
          Some((offset, _)) =>
            out.write_string(format_offset_colon_seconds(offset))
          None => raise MissingField(item)
        }
      Fixed(TimezoneOffsetColonHours) =>
        match tz_info {
          Some((offset, _)) =>
            out.write_string(format_offset_hours_only(offset))
          None => raise MissingField(item)
        }
      Fixed(TimezoneOffsetPermissive) => raise ParseOnly(item)
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
            let is_pm = t.hour12().is_pm()
            out.write_string(if is_pm { "pm" } else { "am" })
          }
          None => raise MissingField(item)
        }
      Fixed(AmPmUpper) =>
        match time {
          Some(t) => {
            let is_pm = t.hour12().is_pm()
            out.write_string(if is_pm { "PM" } else { "AM" })
          }
          None => raise MissingField(item)
        }
      Numeric(Hour12) =>
        match time {
          Some(t) => {
            let hour = t.hour12().hour()
            out.write_string(pad_int(hour, 2))
          }
          None => raise MissingField(item)
        }
      Numeric(Hour12Blank) =>
        match time {
          Some(t) => {
            let hour = t.hour12().hour()
            out.write_string(pad_int_blank(hour, 2))
          }
          None => raise MissingField(item)
        }
      Numeric(HourBlank) =>
        match time {
          Some(t) => out.write_string(pad_int_blank(t.hour(), 2))
          None => raise MissingField(item)
        }
      Numeric(Timestamp) =>
        match timestamp {
          Some(ts) => out.write_string(ts.to_string())
          None => raise MissingField(item)
        }
      Numeric(IsoYear) =>
        match date {
          Some(d) => out.write_string(year_text(d.iso_week().year(), 4))
          None => raise MissingField(item)
        }
      Numeric(IsoYearMod100) =>
        match date {
          Some(d) =>
            out.write_string(pad_int(floor_mod(d.iso_week().year(), 100), 2))
          None => raise MissingField(item)
        }
      Numeric(IsoWeekNumber) =>
        match date {
          Some(d) => out.write_string(pad_int(d.iso_week().week(), 2))
          None => raise MissingField(item)
        }
      Numeric(Century) =>
        match date {
          Some(d) => out.write_string(pad_int(floor_div(d.year(), 100), 2))
          None => raise MissingField(item)
        }
      Numeric(YearMod100) =>
        match date {
          Some(d) => out.write_string(pad_int(floor_mod(d.year(), 100), 2))
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
/// Renders `date` against `items`, a sequence already produced by
/// `tokenize` (or built by hand), so a format string reused for many values
/// is tokenized once. Same as `format_date` otherwise.
pub fn format_date_items(
  date : @core.NaiveDate,
  items : Array[Item],
) -> String raise FormatError {
  render(items, Some(date), None, None, None)
}

///|
/// Renders `time` against `items`; see `format_date_items`.
pub fn format_time_items(
  time : @core.NaiveTime,
  items : Array[Item],
) -> String raise FormatError {
  render(items, None, Some(time), None, None)
}

///|
/// Renders `dt` against `items`; see `format_date_items`.
pub fn format_date_time_items(
  dt : @core.NaiveDateTime,
  items : Array[Item],
) -> String raise FormatError {
  render(items, Some(dt.date()), Some(dt.time()), None, Some(dt.timestamp()))
}

///|
/// Renders a zone-aware `dt` against `items`; see `format_date_items` and
/// `format_date_time_tz`.
pub fn[Tz : @tz.TimeZone] format_date_time_tz_items(
  dt : @tz.DateTime[Tz],
  items : Array[Item],
) -> String raise FormatError {
  let wall_clock = dt.naive_local()
  let name = dt.timezone().zone_name(dt.naive_utc())
  let offset = dt.offset().local_minus_utc()
  render(
    items,
    Some(wall_clock.date()),
    Some(wall_clock.time()),
    Some((offset, name)),
    Some(dt.naive_utc().timestamp()),
  )
}

///|
pub fn format_date(
  date : @core.NaiveDate,
  fmt : String,
) -> String raise FormatError {
  format_date_items(date, tokenize(fmt))
}

///|
pub fn format_time(
  time : @core.NaiveTime,
  fmt : String,
) -> String raise FormatError {
  format_time_items(time, tokenize(fmt))
}

///|
pub fn format_date_time(
  dt : @core.NaiveDateTime,
  fmt : String,
) -> String raise FormatError {
  format_date_time_items(dt, tokenize(fmt))
}

///|
/// Renders a zone-aware `DateTime[Tz]` against `fmt`, in its local
/// (wall-clock) representation. `%Z` renders `tz.zone_name()`; `%z` renders
/// the numeric offset, strftime-style (`+HHMM`, no colon). `%s` renders
/// the underlying UTC instant's timestamp, unaffected by the local zone
/// shift applied to every other field.
pub fn[Tz : @tz.TimeZone] format_date_time_tz(
  dt : @tz.DateTime[Tz],
  fmt : String,
) -> String raise FormatError {
  format_date_time_tz_items(dt, tokenize(fmt))
}
