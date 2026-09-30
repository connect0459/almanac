# `connect0459/chrono` (root package)

A thin entry point over the three packages below. Importing this package alone gives the everyday date, time, duration and zoned-datetime types; the functions and the rest of each API live in the packages that define them.

| Package | Import | Contents |
| :--- | :--- | :--- |
| `connect0459/chrono` | `@chrono` | Re-exports of the everyday types (see below) |
| `connect0459/chrono/core` | `@core` | Calendar and clock primitives with no time zone: `Weekday`, `WeekdaySet`, `Month`, `IsoWeek`, `NaiveDate`, `NaiveWeek`, `NaiveTime`, `TimeDelta`, `NaiveDateTime`, `RoundingError` |
| `connect0459/chrono/tz` | `@tz` | Time zones: the `TimeZone` trait, `Utc`, `FixedOffset`, `FixedZone`, `Location` (IANA tzdata), `PosixTz`, `DateTime[Tz]`, `MappedLocalTime` |
| `connect0459/chrono/format` | `@format` | `strftime`-style formatting and parsing, RFC 2822 and RFC 3339, plus the default-layout and duration parsers |

## Re-exported types

`Weekday`, `Month`, `NaiveDate`, `NaiveTime`, `NaiveDateTime` and `TimeDelta` (from `core`), and `TimeZone`, `Utc`, `FixedOffset`, `Location`, `DateTime` and `MappedLocalTime` (from `tz`). They are aliases of the original types, so a value from `@chrono` is interchangeable with the same type from `@core` or `@tz`. Functions such as `format_date_time` and `parse_rfc3339` are not re-exported; import `connect0459/chrono/format` for them.

## Quick start

```mbt check
///|
test {
  let date = @chrono.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @chrono.NaiveTime::from_hms(9, 5, 7).unwrap()
  let naive = @chrono.NaiveDateTime::new(date, time)
  assert_eq(naive.to_string(), "2024-03-05 09:05:07")
  let tokyo = @chrono.FixedOffset::east(9 * 3600).unwrap()
  let dt = @chrono.DateTime::from_timestamp(0L, 0, tokyo).unwrap()
  assert_eq(dt.hour(), 9)
}
```

## Package aliases

A package imported as `connect0459/chrono/core` is referred to as `@core` by default. That is also the name of the standard library's `moonbitlang/core`, so a project that mentions both can give this one its own alias in `moon.pkg`:

```text
import {
  "connect0459/chrono/core" @chrono_core,
  "connect0459/chrono/tz" @chrono_tz,
}
```
