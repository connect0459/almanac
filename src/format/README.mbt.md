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
| `parse_date_and_remainder`/`parse_time_and_remainder`/`parse_date_time_and_remainder`/`parse_date_time_tz_and_remainder`/`parse_date_time_in_and_remainder` | Like each `parse_*` above, but return the unparsed tail instead of rejecting trailing input |
| `Parsed`/`parse_items`/`parse_items_and_remainder` | Walk a pre-tokenized `Item` sequence against input into an opaque `Parsed`, then resolve it with `to_date`/`to_time`/`to_date_time`/`to_date_time_tz`/`to_date_time_in`, for building custom parsers on the engine's resolution rules |
| `format_date_items`/`format_time_items`/`format_date_time_items`/`format_date_time_tz_items` | `format_*` taking a pre-tokenized `Item` sequence, so a format reused for many values is tokenized once |
| `to_rfc3339`/`to_rfc3339_opts`/`parse_rfc3339` | Dedicated RFC 3339 fast path, bypassing the specifier engine; `to_rfc3339_opts` picks the fractional digits (`SecondsFormat`) and `Z` versus `+00:00` |
| `to_rfc2822`/`parse_from_rfc2822` | Dedicated RFC 2822 fast path (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`), bypassing the specifier engine |
| `parse_duration` | Reads a `TimeDelta` from Go-style text (`"1h30m"`, `"-1.5s"`, `"300ms"`); the inverse of `TimeDelta`'s `Show` |
| `parse_fixed_offset` | Reads a `FixedOffset` from offset text (`"+09:00"`, `"+0900"`, `"+09"`, `"+09:00:30"`, `"Z"`); the inverse of `FixedOffset`'s `Show` |
| `parse_date_default`/`parse_time_default`/`parse_date_time_default`/`parse_date_time_utc_default`/`parse_date_time_tz_default` | One-argument parsers that read the layout each type's `Show` renders (`2024-03-05`, `09:05:07.500`, `2024-03-05 09:05:07.500`, `... UTC`, `... +09:00`); the inverse of `Show`, so every rendered value reads back |
| `rfc1123`/`rfc1123z`/`rfc822`/`rfc822z`/`rfc850`/`ansic`/`unix_date`/`ruby_date`/`kitchen`/`stamp`/`stamp_milli`/`stamp_micro`/`stamp_nano`/`date_only`/`time_only`/`date_time` | Named convenience format strings (Go `time` package layout equivalents) — pass one to `format_*`/`parse_*` like any other format string |

## Supported specifiers

| Specifier | Field | Description |
| :--- | :--- | :--- |
| `%Y` | Year | Zero-padded to 4 digits on format, `-` for a negative year and an explicit `+` beyond 9999 (`0024`, `-0001`, `+10000`, as ISO 8601 requires and as `NaiveDate`'s `Show` renders); variable-width on parse, accepting an optional `-` or `+` and an unsigned year beyond 9999 |
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
| `%.3f` | Dot-prefixed fractional second, milliseconds | A dot then exactly 3 digits, truncated (not rounded), present even for a whole second (`.000`); on parse the dot and all 3 digits are mandatory, unlike the optional `%.f` |
| `%.6f` | Dot-prefixed fractional second, microseconds | Like `%.3f` with 6 digits |
| `%.9f` | Dot-prefixed fractional second, nanoseconds | Like `%.3f` with 9 digits |
| `%A` | Long weekday name | e.g. `"Monday"` |
| `%a` | Short weekday name | e.g. `"Mon"` |
| `%B` | Long month name | e.g. `"March"`; on parse, resolves `%m`'s field directly |
| `%b`, `%h` | Short month name | e.g. `"Mar"`; on parse, resolves `%m`'s field directly |
| `%I` | Hour, 12-hour clock | Zero-padded, `01`..`12`; combines with `%p`/`%P` on parse (cross-checked against `%H`, if also present) |
| `%l` | Hour, 12-hour clock | Space-padded, `" 1"`..`"12"`; parses the same field as `%I`, tolerating a blank or zero leading digit |
| `%k` | Hour, 24-hour clock | Space-padded, `" 0"`..`"23"`; parses the same field as `%H`, tolerating a blank or zero leading digit |
| `%P` | am/pm marker, lowercase | `"am"`/`"pm"`; parses `%p`/`%P` case-insensitively either way |
| `%p` | am/pm marker, uppercase | `"AM"`/`"PM"`; see `%P` |
| `%s` | Unix timestamp | The UTC instant's seconds since the epoch (unaffected by `format_date_time_tz`'s local zone shift). On parse, a signed run of digits naming that instant: date-time resolvers derive the value from it (a `%f`-family field gives the sub-second part) and cross-check every other date or time field against the reading it has in the target offset (`InconsistentFields` on a mismatch); `to_date_time_tz` still needs `%z` (`IncompleteFields` without it), `to_date_time_in` takes the offset from the zone, and `to_date`/`to_time` ignore it. More than 18 digits, or an instant no date can hold, is `FieldOutOfRange` |
| `%G` | ISO week-based year | Zero-padded to 4 digits on format, with `%Y`'s sign rules (`-` negative, `+` beyond 9999); on parse, an optionally-signed greedy field like `%Y`. With `%V` and a weekday, constructs the date via ISO week-date construction; otherwise cross-checked against the resolved date |
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
| `%Z` | Timezone name | On parse, consumes one or more non-whitespace characters without validating them; every entry point discards the name except `parse_date_time_in`, which resolves it through the target zone; an empty name raises `InputTooShort` at the end of input and `InputMismatch` before whitespace |
| `%z` | Timezone offset | `±HHMM`, no colon |
| `%:z` | Timezone offset, minutes | `±HH:MM`; on parse, the colon is mandatory (exactly its own rendered shape) |
| `%::z` | Timezone offset, seconds | `±HH:MM:SS`, always with seconds (unlike `FixedOffset`'s own `tz_name`, which only extends past minutes when they're nonzero); on parse, the seconds field is mandatory too |
| `%:::z` | Timezone offset, hours only | `±HH` — minutes and seconds are dropped entirely, not just omitted when zero; parses the same shape |
| `%#z` | Timezone offset, permissive | Parse-only (mirrors chrono, which panics if used to format): accepts `±HHMM`, `±HH:MM`, hours-only `±HH`, or `Z`/`z` for a zero offset, with any run of `:`/space/tab (or none) between the hour and minute digits; no seconds field |
| `%F` | `%Y-%m-%d` | Expands to that specifier sequence |
| `%T` | `%H:%M:%S` | Expands to that specifier sequence |
| `%D`, `%x` | `%m/%d/%y` | Expands to that specifier sequence (no locale support, so `%x` is identical to `%D`) |
| `%v` | `%e-%b-%Y` | VMS-style date, e.g. `" 5-Mar-2024"`; expands to that specifier sequence |
| `%R` | `%H:%M` | Expands to that specifier sequence; carries no seconds, which `parse_time` reads as zero (add `%S` for a seconds field, or see `%X`) |
| `%X` | `%H:%M:%S` | Expands to that specifier sequence (identical to `%T`) |
| `%r` | `%I:%M:%S %p` | Expands to that specifier sequence |
| `%c` | `%a %b %e %H:%M:%S %Y` | ctime-style, e.g. `"Tue Mar  5 09:05:30 2024"`; expands to that specifier sequence |
| `%+` | RFC 3339 date-time | A whole `DateTime`, rendered/parsed via the dedicated `to_rfc3339`/`parse_rfc3339` fast path rather than a sequence of simpler specifiers (mirrors chrono); needs a date, time, and offset together, like `%Z`/`%z` |
| `%%` | Literal `%` | |
| `%n` | Newline | Renders a single `\n`; on parse matches exactly one `\n` (expands to a literal item) |
| `%t` | Tab | Renders a single `\t`; on parse matches exactly one `\t` (expands to a literal item) |
| `%-X` | No padding | Overrides `X`'s own default padding; on parse reads one to `X`'s width in digits, greedily (`%-d` reads `5` and `05`, and in `%-H%-M` the input `905` splits as `90` then `5`), the opt-in way to accept unpadded numbers, since an unflagged field stays fixed-width; `X` must resolve to a single bare `Numeric` specifier (not a `Fixed` one or a compound expansion like `%F`) other than `%f`/`%.f`/`%3f`/`%6f`/`%s` — chrono itself treats the fractional-second family as `Fixed`, and `%s` has no natural fixed width |
| `%0X` | Zero padding | See `%-X`; meaningful for a specifier that doesn't already zero-pad, e.g. `%0e`. On parse it keeps `X`'s own default reading |
| `%_X` | Space padding | See `%-X`; meaningful for a specifier that doesn't already space-pad, e.g. `%_d`. On parse it reads a leading blank or zero (`" 5"` or `"05"`), so a value rendered with `%_X` reads back |

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
| `parse_time(String, String)` | `-> NaiveTime raise ParseError` | Parse against a format string's time-of-day fields: an hour and a minute are required, while `%S` and `%f` are optional and default to zero (so `%R` and `kitchen` resolve) |
| `parse_date_time(String, String)` | `-> NaiveDateTime raise ParseError` | Parse against a format string's date and time-of-day fields together |
| `parse_date_time_tz(String, String)` | `-> DateTime[FixedOffset] raise ParseError` | Parse against a format string's date, time-of-day, and `%z` fields, interpreting them as the zone's local wall-clock reading |
| `parse_date_time_in[Tz : TimeZone](String, String, Tz)` | `-> MappedLocalTime[DateTime[Tz]] raise ParseError` | Parse a zone-less format's date and time-of-day fields and resolve the reading in `tz` (`Ambiguous` in a DST fold, `Absent` in a gap); raises `InconsistentFields` if the format yields an offset (`%z`, `%+`, ...); a `%Z` name the zone recognizes fixes the offset (Go's `ParseInLocation`), so an abbreviation like `EDT` resolves a DST fold to `Single`, and an unrecognized name is ignored |
| `parse_date_and_remainder(String, String)` / `parse_time_and_remainder` / `parse_date_time_and_remainder` / `parse_date_time_tz_and_remainder` / `parse_date_time_in_and_remainder` | `-> (T, String) raise ParseError` | The value the matching `parse_*` returns, paired with the leftover input (from the first character the format did not consume to the end, counted in characters, `""` when the whole input matched). A mismatch or unresolvable field inside the format still raises, exactly as in the strict form; only trailing input is tolerated |

