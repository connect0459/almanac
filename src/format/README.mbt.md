# `format` package

strftime-style formatting and parsing for `core`/`tz` types. Import `connect0459/almanac/format` for `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, their `parse_*` counterparts, and dedicated RFC 3339 and RFC 2822 fast paths (`to_rfc3339`/`parse_rfc3339`, `to_rfc2822`/`parse_rfc2822`, `parse_rfc2822_lenient`, `to_http_date`/`parse_http_date`), and `parse_duration` for `TimeDelta`.

## Key functions

| Function | Description |
| :--- | :--- |
| `format_date`/`format_time`/`format_date_time` | Render a `NaiveDate`/`NaiveTime`/`NaiveDateTime` against a `%`-specifier format string |
| `format_date_time_tz` | Render a `DateTime[Tz]` in its local (wall-clock) representation, supporting `%Z`/`%z` |
| `parse_date`/`parse_time`/`parse_date_time` | Parse a string against a format string into a `NaiveDate`/`NaiveTime`/`NaiveDateTime` |
| `parse_date_time_fixed_offset` | Parse a string with a `%z` offset into a `DateTime[FixedOffset]`, interpreting the fields as local wall-clock time |
| `parse_date_time_in` | Parse a zone-less string and resolve it as wall-clock time in a given `TimeZone`, surfacing DST ambiguity as `MappedLocalTime` |
| `parse_date_and_remainder`/`parse_time_and_remainder`/`parse_date_time_and_remainder`/`parse_date_time_fixed_offset_and_remainder`/`parse_date_time_in_and_remainder` | Like each `parse_*` above, but return the unparsed tail instead of rejecting trailing input |
| `Parsed`/`parse_items`/`parse_items_and_remainder` | Walk a pre-tokenized `Item` sequence against input into a `Parsed` whose fields are not exposed one by one, then resolve it with `to_date`/`to_time`/`to_date_time`/`to_date_time_fixed_offset`/`to_date_time_in`, for building custom parsers on the engine's resolution rules |
| `format_date_items`/`format_time_items`/`format_date_time_items`/`format_date_time_tz_items` | `format_*` taking a pre-tokenized `Item` sequence, so a format reused for many values is tokenized once |
| `to_rfc3339`/`to_rfc3339_opts`/`parse_rfc3339` | Dedicated RFC 3339 fast path, bypassing the specifier engine; `to_rfc3339_opts` picks the fractional digits (`SecondsFormat`) and `Z` versus `+00:00` |
| `to_rfc2822`/`parse_rfc2822` | Dedicated RFC 2822 fast path (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`), bypassing the specifier engine |
| `to_http_date`/`parse_http_date` | Dedicated HTTP date fast path (IMF-fixdate, e.g. `"Sun, 06 Nov 1994 08:49:37 GMT"`), bypassing the specifier engine |
| `parse_duration` | Reads a `TimeDelta` from duration text (`"1h30m"`, `"-1.5s"`, `"300ms"`); the inverse of `TimeDelta`'s `Show` |
| `parse_fixed_offset` | Reads a `FixedOffset` from offset text (`"+09:00"`, `"+0900"`, `"+09"`, `"+09:00:30"`, `"Z"`); the inverse of `FixedOffset`'s `Show` |
| `parse_date_default`/`parse_time_default`/`parse_date_time_default`/`parse_date_time_utc_default`/`parse_date_time_fixed_offset_default` | One-argument parsers that read the layout each type's `Show` renders (`2024-03-05`, `09:05:07.500`, `2024-03-05 09:05:07.500`, `... UTC`, `... +09:00`); the inverse of `Show`, so every rendered value reads back |
| `ANSIC`/`UNIX_DATE`/`RUBY_DATE`/`KITCHEN`/`STAMP`/`STAMP_MILLI`/`STAMP_MICRO`/`STAMP_NANO`/`DATE_ONLY`/`TIME_ONLY`/`DATE_TIME` | Named convenience format strings — pass one to `format_*`/`parse_*` like any other format string |

## Supported specifiers

