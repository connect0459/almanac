# `format` package

strftime-style formatting and parsing for `core`/`tz` types. Import `connect0459/chrono/format` for `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, their `parse_*` counterparts, and dedicated RFC 3339 and RFC 2822 fast paths (`to_rfc3339`/`parse_rfc3339`, `to_rfc2822`/`parse_from_rfc2822`), and `parse_duration` for `TimeDelta`.

## Key functions

| Function | Description |
| :--- | :--- |
| `format_date`/`format_time`/`format_date_time` | Render a `NaiveDate`/`NaiveTime`/`NaiveDateTime` against a `%`-specifier format string |
| `format_date_time_tz` | Render a `DateTime[Tz]` in its local (wall-clock) representation, supporting `%Z`/`%z` |
| `parse_date`/`parse_time`/`parse_date_time` | Parse a string against a format string into a `NaiveDate`/`NaiveTime`/`NaiveDateTime` |
| `parse_date_time_tz` | Parse a string with a `%z` offset into a `DateTime[FixedOffset]`, interpreting the fields as local wall-clock time |
| `parse_date_time_in` | Parse a zone-less string and resolve it as wall-clock time in a given `TimeZone`, surfacing DST ambiguity as `MappedLocalTime` |
| `to_rfc3339`/`parse_rfc3339` | Dedicated RFC 3339 fast path, bypassing the specifier engine |
| `to_rfc2822`/`parse_from_rfc2822` | Dedicated RFC 2822 fast path (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`), bypassing the specifier engine |
| `parse_duration` | Reads a `TimeDelta` from Go-style text (`"1h30m"`, `"-1.5s"`, `"300ms"`); the inverse of `TimeDelta`'s `Show` |
| `rfc1123`/`kitchen`/`stamp`/`stamp_milli`/`stamp_micro`/`stamp_nano`/`date_only`/`time_only` | Named convenience format strings (Go `time` package layout equivalents) — pass one to `format_*`/`parse_*` like any other format string |

## Supported specifiers