### RFC 3339 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc3339(DateTime[Tz])` *(Tz : TimeZone)* | `-> String` | Renders `YYYY-MM-DDTHH:MM:SS[.fraction](Z\|±HH:MM)`; a zero offset renders as `Z`, fractional seconds only when nonzero, with the fewest of 3, 6 or 9 digits that represent them, a leap second as `:60`. Total — never raises |
| `to_rfc3339_opts(DateTime[Tz], SecondsFormat, Bool)` *(Tz : TimeZone)* | `-> String` | Like `to_rfc3339`, with the fractional seconds chosen by `SecondsFormat` (`Secs` none, `Millis`/`Micros`/`Nanos` exactly 3/6/9 digits, truncated rather than rounded so the seconds never change, `Auto` the fewest of 3/6/9 that are exact) and, when the `Bool` (`use_z`) is `true`, a zero offset written `Z`, else `+00:00`; a non-zero offset is unaffected. `Auto` with `true` is `to_rfc3339` |
| `parse_rfc3339(String)` | `-> DateTime[FixedOffset] raise ParseError` | Strict RFC 3339 parsing (`T`/`t` and `Z`/`z` case-insensitive; a fractional-second field beyond 9 digits is truncated, not rejected); raises `InvalidRfc3339` on any mismatch |

