# `format` package

strftime-style formatting and parsing for `core`/`tz` types. Import `connect0459/chrono/format` for `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, their `parse_*` counterparts, and a dedicated RFC 3339 fast path (`to_rfc3339`/`parse_rfc3339`).

## Key functions

| Function | Description |
| :--- | :--- |
| `format_date`/`format_time`/`format_date_time` | Render a `NaiveDate`/`NaiveTime`/`NaiveDateTime` against a `%`-specifier format string |
| `format_date_time_tz` | Render a `DateTime[Tz]` in its local (wall-clock) representation, supporting `%Z`/`%z` |
| `parse_date`/`parse_time`/`parse_date_time` | Parse a string against a format string into a `NaiveDate`/`NaiveTime`/`NaiveDateTime` |
| `parse_date_time_tz` | Parse a string with a `%z` offset into a `DateTime[FixedOffset]`, interpreting the fields as local wall-clock time |
| `to_rfc3339`/`parse_rfc3339` | Dedicated RFC 3339 fast path, bypassing the specifier engine |

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
| `%A` | Long weekday name | e.g. `"Monday"` |
| `%a` | Short weekday name | e.g. `"Mon"` |
| `%B` | Long month name | e.g. `"March"`; on parse, resolves `%m`'s field directly |
| `%b`, `%h` | Short month name | e.g. `"Mar"`; on parse, resolves `%m`'s field directly |
| `%I` | Hour, 12-hour clock | Zero-padded, `01`..`12`; combines with `%p`/`%P` on parse (cross-checked against `%H`, if also present) |
| `%l` | Hour, 12-hour clock | Space-padded, `" 1"`..`"12"`; parses the same field as `%I`, tolerating a blank or zero leading digit |
| `%P` | am/pm marker, lowercase | `"am"`/`"pm"`; parses `%p`/`%P` case-insensitively either way |
| `%p` | am/pm marker, uppercase | `"AM"`/`"PM"`; see `%P` |
| `%s` | Unix timestamp | Format-only: the underlying UTC instant's seconds since the epoch (unaffected by `format_date_time_tz`'s local zone shift); raises `InputMismatch` on parse |
| `%G` | ISO week-based year | Zero-padded to 4 digits; format-only, raises `InputMismatch` on parse (needs a weekday specifier, not yet implemented, to round-trip) |
| `%g` | ISO week-based year, no century | Zero-padded to 2 digits; format-only, see `%G` |
| `%V` | ISO week number | Zero-padded, `01`..`53`; format-only, see `%G` |
| `%Z` | Timezone name | Format-only: raises `InputMismatch` on parse (no generically parseable shape) |
| `%z` | Timezone offset | `±HHMM`, no colon |
| `%F` | `%Y-%m-%d` | Expands to that specifier sequence |
| `%T` | `%H:%M:%S` | Expands to that specifier sequence |
| `%%` | Literal `%` | |

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

`to_rfc3339` trims trailing zeros from fractional seconds and renders a zero offset as `Z`:

```mbt check
///|
test {
  let naive = @core.NaiveDateTime::from_timestamp(0L, 500_000_000).unwrap()
  let dt = @tz.DateTime::from_utc(naive, @tz.FixedOffset::east(0).unwrap())
  assert_eq(@format.to_rfc3339(dt), "1970-01-01T00:00:00.5Z")
  assert_eq(@format.parse_rfc3339("1970-01-01T00:00:00.5Z"), dt)
}
```

## API reference

### Formatting

| Function | Signature | Description |
| :--- | :--- | :--- |
| `format_date(NaiveDate, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for a time-of-day specifier (`%H`/`%M`/`%S`/`%f`/`%I`/`%l`/`%P`/`%p`) |
| `format_time(NaiveTime, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for a date specifier (`%Y`/`%m`/`%d`/`%j`/`%A`/`%a`/`%B`/`%b`/`%h`/`%G`/`%g`/`%V`) or `%s` (no absolute instant to draw from) |
| `format_date_time(NaiveDateTime, String)` | `-> String raise ParseError` | Render against a format string; raises `MissingField` for `%Z`/`%z` (no zone to draw from) |
| `format_date_time_tz(DateTime[Tz], String)` *(Tz : TimeZone)* | `-> String raise ParseError` | Render in local (wall-clock) representation; `%Z` renders `tz.tz_name()`, `%z` the numeric offset, `%s` the underlying UTC instant's timestamp |

### Parsing

| Function | Signature | Description |
| :--- | :--- | :--- |
| `parse_date(String, String)` | `-> NaiveDate raise ParseError` | Parse against a format string's date fields (`%Y` plus `%m`/`%d` or `%j`) |
| `parse_time(String, String)` | `-> NaiveTime raise ParseError` | Parse against a format string's time-of-day fields (`%H`/`%M`/`%S`, `%f` optional) |
| `parse_date_time(String, String)` | `-> NaiveDateTime raise ParseError` | Parse against a format string's date and time-of-day fields together |
| `parse_date_time_tz(String, String)` | `-> DateTime[FixedOffset] raise ParseError` | Parse against a format string's date, time-of-day, and `%z` fields, interpreting them as the zone's local wall-clock reading |

### RFC 3339 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc3339(DateTime[Tz])` *(Tz : TimeZone)* | `-> String` | Renders `YYYY-MM-DDTHH:MM:SS[.fraction](Z\|±HH:MM)`; a zero offset renders as `Z`, fractional seconds only when nonzero with trailing zeros trimmed, a leap second as `:60`. Total — never raises |
| `parse_rfc3339(String)` | `-> DateTime[FixedOffset] raise ParseError` | Strict RFC 3339 parsing (`T`/`t` and `Z`/`z` case-insensitive; a fractional-second field beyond 9 digits is truncated, not rejected); raises `InvalidRfc3339` on any mismatch |

### `tokenize`

| Function | Signature | Description |
| :--- | :--- | :--- |
| `tokenize(String)` | `-> Array[Item] raise ParseError` | Parses a `%`-specifier format string into a sequence of `Item`s; raises `UnknownSpecifier`/`TrailingPercent` on a malformed format string. Not usually needed directly — `format_*`/`parse_*` call it internally |

### `Item`, `Numeric`, `Fixed`

The token types produced by `tokenize`.

```mbt nocheck
///|
pub(all) enum Item {
  Literal(String)
  Numeric(Numeric)
  Fixed(Fixed)
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
}
```

`Item`, `Numeric`, and `Fixed` each also implement `Eq`.

### `ParseError`

| Variant | Raised when |
| :--- | :--- |
| `UnknownSpecifier(Char)` | `tokenize` encounters an unrecognized `%`-specifier |
| `TrailingPercent` | A format string ends with a bare `%` |
| `MissingField(Item)` | A `format_*` call is asked to render a specifier its input type can't supply (e.g. `%Z` via `format_date_time`) |
| `InvalidRfc3339` | `parse_rfc3339` fails to match the RFC 3339 grammar |
| `IncompleteFields` | A `parse_*` call resolves fields that never populate a required value (e.g. no year) |
| `InconsistentFields` | Two populated fields disagree, or don't jointly form a valid value (e.g. `%j` contradicting `%m`/`%d`, or an out-of-range calendar date) |
| `InputMismatch` | Literal or specifier text fails to match the input, input remains unconsumed, or a format-only specifier (`%Z`, `%s`, `%G`, `%g`, `%V`) is parsed |

`ParseError` also implements `Eq`.