| Specifier | Field | Description |
| :--- | :--- | :--- |
| `%Y` | Year | Variable-width, optionally signed on parse; zero-padded to 4 digits on format |
| `%m` | Month | Zero-padded, `01`..`12` |
| `%d` | Day | Zero-padded, `01`..`31` |
| `%j` | Ordinal | Day of year, zero-padded to 3 digits |
| `%H` | Hour | Zero-padded, `00`..`23` |
| `%M` | Minute | Zero-padded, `00`..`59` |
| `%S` | Second | Zero-padded, `00`..`60` (`60` on parse maps to a leap second) |
| `%f` | Nanosecond | Zero-padded to 9 digits |
| `%.f` | Dot-prefixed fractional second | The fewest of 3, 6 or 9 digits that represent the nanoseconds (`.500`, `.123456`, `.000000789`), matching `to_rfc3339`'s and `NaiveTime`'s `Show` fraction rendering; renders nothing when zero. On parse, optional — unlike every other specifier, absent input (no leading dot) leaves the nanosecond field untouched rather than raising |
| `%3f` | Fractional second, milliseconds | 3 digits, no leading dot, truncated (not rounded); mandatory on parse |
| `%6f` | Fractional second, microseconds | 6 digits, no leading dot; see `%3f` |
| `%9f` | Fractional second | 9 digits, no leading dot; identical to `%f` |
| `%A` | Long weekday name | e.g. `"Monday"` |
| `%a` | Short weekday name | e.g. `"Mon"` |
| `%B` | Long month name | e.g. `"March"`; on parse, resolves `%m`'s field directly |
| `%b`, `%h` | Short month name | e.g. `"Mar"`; on parse, resolves `%m`'s field directly |
| `%I` | Hour, 12-hour clock | Zero-padded, `01`..`12`; combines with `%p`/`%P` on parse (cross-checked against `%H`, if also present) |
| `%l` | Hour, 12-hour clock | Space-padded, `" 1"`..`"12"`; parses the same field as `%I`, tolerating a blank or zero leading digit |
| `%P` | am/pm marker, lowercase | `"am"`/`"pm"`; parses `%p`/`%P` case-insensitively either way |
| `%p` | am/pm marker, uppercase | `"AM"`/`"PM"`; see `%P` |
| `%s` | Unix timestamp | Format-only: the underlying UTC instant's seconds since the epoch (unaffected by `format_date_time_tz`'s local zone shift); raises `InputMismatch` on parse |
| `%G` | ISO week-based year | Zero-padded to 4 digits on format; on parse, an optionally-signed greedy field. With `%V` and a weekday, constructs the date via ISO week-date construction; otherwise cross-checked against the resolved date |
| `%g` | ISO week-based year, no century | Zero-padded to 2 digits; on parse, a lone `%g` uses the same pivot as `%y` (below 70 is 20xx, otherwise 19xx), and is cross-checked against `%G` when both are present |
| `%V` | ISO week number | Zero-padded, `01`..`53`; on parse, combined with `%G`/`%g` and a weekday, or else cross-checked against the resolved date |
| `%C` | Century | Zero-padded to 2 digits (`year / 100`); combines with `%y` on parse (`%y` alone is interpreted via the conventional two-digit-year pivot: `< 70` -> 20xx, `>= 70` -> 19xx); cross-checked against `%Y`, if also present |
| `%y` | Year without century | Zero-padded to 2 digits (`year % 100`); see `%C` |
| `%q` | Quarter | `1`..`4`, no padding; on parse, cross-checked against an already-determined date (a quarter alone can't determine a day, like `%A`/`%a`) |
| `%e` | Day, space-padded | `" 1"`..`"31"`; parses the same field as `%d`, tolerating a blank or zero leading digit |
| `%w` | Weekday number, Sunday-based | `0`..`6` (Sunday `0`); parses the same field as `%A`/`%a` |
| `%u` | Weekday number, Monday-based (ISO 8601) | `1`..`7` (Sunday `7`); parses the same field as `%A`/`%a` |
| `%U` | Week number, Sunday-based | Zero-padded, `00`..`53`; combined with a weekday (`%A`/`%a`/`%w`/`%u`) on parse to construct a date when no month/day/ordinal is given, mirroring `%j`'s role; cross-checked against an already-determined date otherwise |
| `%W` | Week number, Monday-based | Zero-padded, `00`..`53`; see `%U` |
| `%Z` | Timezone name | On parse, consumes one or more non-whitespace characters without validating them; every entry point discards the name except `parse_date_time_in`, which resolves it through the target zone; an empty name raises `InputMismatch` |
| `%z` | Timezone offset | `±HHMM`, no colon |
| `%:z` | Timezone offset, minutes | `±HH:MM`; on parse, the colon is mandatory (exactly its own rendered shape) |
| `%::z` | Timezone offset, seconds | `±HH:MM:SS`, always with seconds (unlike `FixedOffset`'s own `tz_name`, which only extends past minutes when they're nonzero); on parse, the seconds field is mandatory too |
| `%:::z` | Timezone offset, hours only | `±HH` — minutes and seconds are dropped entirely, not just omitted when zero; parses the same shape |
| `%#z` | Timezone offset, permissive | Parse-only (mirrors chrono, which panics if used to format): accepts `±HHMM`, `±HH:MM`, hours-only `±HH`, or `Z`/`z` for a zero offset, with any run of `:`/space/tab (or none) between the hour and minute digits; no seconds field |
| `%F` | `%Y-%m-%d` | Expands to that specifier sequence |
| `%T` | `%H:%M:%S` | Expands to that specifier sequence |
| `%D`, `%x` | `%m/%d/%y` | Expands to that specifier sequence (no locale support, so `%x` is identical to `%D`) |
| `%v` | `%e-%b-%Y` | VMS-style date, e.g. `" 5-Mar-2024"`; expands to that specifier sequence |
| `%R` | `%H:%M` | Expands to that specifier sequence; carries no seconds, so `parse_time` needs a separate `%S` to fully resolve a time (see `%r`/`%X` for a self-sufficient alternative) |
| `%X` | `%H:%M:%S` | Expands to that specifier sequence (identical to `%T`) |
| `%r` | `%I:%M:%S %p` | Expands to that specifier sequence |
| `%c` | `%a %b %e %H:%M:%S %Y` | ctime-style, e.g. `"Tue Mar  5 09:05:30 2024"`; expands to that specifier sequence |
| `%+` | RFC 3339 date-time | A whole `DateTime`, rendered/parsed via the dedicated `to_rfc3339`/`parse_rfc3339` fast path rather than a sequence of simpler specifiers (mirrors chrono); needs a date, time, and offset together, like `%Z`/`%z` |
| `%%` | Literal `%` | |
| `%-X` | No padding | Overrides `X`'s own default padding; `X` must resolve to a single bare `Numeric` specifier (not a `Fixed` one or a compound expansion like `%F`) other than `%f`/`%.f`/`%3f`/`%6f`/`%s` — chrono itself treats the fractional-second family as `Fixed`, and `%s` has no natural fixed width |
| `%0X` | Zero padding | See `%-X`; meaningful for a specifier that doesn't already zero-pad, e.g. `%0e` |
| `%_X` | Space padding | See `%-X`; meaningful for a specifier that doesn't already space-pad, e.g. `%_d` |

Padding flags only affect formatting. On parse, `%-X`/`%0X`/`%_X` behave exactly like bare `%X` (matching chrono, whose parser never reads a specifier's `Pad`).

## Quick start

Formatting and parsing a date against a custom format string:

```mbt check
///|
test {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  assert_eq(@format.format_date(date, "%Y-%m-%d"), "2024-02-29")
  assert_eq(@format.parse_date("2024-02-29", "%Y-%m-%d"), date)
}
```

Round-tripping a zone-aware `DateTime[Tz]` through `%Z`/`%z`:

```mbt check
///|
test {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(
    @format.format_date_time_tz(dt, "%F %T %z"),
    "2024-06-15 21:00:00 +0900",
  )
}
```

`to_rfc3339` renders fractional seconds with the fewest of 3, 6 or 9 digits that represent them, and a zero offset as `Z`; `parse_rfc3339` accepts any number of fractional digits:

```mbt check
///|
test {
  let naive = @core.NaiveDateTime::from_timestamp(0L, 500_000_000).unwrap()
  let dt = @tz.DateTime::from_utc(naive, @tz.FixedOffset::east(0).unwrap())
  assert_eq(@format.to_rfc3339(dt), "1970-01-01T00:00:00.500Z")
  assert_eq(@format.parse_rfc3339("1970-01-01T00:00:00.5Z"), dt)
  assert_eq(@format.parse_rfc3339("1970-01-01T00:00:00.500Z"), dt)
}
```

## API reference

### Formatting

| Function | Signature | Description |
| :--- | :--- | :--- |
| `format_date(NaiveDate, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for a time-of-day specifier (`%H`/`%M`/`%S`/`%f`/`%I`/`%l`/`%P`/`%p`) |
| `format_time(NaiveTime, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for a date specifier (`%Y`/`%m`/`%d`/`%j`/`%A`/`%a`/`%B`/`%b`/`%h`/`%G`/`%g`/`%V`/`%C`/`%y`/`%q`/`%e`/`%w`/`%u`/`%U`/`%W`) or `%s` (no absolute instant to draw from) |
| `format_date_time(NaiveDateTime, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for `%Z`/`%z`/`%:z`/`%::z`/`%:::z` (no zone to draw from) or `%#z` (parse-only, never renders) |
| `format_date_time_tz(DateTime[Tz], String)` *(Tz : TimeZone)* | `-> String raise ParseError` | Render in local (wall-clock) representation; `%Z` renders `tz.tz_name()`, `%z` the numeric offset, `%s` the underlying UTC instant's timestamp |

### Parsing

| Function | Signature | Description |
| :--- | :--- | :--- |
| `parse_date(String, String)` | `-> NaiveDate raise ParseError` | Parse against a format string's date fields (`%Y` plus `%m`/`%d` or `%j`) |
| `parse_time(String, String)` | `-> NaiveTime raise ParseError` | Parse against a format string's time-of-day fields (`%H`/`%M`/`%S`, `%f` optional) |
| `parse_date_time(String, String)` | `-> NaiveDateTime raise ParseError` | Parse against a format string's date and time-of-day fields together |
| `parse_date_time_tz(String, String)` | `-> DateTime[FixedOffset] raise ParseError` | Parse against a format string's date, time-of-day, and `%z` fields, interpreting them as the zone's local wall-clock reading |
| `parse_date_time_in[Tz : TimeZone](String, String, Tz)` | `-> MappedLocalTime[DateTime[Tz]] raise ParseError` | Parse a zone-less format's date and time-of-day fields and resolve the reading in `tz` (`Ambiguous` in a DST fold, `Absent` in a gap); raises `InconsistentFields` if the format yields an offset (`%z`, `%+`, ...); a `%Z` name the zone recognizes fixes the offset (Go's `ParseInLocation`), so an abbreviation like `EDT` resolves a DST fold to `Single`, and an unrecognized name is ignored |

### RFC 3339 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc3339(DateTime[Tz])` *(Tz : TimeZone)* | `-> String` | Renders `YYYY-MM-DDTHH:MM:SS[.fraction](Z\|±HH:MM)`; a zero offset renders as `Z`, fractional seconds only when nonzero, with the fewest of 3, 6 or 9 digits that represent them, a leap second as `:60`. Total — never raises |
| `parse_rfc3339(String)` | `-> DateTime[FixedOffset] raise ParseError` | Strict RFC 3339 parsing (`T`/`t` and `Z`/`z` case-insensitive; a fractional-second field beyond 9 digits is truncated, not rejected); raises `InvalidRfc3339` on any mismatch |

### RFC 2822 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc2822(DateTime[Tz])` *(Tz : TimeZone)* | `-> String raise ParseError` | Renders `"<short weekday>, <day> <short month> <year> <HH>:<MM>:<SS> ±HHMM"` (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`); the day is unpadded (one or two digits, never a leading zero), unlike this package's other numeric fields. Raises `InvalidRfc2822` if the year is outside RFC 2822's own `0..=9999` range — unlike `to_rfc3339`, not total |
| `parse_from_rfc2822(String)` | `-> DateTime[FixedOffset] raise ParseError` | Strict RFC 2822 parsing: only the exact shape `to_rfc2822` renders (day-of-week and seconds mandatory, single-space separators, a 4-digit year, a numeric `±HHMM` offset). Unlike chrono's own parser, does *not* support RFC 2822's "obsolete format" — optional day-of-week, arbitrary/folding whitespace, 2-/3-digit year windowing, named legacy zones (`GMT`, `EST`, ...), or parenthesized comments. Raises `InvalidRfc2822` on any mismatch |
| `parse_duration(String)` | `-> TimeDelta raise ParseError` | Parses one or more `<number><unit>` components with an optional leading sign (`"1h30m"`, `"-1.5s"`, `"300ms"`, `".5s"`, `"1.5h"`). Units are `ns`, `us` (also `µs` U+00B5 and `μs` U+03BC), `ms`, `s`, `m`, `h`, case-sensitive, with hours the largest (no days/weeks); components are summed. A bare `"0"` (optionally signed) needs no unit. Fractional digits beyond the ninth, and precision finer than a nanosecond, are truncated toward zero. The inverse of `TimeDelta`'s `Show`. Raises `InvalidDuration` for malformed input or a value outside `TimeDelta`'s range |

### Named layouts

Convenience format-string constants, mirroring Go's `time` package layouts (translated into this project's `%`-specifier style, not copied as Go's reference-time-layout syntax). Each is just a `String` — pass one to `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, or their `parse_*` counterparts, like any other format string.

| Constant | Format string | Go equivalent | Example |
| :--- | :--- | :--- | :--- |
| `rfc1123` | `"%a, %d %b %Y %H:%M:%S %Z"` | `RFC1123` | `"Tue, 05 Mar 2024 09:05:03 UTC"` |
| `kitchen` | `"%-I:%M%p"` | `Kitchen` | `"9:05AM"` |
| `stamp` | `"%b %e %H:%M:%S"` | `Stamp` | `"Mar  5 09:05:03"` |
| `stamp_milli` | `"%b %e %H:%M:%S.%3f"` | `StampMilli` | `"Mar  5 09:05:03.123"` |
| `stamp_micro` | `"%b %e %H:%M:%S.%6f"` | `StampMicro` | `"Mar  5 09:05:03.123456"` |
| `stamp_nano` | `"%b %e %H:%M:%S.%9f"` | `StampNano` | `"Mar  5 09:05:03.123456789"` |
| `date_only` | `"%F"` | `DateOnly` | `"2024-03-05"` |
| `time_only` | `"%T"` | `TimeOnly` | `"09:05:03"` |

`kitchen` (no seconds), and the `stamp*` family (no year) don't carry enough fields to round-trip through the matching `parse_*` function on their own — matching Go's own `Stamp` family, meant for display alongside separately-known context. Only `date_only`/`time_only` are self-sufficient for parsing.

### `tokenize`

| Function | Signature | Description |
| :--- | :--- | :--- |
| `tokenize(String)` | `-> Array[Item] raise ParseError` | Parses a `%`-specifier format string into a sequence of `Item`s; raises `UnknownSpecifier`/`TrailingPercent` on a malformed format string. Not usually needed directly — `format_*`/`parse_*` call it internally |

### `Item`, `Numeric`, `Fixed`, `PadMode`

The token types produced by `tokenize`.

```mbt nocheck
///|
pub(all) enum Item {
  Literal(String)
  Numeric(Numeric)
  Fixed(Fixed)
  Rfc3339
  PaddedNumeric(Numeric, PadMode)
}

///|
pub(all) enum PadMode {
  NoPad
  ZeroPad
  SpacePad
}

///|
pub(all) enum Numeric {
  Year
  Month
  Day
  Ordinal
  Hour
  Minute
  Second
  Nanosecond
  Hour12
  Hour12Blank
  Timestamp
  IsoYear
  IsoYear2
  IsoWeekNumber
  Century
  YearMod100
  Quarter
  DayBlank
  WeekdayNumberSunday0
  WeekdayNumberMonday1
  WeekSunday
  WeekMonday
  DotFraction
  Nanosecond3
  Nanosecond6
}

///|
pub(all) enum Fixed {
  LongWeekdayName
  ShortWeekdayName
  TimezoneName
  TimezoneOffset
  LongMonthName
  ShortMonthName
  AmPmLower
  AmPmUpper
  TimezoneOffsetColonMinutes
  TimezoneOffsetColonSeconds
  TimezoneOffsetColonHours
  TimezoneOffsetPermissive
}
```

`Item`, `Numeric`, `Fixed`, and `PadMode` each also implement `Eq`.

### `ParseError`

| Variant | Raised when |
| :--- | :--- |
| `UnknownSpecifier(Char)` | `tokenize` encounters an unrecognized `%`-specifier |
| `TrailingPercent` | A format string ends with a bare `%` |
| `MissingField(Item)` | A `format_*` call is asked to render a specifier its input type can't supply (e.g. `%Z` via `format_date_time`) |
| `InvalidRfc3339` | `parse_rfc3339` fails to match the RFC 3339 grammar |
| `InvalidRfc2822` | `to_rfc2822`'s year is outside `0..=9999`, or `parse_from_rfc2822` fails to match this package's (strict) RFC 2822 grammar |
| `InvalidDuration` | `parse_duration`'s input is malformed (no digits, missing or unknown unit, misplaced sign, stray characters) or its value is outside `TimeDelta`'s representable range |
| `IncompleteFields` | A `parse_*` call resolves fields that never populate a required value (e.g. no year) |
| `InconsistentFields` | Two populated fields disagree, or don't jointly form a valid value (e.g. `%j` contradicting `%m`/`%d`, or an out-of-range calendar date) |
| `InputMismatch` | Literal or specifier text fails to match the input, input remains unconsumed, or a format-only specifier (`%s`) is parsed |

`ParseError` also implements `Eq` and `Show`, which renders a one-line message per variant (e.g. `input does not match the format`; `MissingField` appends the item's `Debug` form).