### RFC 2822 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc2822(DateTime[Tz])` *(Tz : TimeZone)* | `-> String raise ParseError` | Renders `"<short weekday>, <day> <short month> <year> <HH>:<MM>:<SS> ±HHMM"` (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`); the day is unpadded (one or two digits, never a leading zero), unlike this package's other numeric fields. Raises `InvalidRfc2822` if the year is outside RFC 2822's own `0..=9999` range — unlike `to_rfc3339`, not total |
| `parse_from_rfc2822(String)` | `-> DateTime[FixedOffset] raise ParseError` | Strict RFC 2822 parsing: only the exact shape `to_rfc2822` renders (day-of-week and seconds mandatory, single-space separators, a 4-digit year, a numeric `±HHMM` offset). Unlike chrono's own parser, does *not* support RFC 2822's "obsolete format" — optional day-of-week, arbitrary/folding whitespace, 2-/3-digit year windowing, named legacy zones (`GMT`, `EST`, ...), or parenthesized comments. Raises `InvalidRfc2822` on any mismatch |
| `parse_duration(String)` | `-> TimeDelta raise ParseError` | Parses one or more `<number><unit>` components with an optional leading sign (`"1h30m"`, `"-1.5s"`, `"300ms"`, `".5s"`, `"1.5h"`). Units are `ns`, `us` (also `µs` U+00B5 and `μs` U+03BC), `ms`, `s`, `m`, `h`, case-sensitive, with hours the largest (no days/weeks); components are summed. A bare `"0"` (optionally signed) needs no unit. Fractional digits beyond the ninth, and precision finer than a nanosecond, are truncated toward zero. The inverse of `TimeDelta`'s `Show`. Raises `InvalidDuration` for malformed input or a value outside `TimeDelta`'s range |
| `parse_fixed_offset(String)` | `-> FixedOffset raise ParseError` | Parses a whole offset string: `±HH:MM:SS`, `±HH:MM`, `±HHMM`, `±HH`, or `Z`/`z` for zero. Raises `InputMismatch` for any other text (including minutes or seconds above 59) and `FieldOutOfRange` for a well-shaped offset beyond `±23:59:59` |
| `parse_date_default(String)` / `parse_time_default(String)` / `parse_date_time_default(String)` | `-> NaiveDate` / `NaiveTime` / `NaiveDateTime raise ParseError` | Parse exactly the text `Show` renders: `YYYY-MM-DD` (`-` for a negative year, `+` beyond 9999); `HH:MM:SS` with an optional fraction of any number of digits and a leap second as `:60`; a date and time joined by one space. Same failures as `parse_date`/`parse_time`/`parse_date_time` |
| `parse_date_time_utc_default(String)` | `-> DateTime[Utc] raise ParseError` | `parse_date_time_default`'s layout followed by a space and `UTC`: the inverse of `Show` for `DateTime[Utc]` |
| `parse_date_time_tz_default(String)` | `-> DateTime[FixedOffset] raise ParseError` | `parse_date_time_default`'s layout followed by a space and an offset as `parse_fixed_offset` reads it; the written clock is local time in that offset. The inverse of `Show` for `DateTime[FixedOffset]`; an IANA zone's abbreviation or a `FixedZone`'s name is not read back |