| Specifier | Field | Description |
| :--- | :--- | :--- |
| `%Y` | Year | Zero-padded to 4 digits on format, `-` for a negative year and an explicit `+` beyond 9999 (`0024`, `-0001`, `+10000`, as ISO 8601 requires and as `NaiveDate`'s `Show` renders); on parse, an optional `-` or `+` followed by any number of digits, or at most 4 digits when unsigned (so `%Y%m%d` reads `20240305`; a year beyond 9999 needs its sign) |
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
| `%s` | Unix timestamp | The UTC instant's seconds since the epoch (unaffected by `format_date_time_tz`'s local zone shift). On parse, a signed run of digits naming that instant: date-time resolvers derive the value from it (a `%f`-family field gives the sub-second part) and cross-check every other date or time field against the reading it has in the target offset (`InconsistentFields` on a mismatch); `to_date_time_fixed_offset` still needs `%z` (`IncompleteFields` without it), `to_date_time_in` takes the offset from the zone, and `to_date`/`to_time` ignore it. More than 18 digits, or an instant no date can hold, is `FieldOutOfRange` |
| `%G` | ISO week-based year | Zero-padded to 4 digits on format, with `%Y`'s sign rules (`-` negative, `+` beyond 9999); on parse, read like `%Y` (signed: any number of digits; unsigned: at most 4). With `%V` and a weekday, constructs the date via ISO week-date construction; otherwise cross-checked against the resolved date |
| `%g` | ISO week-based year, no century | Zero-padded to 2 digits, always `00`..`99` (floor modulo, so year `-7` renders `93`); on parse, a lone `%g` uses the same pivot as `%y` (below 70 is 20xx, otherwise 19xx), and is cross-checked against `%G` when both are present |
| `%V` | ISO week number | Zero-padded, `01`..`53`; on parse, combined with `%G`/`%g` and a weekday, or else cross-checked against the resolved date |
| `%C` | Century | Zero-padded to 2 digits (`year` floor-divided by 100, so year `-7` renders `-01`; a negative century is not readable on parse); combines with `%y` on parse (`%y` alone is interpreted via the conventional two-digit-year pivot: `< 70` -> 20xx, `>= 70` -> 19xx); cross-checked against `%Y`, if also present |
| `%y` | Year without century | Zero-padded to 2 digits, always `00`..`99` (floor modulo, so year `-7` renders `93`); see `%C` |
| `%q` | Quarter | `1`..`4`, no padding; on parse, cross-checked against an already-determined date (a quarter alone can't determine a day, like `%A`/`%a`) |
| `%e` | Day, space-padded | `" 1"`..`"31"`; parses the same field as `%d`, tolerating a blank or zero leading digit |
| `%w` | Weekday number, Sunday-based | `0`..`6` (Sunday `0`); parses the same field as `%A`/`%a` |
| `%u` | Weekday number, Monday-based (ISO 8601) | `1`..`7` (Sunday `7`); parses the same field as `%A`/`%a` |
| `%U` | Week number, Sunday-based | Zero-padded, `00`..`53`; combined with a weekday (`%A`/`%a`/`%w`/`%u`) on parse to construct a date when no month/day/ordinal is given, mirroring `%j`'s role; cross-checked against an already-determined date otherwise |
| `%W` | Week number, Monday-based | Zero-padded, `00`..`53`; see `%U` |
| `%Z` | Timezone name | On parse, consumes one or more non-whitespace characters without validating them; every entry point discards the name except `parse_date_time_in`, which resolves it through the target zone; an empty name raises `InputTooShort` at the end of input and `InputMismatch` before whitespace |
| `%z` | Timezone offset | `±HHMM`, no colon |
| `%:z` | Timezone offset, minutes | `±HH:MM`; on parse, the colon is mandatory (exactly its own rendered shape) |
| `%::z` | Timezone offset, seconds | `±HH:MM:SS`, always with seconds (unlike `FixedOffset`'s own `zone_name`, which only extends past minutes when they're nonzero); on parse, the seconds field is mandatory too |
| `%:::z` | Timezone offset, hours only | `±HH` — minutes and seconds are dropped entirely, not just omitted when zero; parses the same shape |
| `%#z` | Timezone offset, permissive | Parse-only: accepts `±HHMM`, `±HH:MM`, hours-only `±HH`, or `Z`/`z` for a zero offset, with any run of `:`/space/tab (or none) between the hour and minute digits; no seconds field |
| `%F` | `%Y-%m-%d` | Expands to that specifier sequence |
| `%T` | `%H:%M:%S` | Expands to that specifier sequence |
| `%D`, `%x` | `%m/%d/%y` | Expands to that specifier sequence (no locale support, so `%x` is identical to `%D`) |
| `%v` | `%e-%b-%Y` | VMS-style date, e.g. `" 5-Mar-2024"`; expands to that specifier sequence |
| `%R` | `%H:%M` | Expands to that specifier sequence; carries no seconds, which `parse_time` reads as zero (add `%S` for a seconds field, or see `%X`) |
| `%X` | `%H:%M:%S` | Expands to that specifier sequence (identical to `%T`) |
| `%r` | `%I:%M:%S %p` | Expands to that specifier sequence |
| `%c` | `%a %b %e %H:%M:%S %Y` | ctime-style, e.g. `"Tue Mar  5 09:05:30 2024"`; expands to that specifier sequence |
| `%+` | RFC 3339 date-time | A whole `DateTime`, rendered/parsed via the dedicated `to_rfc3339`/`parse_rfc3339` fast path rather than a sequence of simpler specifiers; needs a date, time, and offset together, like `%Z`/`%z` |
| `%%` | Literal `%` | |
| `%n` | Newline | Renders a single `\n`; on parse matches exactly one `\n` (expands to a literal item) |
| `%t` | Tab | Renders a single `\t`; on parse matches exactly one `\t` (expands to a literal item) |
| `%-X` | No padding | Overrides `X`'s own default padding; on parse reads one to `X`'s width in digits, greedily (`%-d` reads `5` and `05`, and in `%-H%-M` the input `905` splits as `90` then `5`), the opt-in way to accept unpadded numbers, since an unflagged field stays fixed-width; `X` must resolve to a single bare `Numeric` specifier (not a `Fixed` one or a compound expansion like `%F`) other than `%f`/`%.f`/`%3f`/`%6f`/`%s` — the fractional-second family and `%s` have no natural fixed width |
| `%0X` | Zero padding | See `%-X`; meaningful for a specifier that doesn't already zero-pad, e.g. `%0e`. On parse it keeps `X`'s own default reading |
| `%_X` | Space padding | See `%-X`; meaningful for a specifier that doesn't already space-pad, e.g. `%_d`. On parse it reads a leading blank or zero (`" 5"` or `"05"`), so a value rendered with `%_X` reads back |

On format, a padding flag overrides the specifier's default padding. On parse, `%-X` and `%_X` widen what the field accepts (see above), while `%0X` and a year (already variable-width) read as bare `%X` does.

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

`to_rfc3339` is total: a year outside `0..=9999`, which RFC 3339's four-digit year cannot hold, is written with an explicit sign (`+10000-01-02T03:04:05Z`, `-0044-...`) as ISO 8601 expands it, and `parse_rfc3339` does not read such text back. `to_rfc2822`, whose format has no such expansion, raises `InvalidRfc2822` for those years.

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

`Item`, `Numeric`, `Fixed`, `PadMode` and `SecondsFormat` are `pub(all)` so callers can build item sequences by hand, and they grow with new specifiers and formats; adding a variant is a breaking change for an exhaustive `match` outside this package, and is released as one.

Every `format_*` and `parse_*` function takes the subject first (the value to render or the input text) and the pattern (a format string or an `Item` array) second.

Suffixes name where the zone comes from: `_tz` renders any `DateTime[Tz]` (`format_date_time_tz`), `_in` reads the local clock in a `Tz` the caller passes (`parse_date_time_in`), and `_fixed_offset` reads the offset written in the input (`parse_date_time_fixed_offset`). A `_default` function is the one-argument form that pairs with a parser taking a format string, and reads exactly what the type's `Show` renders (there is deliberately no fmt-taking `parse_date_time_utc`; use `parse_date_time_in(input, fmt, Utc::new())`). `parse_duration` and `parse_fixed_offset` have no format-string counterpart, so they carry no suffix; each is also the inverse of its type's `Show`, and each accepts a wider grammar than `Show` writes (for instance `"Z"`, `"+09"` and `".5s"`).

### Formatting

| Function | Signature | Description |
| :--- | :--- | :--- |
| `format_date(NaiveDate, String)` | `-> String raise FormatError` | Render against a format string; raises `MissingField` for a time-of-day specifier (`%H`/`%M`/`%S`/`%f`/`%I`/`%l`/`%P`/`%p`) |
| `format_time(NaiveTime, String)` | `-> String raise FormatError` | Render against a format string; raises `MissingField` for a date specifier (`%Y`/`%m`/`%d`/`%j`/`%A`/`%a`/`%B`/`%b`/`%h`/`%G`/`%g`/`%V`/`%C`/`%y`/`%q`/`%e`/`%w`/`%u`/`%U`/`%W`) or `%s` (no absolute instant to draw from) |
| `format_date_time(NaiveDateTime, String)` | `-> String raise FormatError` | Render against a format string; raises `MissingField` for `%Z`/`%z`/`%:z`/`%::z`/`%:::z` (no zone to draw from), or `ParseOnly` for `%#z` (parse-only, never renders) |
| `format_date_time_tz(DateTime[Tz], String)` *(Tz : TimeZone)* | `-> String raise FormatError` | Render in local (wall-clock) representation; `%Z` renders `tz.zone_name()`, `%z` the numeric offset, `%s` the underlying UTC instant's timestamp |

### Parsing

| Function | Signature | Description |
| :--- | :--- | :--- |
| `parse_date(String, String)` | `-> NaiveDate raise FormatError` | Parse against a format string's date fields (`%Y` plus `%m`/`%d` or `%j`) |
| `parse_time(String, String)` | `-> NaiveTime raise FormatError` | Parse against a format string's time-of-day fields: an hour and a minute are required, while `%S` and `%f` are optional and default to zero (so `%R` and `kitchen` resolve) |
| `parse_date_time(String, String)` | `-> NaiveDateTime raise FormatError` | Parse against a format string's date and time-of-day fields together |
| `parse_date_time_fixed_offset(String, String)` | `-> DateTime[FixedOffset] raise FormatError` | Parse against a format string's date, time-of-day, and `%z` fields, interpreting them as the zone's local wall-clock reading |
| `parse_date_time_in[Tz : TimeZone](String, String, Tz)` | `-> MappedLocalTime[DateTime[Tz]] raise FormatError` | Parse a zone-less format's date and time-of-day fields and resolve the reading in `tz` (`Ambiguous` in a DST fold, `Absent` in a gap); raises `InconsistentFields` if the format yields an offset (`%z`, `%+`, ...); a `%Z` name the zone recognizes fixes the offset, so an abbreviation like `EDT` resolves a DST fold to `Single`, and an unrecognized name is ignored |
| `parse_date_and_remainder(String, String)` / `parse_time_and_remainder` / `parse_date_time_and_remainder` / `parse_date_time_fixed_offset_and_remainder` / `parse_date_time_in_and_remainder` | `-> (T, String) raise FormatError` | The value the matching `parse_*` returns, paired with the leftover input (from the first character the format did not consume to the end, counted in characters, `""` when the whole input matched). A mismatch or unresolvable field inside the format still raises, exactly as in the strict form; only trailing input is tolerated |

### RFC 3339 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc3339(DateTime[Tz])` *(Tz : TimeZone)* | `-> String` | Renders `YYYY-MM-DDTHH:MM:SS[.fraction](Z\|±HH:MM)`; a zero offset renders as `Z`, fractional seconds only when nonzero, with the fewest of 3, 6 or 9 digits that represent them, a leap second as `:60`. Total — never raises |
| `to_rfc3339_opts(DateTime[Tz], SecondsFormat, use_z? : Bool)` *(Tz : TimeZone)* | `-> String` | Like `to_rfc3339`, with the fractional seconds chosen by `SecondsFormat` (`Secs` none, `Millis`/`Micros`/`Nanos` exactly 3/6/9 digits, truncated rather than rounded so the seconds never change, `Auto` the fewest of 3/6/9 that are exact) and, when the labelled `use_z` (default `true`) is `true`, a zero offset written `Z`, else `+00:00` (`use_z=false`); a non-zero offset is unaffected. `Auto` with the default is `to_rfc3339` |
| `parse_rfc3339(String)` | `-> DateTime[FixedOffset] raise FormatError` | Strict RFC 3339 parsing (`T`/`t` and `Z`/`z` case-insensitive; a fractional-second field beyond 9 digits is truncated, not rejected); raises `InvalidRfc3339` on any mismatch |
| `parse_iso8601(String)` | `-> Iso8601 raise FormatError` | Lenient ISO 8601 reader, separate from the strict `parse_rfc3339`: the date and time are joined by `T`, `t` or one space, the seconds may be left off (`09:30`), and the offset (`Z`/`z` or `±HH:MM`) may be absent. Returns `Zoned(DateTime[FixedOffset])`, `Local(NaiveDateTime)`, `DateOnly(NaiveDate)` or `TimeOnly(NaiveTime)` according to what the text carried; an offset on a bare date or time is rejected. Fractional seconds and a leap second `:60` follow `parse_rfc3339`; only this extended-format subset is read, so the basic format (`20240305T093000`), an hour-only time, a comma as the decimal mark and week or ordinal dates raise `InvalidIso8601`, as does any other input |

### RFC 2822 fast path

| Function | Signature | Description |
| :--- | :--- | :--- |
| `to_rfc2822(DateTime[Tz])` *(Tz : TimeZone)* | `-> String raise FormatError` | Renders `"<short weekday>, <day> <short month> <year> <HH>:<MM>:<SS> ±HHMM"` (e.g. `"Tue, 1 Jul 2003 10:52:37 +0200"`); the day is unpadded (one or two digits, never a leading zero), unlike this package's other numeric fields. Raises `InvalidRfc2822` if the year is outside RFC 2822's own `0..=9999` range — unlike `to_rfc3339`, not total |
| `parse_rfc2822(String)` | `-> DateTime[FixedOffset] raise FormatError` | Strict RFC 2822 parsing: only the exact shape `to_rfc2822` renders (day of week and seconds mandatory, short day and month names matched case-sensitively, the day of week matching the date, single-space separators, a 4-digit year, a numeric `±HHMM` offset). Does *not* read RFC 2822's "obsolete format"; use `parse_rfc2822_lenient` for that. Raises `InvalidRfc2822` on any mismatch |
| `parse_rfc2822_lenient(String)` | `-> DateTime[FixedOffset] raise FormatError` | Opt-in reader for RFC 2822's obsolete syntax. Every date `to_rfc2822` renders reads back unchanged, and a superset of `parse_rfc2822`: every string `parse_rfc2822` reads is read the same way. Accepts an optional short day of week (which must match the date when present) and seconds, any whitespace run for a space (also before the first field), names matched ignoring case, a two-digit year below 50 as 20xx and from 50 as 19xx, a three-digit year as 1900 plus the year (a four-digit year is unchanged; one digit or more than four is rejected), the zones `GMT`, `UT`, `EST`/`EDT`, `CST`/`CDT`, `MST`/`MDT`, `PST`/`PDT`, any single letter but `J` as `+0000`, and trailing nested parenthesized comments. Whitespace after the last field or comment and a leap second (`:60`) are rejected. Raises `InvalidRfc2822` on any mismatch |
| `to_http_date(DateTime[Tz])` | `-> String raise FormatError` | Renders the UTC instant as an IMF-fixdate (RFC 9110 section 5.6.7): `"<short weekday>, <DD> <short month> <YYYY> <HH>:<MM>:<SS> GMT"` (e.g. `"Sun, 06 Nov 1994 08:49:37 GMT"`), fixed width with a zero-padded day. Accepts any `Tz`. A fractional second is dropped and a leap second is written as `:60`. Raises `InvalidHttpDate` if the year is outside `0..=9999` |
| `parse_http_date(String, reference_year? : Int)` | `-> DateTime[Utc] raise FormatError` | Reads IMF-fixdate and, as HTTP recipients must, the obsolete RFC 850 (`"Sunday, 06-Nov-94 08:49:37 GMT"`) and `asctime` (`"Sun Nov  6 08:49:37 1994"`) forms; only IMF-fixdate is written. Every form is exact: English names with their capitalisation, fixed widths, single spaces, `GMT` as the only zone, and a weekday that matches the date. A leap second (`:60`) is not read back, as with `parse_rfc2822`. Raises `InvalidHttpDate` on any mismatch |
| `parse_duration(String)` | `-> TimeDelta raise FormatError` | Parses one or more `<number><unit>` components with an optional leading sign (`"1h30m"`, `"-1.5s"`, `"300ms"`, `".5s"`, `"1.5h"`). Units are `ns`, `us` (also `µs` U+00B5 and `μs` U+03BC), `ms`, `s`, `m`, `h`, case-sensitive, with hours the largest (no days/weeks); components are summed. A bare `"0"` (optionally signed) needs no unit. Fractional digits beyond the ninth, and precision finer than a nanosecond, are truncated toward zero. The inverse of `TimeDelta`'s `Show`. Raises `InvalidDuration` for malformed input or a value outside `TimeDelta`'s range |
| `parse_fixed_offset(String)` | `-> FixedOffset raise FormatError` | Parses a whole offset string: `±HH:MM:SS`, `±HH:MM`, `±HHMM`, `±HH`, or `Z`/`z` for zero. Raises `InputMismatch` for any other text (including minutes or seconds above 59) and `FieldOutOfRange` for a well-shaped offset beyond `±23:59:59` |
| `parse_date_default(String)` / `parse_time_default(String)` / `parse_date_time_default(String)` | `-> NaiveDate` / `NaiveTime` / `NaiveDateTime raise FormatError` | Parse exactly the text `Show` renders: `YYYY-MM-DD` (`-` for a negative year, `+` beyond 9999); `HH:MM:SS` with an optional fraction of any number of digits and a leap second as `:60`; a date and time joined by one space. Same failures as `parse_date`/`parse_time`/`parse_date_time` |
| `parse_date_time_utc_default(String)` | `-> DateTime[Utc] raise FormatError` | `parse_date_time_default`'s layout followed by a space and `UTC`: the inverse of `Show` for `DateTime[Utc]` |
| `parse_date_time_fixed_offset_default(String)` | `-> DateTime[FixedOffset] raise FormatError` | `parse_date_time_default`'s layout followed by a space and an offset as `parse_fixed_offset` reads it; the written clock is local time in that offset. The inverse of `Show` for `DateTime[FixedOffset]`; an IANA zone's abbreviation or a `FixedZone`'s name is not read back |

`parse_http_date` returns `DateTime[Utc]` because an HTTP date is always GMT. RFC 850's two-digit year follows `reference_year` when it is given: a year more than 50 years after it reads as the most recent past year with the same last two digits (RFC 9110's rule), so `parse_http_date("Sunday, 06-Nov-94 08:49:37 GMT", reference_year=2024)` reads 1994 and `"...-30 ..."` reads 2030. Without it the fixed `%y` pivot applies (`< 70` is 20xx, `>= 70` is 19xx), which ages: after 2070 it disagrees with that rule, so a caller reading live traffic should pass the current year.

