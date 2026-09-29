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
  /// `%C`: the calendar year divided by 100, zero-padded to 2 digits.
  Century
  /// `%y`: the calendar year modulo 100, zero-padded to 2 digits.
  YearMod100
  /// `%q`: the quarter (`1`..=`4`).
  Quarter
  /// `%e`: the day of the month, space-padded (`" 1"`..=`"31"`).
  DayBlank
  /// `%w`: the weekday as a number, Sunday-based (`0`..=`6`, Sunday `0`).
  WeekdayNumberSunday0
  /// `%u`: the weekday as a number, Monday-based (`1`..=`7`, ISO 8601).
  WeekdayNumberMonday1
  /// `%U`: the week number of the year, Sunday-based (`00`..=`53`); days
  /// before the year's first Sunday are week `00`.
  WeekSunday
  /// `%W`: the week number of the year, Monday-based (`00`..=`53`); days
  /// before the year's first Monday are week `00`.
  WeekMonday
  /// `%.f`: a dot-prefixed fractional second, trimmed to its minimal
  /// significant digits (mirrors `to_rfc3339`'s fraction rendering); on
  /// parse, optional — absent input (no leading dot) simply leaves the
  /// nanosecond field untouched rather than raising, unlike every other
  /// specifier.
  DotFraction
  /// `%3f`: a fractional second truncated to 3 digits (milliseconds), no
  /// leading dot. Unlike `DotFraction`, mandatory on parse.
  Nanosecond3
  /// `%6f`: a fractional second truncated to 6 digits (microseconds), no
  /// leading dot. Mandatory on parse, like `Nanosecond3`.
  Nanosecond6
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
  /// `%:z`: `±HH:MM`, always with minutes, never seconds.
  TimezoneOffsetColonMinutes
  /// `%::z`: `±HH:MM:SS`, always with seconds (unlike `TimezoneOffset`'s
  /// `tz`-package sibling `FixedOffset::tz_name`, which only extends to
  /// seconds when they're nonzero).
  TimezoneOffsetColonSeconds
  /// `%:::z`: `±HH`, hours only — minutes and seconds are dropped, not
  /// just omitted when zero.
  TimezoneOffsetColonHours
  /// `%#z`: parse-only (mirrors chrono, which panics if used to format).
  /// Accepts whichever shape is present: `±HHMM`, `±HH:MM`, hours-only
  /// `±HH`, or `Z`/`z` for a zero offset, with any run of `:`/space/tab
  /// allowed (or omitted) between the hour and minute digits. No
  /// seconds component — matches chrono's own `%#z`, whose shared
  /// parsing engine doesn't read one either.
  TimezoneOffsetPermissive
} derive(Eq, @debug.Debug)

///|
pub extend Fixed with Eq::{equal}

///|
pub extend Fixed with Eq::{not_equal}

///|
pub extend Fixed with @debug.Debug::{to_repr}

///|
/// A padding-flag override (`%-`/`%0`/`%_`) for a single numeric
/// specifier: `NoPad` (`%-`) renders with no padding at all, `ZeroPad`
/// (`%0`) forces zero-padding (redundant for a specifier that already
/// zero-pads by default, but meaningful for one like `%e` that normally
/// space-pads), `SpacePad` (`%_`) forces space-padding. Only affects
/// rendering — parsing ignores it entirely and behaves exactly like the
/// unwrapped specifier, matching chrono (its `Item::Numeric`'s `Pad`
/// field is likewise unread by its parser).
pub(all) enum PadMode {
  NoPad
  ZeroPad
  SpacePad
} derive(Eq, @debug.Debug)

///|
pub extend PadMode with Eq::{equal}

///|
pub extend PadMode with Eq::{not_equal}

///|
pub extend PadMode with @debug.Debug::{to_repr}

///|
/// A single formatting/parsing item produced by `tokenize` from a
/// `%`-specifier format string.
pub(all) enum Item {
  Literal(String)
  Numeric(Numeric)
  Fixed(Fixed)
  /// `%+`: a whole RFC 3339 date-time, rendered/parsed via the dedicated
  /// fast path (`to_rfc3339`/`parse_rfc3339`) rather than as a sequence
  /// of simpler items — chrono itself treats `%+` the same way.
  Rfc3339
  /// `%-X`/`%0X`/`%_X`: a single numeric specifier `X` with its default
  /// padding overridden. Only produced when `X` resolves to a bare
  /// `Numeric` item on its own (not a `Fixed` item or a multi-item
  /// compound expansion like `%F`) — matches chrono, which only allows a
  /// padding flag on its own `Numeric`-carrying items. Also excludes the
  /// fractional-second family (`%f`/`%.f`/`%3f`/`%6f`), which are
  /// `Numeric` in this project for implementation convenience but map to
  /// `Fixed` in chrono (so chrono itself rejects a flag on them), and
  /// `%s` (`Timestamp`), which has no natural fixed width to override.
  PaddedNumeric(Numeric, PadMode)
} derive(Eq, @debug.Debug)

///|
pub extend Item with Eq::{equal}

///|
pub extend Item with Eq::{not_equal}

///|
pub extend Item with @debug.Debug::{to_repr}