### Named layouts

Convenience format-string constants, mirroring Go's `time` package layouts (translated into this project's `%`-specifier style, not copied as Go's reference-time-layout syntax). Each is just a `String` — pass one to `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, or their `parse_*` counterparts, like any other format string.

| Constant | Format string | Go equivalent | Example |
| :--- | :--- | :--- | :--- |
| `rfc1123` | `"%a, %d %b %Y %H:%M:%S %Z"` | `RFC1123` | `"Tue, 05 Mar 2024 09:05:03 UTC"` |
| `rfc1123z` | `"%a, %d %b %Y %H:%M:%S %z"` | `RFC1123Z` | `"Tue, 05 Mar 2024 18:05:03 +0900"` |
| `rfc822` | `"%d %b %y %H:%M %Z"` | `RFC822` | `"05 Mar 24 09:05 UTC"` |
| `rfc822z` | `"%d %b %y %H:%M %z"` | `RFC822Z` | `"05 Mar 24 18:05 +0900"` |
| `rfc850` | `"%A, %d-%b-%y %H:%M:%S %Z"` | `RFC850` | `"Tuesday, 05-Mar-24 09:05:03 UTC"` |
| `ansic` | `"%a %b %e %H:%M:%S %Y"` | `ANSIC` | `"Tue Mar  5 09:05:03 2024"` |
| `unix_date` | `"%a %b %e %H:%M:%S %Z %Y"` | `UnixDate` | `"Tue Mar  5 09:05:03 UTC 2024"` |
| `ruby_date` | `"%a %b %d %H:%M:%S %z %Y"` | `RubyDate` | `"Tue Mar 05 18:05:03 +0900 2024"` |
| `kitchen` | `"%-I:%M%p"` | `Kitchen` | `"9:05AM"` |
| `stamp` | `"%b %e %H:%M:%S"` | `Stamp` | `"Mar  5 09:05:03"` |
| `stamp_milli` | `"%b %e %H:%M:%S.%3f"` | `StampMilli` | `"Mar  5 09:05:03.123"` |
| `stamp_micro` | `"%b %e %H:%M:%S.%6f"` | `StampMicro` | `"Mar  5 09:05:03.123456"` |
| `stamp_nano` | `"%b %e %H:%M:%S.%9f"` | `StampNano` | `"Mar  5 09:05:03.123456789"` |
| `date_only` | `"%F"` | `DateOnly` | `"2024-03-05"` |
| `time_only` | `"%T"` | `TimeOnly` | `"09:05:03"` |
| `date_time` | `"%F %T"` | `DateTime` | `"2024-03-05 09:05:03"` |