### Named layouts

Convenience format-string constants, declared `const` (hence the upper-case names). Each is just a `String` — pass one to `format_date`/`format_time`/`format_date_time`/`format_date_time_tz`, or their `parse_*` counterparts, like any other format string.

| Constant | Format string | Example |
| :--- | :--- | :--- |
| `ANSIC` | `"%a %b %e %H:%M:%S %Y"` | `"Tue Mar  5 09:05:03 2024"` |
| `UNIX_DATE` | `"%a %b %e %H:%M:%S %Z %Y"` | `"Tue Mar  5 09:05:03 UTC 2024"` |
| `RUBY_DATE` | `"%a %b %d %H:%M:%S %z %Y"` | `"Tue Mar 05 18:05:03 +0900 2024"` |
| `KITCHEN` | `"%-I:%M%p"` | `"9:05AM"` |
| `STAMP` | `"%b %e %H:%M:%S"` | `"Mar  5 09:05:03"` |
| `STAMP_MILLI` | `"%b %e %H:%M:%S.%3f"` | `"Mar  5 09:05:03.123"` |
| `STAMP_MICRO` | `"%b %e %H:%M:%S.%6f"` | `"Mar  5 09:05:03.123456"` |
| `STAMP_NANO` | `"%b %e %H:%M:%S.%9f"` | `"Mar  5 09:05:03.123456789"` |
| `DATE_ONLY` | `"%F"` | `"2024-03-05"` |
| `TIME_ONLY` | `"%T"` | `"09:05:03"` |
| `DATE_TIME` | `"%F %T"` | `"2024-03-05 09:05:03"` |

