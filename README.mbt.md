# almanac

[![CI](https://github.com/connect0459/almanac/actions/workflows/ci.yml/badge.svg)](https://github.com/connect0459/almanac/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://github.com/connect0459/almanac/blob/main/LICENSE)
[![docs](https://img.shields.io/badge/docs-mooncakes.io-green)](https://mooncakes.io/docs/connect0459/almanac)

A date and time library for MoonBit: calendar and clock values, durations, IANA time zones, `strftime`-style formatting and parsing, and cron schedules.

## Packages

| Package | Import alias | Description |
| :--- | :--- | :--- |
| `connect0459/almanac` | `@almanac` | Re-exports of the everyday types: `Weekday`, `Month`, `NaiveDate`, `NaiveTime`, `NaiveDateTime`, `TimeDelta`, `TimeZone`, `Utc`, `FixedOffset`, `Location`, `DateTime`, `MappedLocalTime` |
| `connect0459/almanac/core` | `@core` | Calendar and clock primitives with no time zone: `NaiveDate`, `NaiveTime`, `NaiveDateTime`, `TimeDelta`, `Weekday`, `WeekdaySet`, `Month`, `IsoWeek`, `NaiveWeek` |
| `connect0459/almanac/tz` | `@tz` | Time zones: the `TimeZone` trait, `Utc`, `FixedOffset`, `FixedZone`, `Location` (embedded IANA tz database), `PosixTz`, `DateTime[Tz]`, `MappedLocalTime`, and `Local` (the host's zone) |
| `connect0459/almanac/format` | `@format` | `strftime`-style formatting and parsing, RFC 3339, RFC 2822 and HTTP dates, plus the default-layout and duration parsers |
| `connect0459/almanac/cron` | `@cron` | Cron expressions: `Cron::parse`, then `matches` and `next` over a zoned `DateTime[Tz]` |

## Installation

```sh
moon add connect0459/almanac
```

Then declare the packages you need in your `moon.pkg`:

```mbt nocheck
import {
  "connect0459/almanac",         // everyday types
  "connect0459/almanac/format",  // formatting and parsing
  // "connect0459/almanac/core",
  // "connect0459/almanac/tz",
  // "connect0459/almanac/cron",
}
```

`@core` is also the default alias of the standard library's `moonbitlang/core`. The root package README shows how to import a package under another alias.

## Usage

Build a zoned value, format it, and ask a cron schedule for its next fire time:

```mbt nocheck
///|
test {
  let tokyo = @tz.Location::load("Asia/Tokyo").unwrap()
  let dt = @tz.DateTime::from_ymd_hms(2024, 3, 8, 9, 40, 0, tokyo)
    .single()
    .unwrap()
  assert_eq(@format.to_rfc3339(dt), "2024-03-08T09:40:00+09:00")
  let weekdays = @cron.Cron::parse("30 9 * * mon-fri")
  let next = weekdays.next(dt).unwrap()
  assert_eq(@format.to_rfc3339(next), "2024-03-11T09:30:00+09:00")
}
```

A local reading can fall in a DST gap or fold, so constructors from local components return a `MappedLocalTime` that you reduce with `single`, `earliest` or `latest`.

## Compatibility

- The library is tested on the `js`, `wasm`, `wasm-gc` and `native` backends. `Local`, the host's zone, is read from `$TZ` or `/etc/localtime` on `native`, from the runtime's `Intl` zone name on `js`, and from `$TZ` alone on `wasm` and `wasm-gc`.
- The embedded tz database is a snapshot; regenerate it with `just gen-tzdata <zoneinfo dir>`.
- While the major version is `0`, a minor release may contain breaking changes to the public API.

## Documentation

Each public package has a `README.mbt.md` with a key-types overview, usage examples and a full API reference. Start with `core` for the value types and `tz` for zones.

## Contributing

See [CONTRIBUTING.md](https://github.com/connect0459/almanac/blob/main/CONTRIBUTING.md).

## License

[Apache-2.0](https://github.com/connect0459/almanac/blob/main/LICENSE)
