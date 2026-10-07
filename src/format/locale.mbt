///|
/// A locale's names and layouts for the text-bearing specifiers: month and
/// weekday names (`%B`, `%b`, `%A`, `%a`), the day-period markers (`%p`,
/// `%P`) and the layouts `%x`, `%X`, `%c` and `%r` expand to. Immutable;
/// build one with `Locale::new`, or use `Locale::posix`.
pub struct Locale {
  priv long_months : Array[String]
  priv short_months : Array[String]
  priv long_weekdays : Array[String]
  priv short_weekdays : Array[String]
  priv am : String
  priv pm : String
  priv date_format : String
  priv time_format : String
  priv date_time_format : String
  priv time_format_12h : String
}

///|
/// Why `Locale::new` rejected its arguments.
pub(all) suberror LocaleError {
  /// The month names are not twelve non-empty names per form, or one name
  /// belongs to two different months.
  InvalidMonthNames
  /// The weekday names are not seven non-empty names per form, or one name
  /// belongs to two different weekdays.
  InvalidWeekdayNames
  /// A day-period name is empty, or the two are equal ignoring ASCII case.
  InvalidAmPmNames
  /// A layout is empty, is not a valid format string, or uses `%x`, `%X`,
  /// `%c` or `%r`, which would make it expand into itself.
  InvalidPattern(String)
} derive(Eq, @debug.Debug)

///|
pub extend LocaleError with Eq::{equal}

///|
pub extend LocaleError with Eq::{not_equal}

///|
pub extend LocaleError with @debug.Debug::{to_repr}

///|
pub impl Show for LocaleError with fn output(self, logger) {
  let message = match self {
    InvalidMonthNames =>
      "a locale needs twelve distinct non-empty month names in each form"
    InvalidWeekdayNames =>
      "a locale needs seven distinct non-empty weekday names in each form"
    InvalidAmPmNames => "a locale needs two distinct non-empty day-period names"
    InvalidPattern(pattern) => "invalid locale layout: \{pattern}"
  }
  logger.write_string(message)
}

///|
pub extend LocaleError with Show::{to_string, output}

///|
fn ascii_lower_string(s : String) -> String {
  let out = StringBuilder()
  for c in s {
    out.write_char(ascii_lower(c))
  }
  out.to_string()
}

///|
fn names_are_distinct(
  long : Array[String],
  short : Array[String],
  count : Int,
) -> Bool {
  if long.length() != count || short.length() != count {
    return false
  }
  let seen : Map[String, Int] = Map([])
  for form in [long, short] {
    for i, name in form {
      if name == "" {
        return false
      }
      match seen.get(name) {
        Some(owner) => if owner != i { return false }
        None => seen[name] = i
      }
    }
  }
  true
}

///|
fn mentions_locale_dependent_specifier(pattern : String) -> Bool {
  let chars = pattern.to_array()
  let n = chars.length()
  for i = 0 {
    if i >= n {
      break false
    }
    if chars[i] != '%' || i + 1 >= n {
      continue i + 1
    }
    let next = match chars[i + 1] {
      '-' | '0' | '_' => if i + 2 < n { chars[i + 2] } else { '%' }
      c => c
    }
    if next == '%' && chars[i + 1] == '%' {
      continue i + 2
    }
    if next == 'x' || next == 'X' || next == 'c' || next == 'r' {
      break true
    }
    continue i + 2
  }
}

///|
fn check_pattern(pattern : String) -> Unit raise LocaleError {
  if pattern == "" || mentions_locale_dependent_specifier(pattern) {
    raise InvalidPattern(pattern)
  }
  try tokenize(pattern) |> ignore catch {
    _ => raise InvalidPattern(pattern)
  } noraise {
    _ => ()
  }
}

///|
/// Builds a locale. Month names run from January and weekday names from
/// Monday. A month or weekday name is matched exactly on parse; a day-period
/// name is matched ignoring ASCII case. The four layouts are the expansions
/// of `%x` (date), `%X` (time), `%c` (date and time) and `%r` (12-hour time);
/// each is non-empty and may use any specifier except those four.
///
/// # Errors
/// `InvalidMonthNames`, `InvalidWeekdayNames`, `InvalidAmPmNames` or
/// `InvalidPattern` when the matching argument breaks the rules above.
pub fn Locale::new(
  long_months~ : Array[String],
  short_months~ : Array[String],
  long_weekdays~ : Array[String],
  short_weekdays~ : Array[String],
  am~ : String,
  pm~ : String,
  date_format~ : String,
  time_format~ : String,
  date_time_format~ : String,
  time_format_12h~ : String,
) -> Locale raise LocaleError {
  if !names_are_distinct(long_months, short_months, 12) {
    raise InvalidMonthNames
  }
  if !names_are_distinct(long_weekdays, short_weekdays, 7) {
    raise InvalidWeekdayNames
  }
  if am == "" || pm == "" || ascii_lower_string(am) == ascii_lower_string(pm) {
    raise InvalidAmPmNames
  }
  for pattern in [date_format, time_format, date_time_format, time_format_12h] {
    check_pattern(pattern)
  }
  {
    long_months: long_months.copy(),
    short_months: short_months.copy(),
    long_weekdays: long_weekdays.copy(),
    short_weekdays: short_weekdays.copy(),
    am,
    pm,
    date_format,
    time_format,
    date_time_format,
    time_format_12h,
  }
}

///|
let posix_locale : Locale = {
  long_months: [
    "January", "February", "March", "April", "May", "June", "July", "August", "September",
    "October", "November", "December",
  ],
  short_months: [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov",
    "Dec",
  ],
  long_weekdays: [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
  ],
  short_weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
  am: "AM",
  pm: "PM",
  date_format: "%m/%d/%y",
  time_format: "%H:%M:%S",
  date_time_format: "%a %b %e %H:%M:%S %Y",
  time_format_12h: "%I:%M:%S %p",
}

///|
/// The C locale: English names, `AM`/`PM`, and the layouts `%x` = `%m/%d/%y`,
/// `%X` = `%H:%M:%S`, `%c` = `%a %b %e %H:%M:%S %Y` and
/// `%r` = `%I:%M:%S %p`. What every `locale` argument defaults to.
pub fn Locale::posix() -> Locale {
  posix_locale
}

///|
/// The name of `month`: the short form when `short` is true.
pub fn Locale::month_name(
  self : Locale,
  month : @core.Month,
  short? : Bool = false,
) -> String {
  let names = if short { self.short_months } else { self.long_months }
  names[month.number() - 1]
}

///|
/// The name of `weekday`: the short form when `short` is true.
pub fn Locale::weekday_name(
  self : Locale,
  weekday : @core.Weekday,
  short? : Bool = false,
) -> String {
  let names = if short { self.short_weekdays } else { self.long_weekdays }
  names[weekday.days_since(@core.Mon)]
}

///|
/// The day-period name: the afternoon one when `is_pm` is true.
pub fn Locale::am_pm(self : Locale, is_pm : Bool) -> String {
  if is_pm {
    self.pm
  } else {
    self.am
  }
}

///|
/// The layout `%x` expands to.
pub fn Locale::date_format(self : Locale) -> String {
  self.date_format
}

///|
/// The layout `%X` expands to.
pub fn Locale::time_format(self : Locale) -> String {
  self.time_format
}

///|
/// The layout `%c` expands to.
pub fn Locale::date_time_format(self : Locale) -> String {
  self.date_time_format
}

///|
/// The layout `%r` expands to.
pub fn Locale::time_format_12h(self : Locale) -> String {
  self.time_format_12h
}