The RFC shapes have no constants: `to_rfc2822`/`parse_rfc2822` and `to_rfc3339`/`parse_rfc3339` are the exact implementations, and a caller who wants another shape writes its format string (for example `"%a, %d %b %Y %H:%M:%S %z"`, the RFC 2822 layout with a numeric offset).

The `STAMP*` family (no year) doesn't carry enough fields to round-trip through the matching `parse_*` function on its own; read it with `parse_items` and `Parsed::with_default_year`, which supplies the missing year. `DATE_ONLY`/`TIME_ONLY` are self-sufficient for parsing, and so is `KITCHEN` for a time on the minute, since `parse_time` reads a time without seconds as having zero seconds (a value with seconds loses them when rendered with `KITCHEN`).

### `tokenize`

| Function | Signature | Description |
| :--- | :--- | :--- |
| `tokenize(String)` | `-> Array[Item] raise FormatError` | Parses a `%`-specifier format string into a sequence of `Item`s; raises `UnknownSpecifier`/`TrailingPercent` on a malformed format string. Not usually needed directly — `format_*`/`parse_*` call it internally |
| `format_date_items(NaiveDate, Array[Item])` / `format_time_items(NaiveTime, Array[Item])` / `format_date_time_items(NaiveDateTime, Array[Item])` / `format_date_time_tz_items(DateTime[Tz], Array[Item])` *(Tz : TimeZone)* | `-> String raise FormatError` | The `format_*` functions against an already-tokenized (or hand-built) `Item` sequence; `format_*` is `tokenize` followed by these |
| `parse_items(String, Array[Item])` | `-> Parsed raise FormatError` | Walks an `Item` sequence against the whole input (`InputMismatch` on a mismatch, `InputTooShort` if the input ends first, `TrailingInput` on leftover input), accumulating fields without resolving them |
| `parse_items_and_remainder(String, Array[Item])` | `-> (Parsed, String) raise FormatError` | Like `parse_items`, but returns leftover input instead of rejecting it |
| `Parsed::to_date()` / `to_time()` / `to_date_time()` | `-> NaiveDate` / `NaiveTime` / `NaiveDateTime raise FormatError` | Resolve the accumulated fields; `IncompleteFields` if too few were parsed, `FieldOutOfRange` if a value is outside its range (an hour of 24, February 30), `InconsistentFields` if fields contradict each other. One `Parsed` resolves any number of ways |
| `Parsed::utc_offset()` | `-> Int?` | The offset, in seconds, that a `%z`-family specifier read, or `None`; the raw reading, rejected only on resolution if beyond `±23:59:59`. Tells a caller whether to resolve with `to_date_time_fixed_offset` or `to_date_time_in` |
| `Parsed::with_default_year(Int)` | `-> Parsed` | Returns a copy that reads the given year when the input named none (`%Y`, `%y`, `%C`, an ISO week year and `%s` are never overridden, and a partial year such as a lone `%C` is not completed), so a yearless layout such as `STAMP` resolves. The year still takes part in the usual checks: a leap day needs a leap year, and a weekday must match the date. The original `Parsed` is unchanged |
| `Parsed::zone_name()` | `-> String?` | The text `%Z` read, as written and unvalidated, or `None`; otherwise visible only through `parse_date_time_in` |
| `Parsed::to_date_time_fixed_offset()` | `-> DateTime[FixedOffset] raise FormatError` | Resolve the date, time and `%z` offset, reading the fields as that offset's local time |
| `Parsed::to_date_time_in(Tz)` *(Tz : TimeZone)* | `-> MappedLocalTime[DateTime[Tz]] raise FormatError` | Resolve a zone-less reading in `tz`; see `parse_date_time_in` for `%Z` handling and the offset rejection |

