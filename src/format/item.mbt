///|
/// A numeric field, formatted with a fixed zero-padded width.
pub(all) enum Numeric {
  Year
  Month
  Day
  Ordinal
  Hour
  Minute
  Second
  Nanosecond
} derive(Eq, @debug.Debug)

///|
pub extend Numeric with Eq::{equal}

///|
pub extend Numeric with Eq::{not_equal}

///|
pub extend Numeric with @debug.Debug::{to_repr}

///|
/// A non-numeric field resolved by name (weekday/month names, timezone
/// name/offset).
pub(all) enum Fixed {
  LongWeekdayName
  ShortWeekdayName
  TimezoneName
  TimezoneOffset
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
