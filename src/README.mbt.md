# `connect0459/almanac` (root package)

A thin entry point over the packages below. Importing this package alone gives the everyday date, time, duration and zoned-datetime types; the functions and the rest of each API live in the packages that define them.

| Package | Import | Contents |
| :--- | :--- | :--- |
| `connect0459/almanac` | `@almanac` | Re-exports of the everyday types (see below) |
| `connect0459/almanac/core` | `@core` | Calendar and clock primitives with no time zone: `Weekday`, `WeekdaySet`, `Month`, `IsoWeek`, `NaiveDate`, `NaiveWeek`, `NaiveTime`, `TimeDelta`, `NaiveDateTime`, `RoundingError` |
| `connect0459/almanac/tz` | `@tz` | Time zones: the `TimeZone` trait, `Utc`, `FixedOffset`, `FixedZone`, `Location` (IANA tzdata), `PosixTz`, `DateTime[Tz]`, `MappedLocalTime`, and on the `native` backend only, `Local` (the host's zone) |
| `connect0459/almanac/format` | `@format` | `strftime`-style formatting and parsing, RFC 2822 and RFC 3339, plus the default-layout and duration parsers |
| `connect0459/almanac/cron` | `@cron` | Cron expressions: `Cron::parse`, then `matches` and `next` over a zoned `DateTime[Tz]` |

## Re-exported types

`Weekday`, `Month`, `NaiveDate`, `NaiveTime`, `NaiveDateTime` and `TimeDelta` (from `core`), and `TimeZone`, `Utc`, `FixedOffset`, `Location`, `DateTime` and `MappedLocalTime` (from `tz`). They are aliases of the original types, so a value from `@almanac` is interchangeable with the same type from `@core` or `@tz`. Functions such as `format_date_time` and `parse_rfc3339` are not re-exported; import `connect0459/almanac/format` for them.

## Quick start

```mbt check
///|
test {
  let date = @almanac.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @almanac.NaiveTime::from_hms(9, 5, 7).unwrap()
  let naive = @almanac.NaiveDateTime::new(date, time)
  assert_eq(naive.to_string(), "2024-03-05 09:05:07")
  let tokyo = @almanac.FixedOffset::east(9 * 3600).unwrap()
  let dt = @almanac.DateTime::from_timestamp(0L, 0, tokyo).unwrap()
  assert_eq(dt.hour(), 9)
}
```

## Package aliases

A package imported as `connect0459/almanac/core` is referred to as `@core` by default. That is also the name of the standard library's `moonbitlang/core`, so a project that mentions both can give this one its own alias in `moon.pkg`:

```text
import {
  "connect0459/almanac/core" @almanac_core,
  "connect0459/almanac/tz" @almanac_tz,
}
```