### `Item`, `Numeric`, `Fixed`, `PadMode`

The token types produced by `tokenize`.

`Rfc2822` is the one `Item` that no format-string specifier produces; build it directly for `format_date_time_tz_items`, `parse_items` and the like. It renders as `to_rfc2822` does and reads as `parse_rfc2822_lenient` does (the obsolete syntax, and a trailing run of comments, included); like `%+`, it needs a date, time and offset together, a year outside `0..=9999` raises `InvalidRfc2822` on render, and text that is not an RFC 2822 date-time raises `InputMismatch` on parse.

```mbt nocheck
///|
pub(all) enum Item {
  Literal(String)
  Numeric(Numeric)
  Fixed(Fixed)
  Rfc3339
  Rfc2822
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
  Nanosecond9
  Hour12
  Hour12Blank
  HourBlank
  Timestamp
  IsoYear
  IsoYearMod100
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

### `FormatError`

`FormatError` is the error type of the whole package: it reports a bad format string and a failed parse, and equally a failed render (`MissingField`, `ParseOnly`, `InvalidRfc2822`). It was called `ParseError` until its role in rendering made that name misleading.

| Variant | Raised when |
| :--- | :--- |
| `UnknownSpecifier(Char)` | `tokenize` encounters an unrecognized `%`-specifier |
| `TrailingPercent` | A format string ends with a bare `%` |
| `MissingField(Item)` | A `format_*` call is asked to render a specifier its input type can't supply (e.g. `%Z` via `format_date_time`) |
| `ParseOnly(Item)` | A `format_*` call is given a specifier that can only be parsed (`%#z`); `tokenize` and the `parse_*` functions accept it, since the format string alone does not say which direction it serves |
| `InvalidRfc3339` | `parse_rfc3339` fails to match the RFC 3339 grammar |
| `InvalidIso8601` | `parse_iso8601` fails to match any accepted shape |
| `InvalidRfc2822` | `to_rfc2822`'s year is outside `0..=9999`, or `parse_rfc2822`/`parse_rfc2822_lenient` fails to match its RFC 2822 grammar |
| `InvalidHttpDate` | `to_http_date`'s year is outside `0..=9999`, or `parse_http_date` fails to match one of the three HTTP date shapes, names a weekday that does not match the date, or names a zone other than `GMT` |
| `InvalidDuration` | `parse_duration`'s input is malformed (no digits, missing or unknown unit, misplaced sign, stray characters) or its value is outside `TimeDelta`'s representable range |
| `IncompleteFields` | A `parse_*` call resolves fields that never populate a required value (e.g. no year) |
| `InconsistentFields` | Two populated fields contradict each other (e.g. `%j` or a weekday name disagreeing with the date, two `%H` readings), or an offset is given to `Parsed::to_date_time_in` |
| `FieldOutOfRange` | A parsed value is outside what its field can hold, so no value can be built (an hour of 24, February 30, an ISO week that does not exist in its year, an offset beyond `±23:59:59`) |
| `InputMismatch` | Literal or specifier text fails to match the input |
| `InputTooShort` | The input is exhausted when the format still has an item to match (e.g. `"2024-03"` against `%F`); a partial field such as one digit for `%m` is `InputMismatch` |
| `TrailingInput` | The format is fully matched but input remains after it; the `_and_remainder` functions return that tail instead |

`FormatError` also implements `Eq` and `Show`, which renders a one-line message per variant (e.g. `input does not match the format`; `MissingField` and `ParseOnly` append the item's `Debug` form).