The `stamp*` family (no year) doesn't carry enough fields to round-trip through the matching `parse_*` function on its own — matching Go's own `Stamp` family, meant for display alongside separately-known context. `date_only`/`time_only` are self-sufficient for parsing, and so is `kitchen` for a time on the minute, since `parse_time` reads a time without seconds as having zero seconds (a value with seconds loses them when rendered with `kitchen`).

### `tokenize`

| Function | Signature | Description |
| :--- | :--- | :--- |
| `tokenize(String)` | `-> Array[Item] raise ParseError` | Parses a `%`-specifier format string into a sequence of `Item`s; raises `UnknownSpecifier`/`TrailingPercent` on a malformed format string. Not usually needed directly — `format_*`/`parse_*` call it internally |
| `format_date_items(NaiveDate, Array[Item])` / `format_time_items(NaiveTime, Array[Item])` / `format_date_time_items(NaiveDateTime, Array[Item])` / `format_date_time_tz_items(DateTime[Tz], Array[Item])` *(Tz : TimeZone)* | `-> String raise ParseError` | The `format_*` functions against an already-tokenized (or hand-built) `Item` sequence; `format_*` is `tokenize` followed by these |
| `parse_items(Array[Item], String)` | `-> Parsed raise ParseError` | Walks an `Item` sequence against the whole input (`InputMismatch` on a mismatch, `InputTooShort` if the input ends first, `TrailingInput` on leftover input), accumulating fields without resolving them |
| `parse_items_and_remainder(Array[Item], String)` | `-> (Parsed, String) raise ParseError` | Like `parse_items`, but returns leftover input instead of rejecting it |
| `Parsed::to_date()` / `to_time()` / `to_date_time()` | `-> NaiveDate` / `NaiveTime` / `NaiveDateTime raise ParseError` | Resolve the accumulated fields; `IncompleteFields` if too few were parsed, `FieldOutOfRange` if a value is outside its range (an hour of 24, February 30), `InconsistentFields` if fields contradict each other. One `Parsed` resolves any number of ways |
| `Parsed::to_date_time_tz()` | `-> DateTime[FixedOffset] raise ParseError` | Resolve the date, time and `%z` offset, reading the fields as that offset's local time |
| `Parsed::to_date_time_in(Tz)` *(Tz : TimeZone)* | `-> MappedLocalTime[DateTime[Tz]] raise ParseError` | Resolve a zone-less reading in `tz`; see `parse_date_time_in` for `%Z` handling and the offset rejection |

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
  HourBlank
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
  DotNanosecond3
  DotNanosecond6
  DotNanosecond9
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
| `InconsistentFields` | Two populated fields contradict each other (e.g. `%j` or a weekday name disagreeing with the date, two `%H` readings), or an offset is given to `Parsed::to_date_time_in` |
| `FieldOutOfRange` | A parsed value is outside what its field can hold, so no value can be built (an hour of 24, February 30, an ISO week that does not exist in its year, an offset beyond `±23:59:59`) |
| `InputMismatch` | Literal or specifier text fails to match the input |
| `InputTooShort` | The input is exhausted when the format still has an item to match (e.g. `"2024-03"` against `%F`); a partial field such as one digit for `%m` is `InputMismatch` |
| `TrailingInput` | The format is fully matched but input remains after it; the `_and_remainder` functions return that tail instead |

`ParseError` also implements `Eq` and `Show`, which renders a one-line message per variant (e.g. `input does not match the format`; `MissingField` appends the item's `Debug` form).
