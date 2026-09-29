///|
/// A numeric field. Most render at a fixed zero-padded width; `Hour12Blank`
/// space-pads instead, and `Timestamp` renders unpadded (a signed count of
/// seconds, not a calendar component).
pub(all) enum Numeric {
  Year
  Month
  Day
  Ordinal
  Hour
  Minute
  Second
  Nanosecond
  /// `%I`: the hour on a 12-hour clock, zero-padded (`01`..=`12`).
  Hour12
  /// `%l`: the hour on a 12-hour clock, space-padded (`" 1"`..=`"12"`).
  Hour12Blank
  /// `%s`: the number of non-leap seconds since the Unix epoch.
  Timestamp
  /// `%G`: the ISO 8601 week-based year (distinct from the calendar year
  /// near a year boundary; see `@core.IsoWeek`).
  IsoYear
  /// `%g`: `IsoYear` without its century, zero-padded to 2 digits.
  IsoYear2
  /// `%V`: the ISO 8601 week number (`01`..=`53`).
  IsoWeekNumber
} derive(Eq, @debug.Debug)

///|
pub extend Numeric with Eq::{equal}

///|
pub extend Numeric with Eq::{not_equal}

///|
pub extend Numeric with @debug.Debug::{to_repr}

///|
/// A non-numeric field resolved by name (weekday/month names, timezone
/// name/offset, am/pm marker).
pub(all) enum Fixed {
  LongWeekdayName
  ShortWeekdayName
  TimezoneName
  TimezoneOffset
  /// `%B`: the full month name, e.g. `"March"`.
  LongMonthName
  /// `%b`/`%h`: the abbreviated month name, e.g. `"Mar"`.
  ShortMonthName
  /// `%P`: `"am"`/`"pm"`, lowercase.
  AmPmLower
  /// `%p`: `"AM"`/`"PM"`, uppercase.
  AmPmUpper
} derive(Eq, @debug.Debug)

///|
pub extend Fixed with Eq::{equal}

///|
pub extend Fixed with Eq::{not_equal}

///|
pub extend Fixed with @debug.Debug::{to_repr}

///|
/// A single formatting/parsing item produced by `tokenize` from a
/// `%`-specifier format string.
pub(all) enum Item {
  Literal(String)
  Numeric(Numeric)
  Fixed(Fixed)
} derive(Eq, @debug.Debug)

///|
pub extend Item with Eq::{equal}

///|
pub extend Item with Eq::{not_equal}

///|
pub extend Item with @debug.Debug::{to_repr}
