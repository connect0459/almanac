# `cron` package

Cron schedules evaluated against zoned datetimes. Import `connect0459/almanac/cron` for `Cron::parse`, `Cron::matches` and `Cron::next`; it depends on `core` and `tz` only.

## Key types

| Type | Description |
| :--- | :--- |
| `Cron` | A parsed schedule of whole-second instants. An immutable value with private fields; implements `Eq`, `Hash` and `Debug`. It has no `Show`, since the original text is not kept |
| `CronError` | The `suberror` raised by `Cron::parse`: `InvalidField(CronField)` |
| `CronField` | The part that could not be read: `Second`, `Minute`, `Hour`, `DayOfMonth`, `MonthField`, `DayOfWeek`, `FieldCount` or `Shorthand`. A `pub(all)` enum, so a new variant is a breaking change |

## Key functions

| Function | Signature | Description |
| :--- | :--- | :--- |
| `Cron::parse(String)` | `-> Cron raise CronError` | Reads five fields (`minute hour day-of-month month day-of-week`), six with seconds in front, or a shorthand. Raises `InvalidField` naming the first field that cannot be read |
| `Cron::matches(Cron, DateTime[Tz])` *(Tz : TimeZone)* | `-> Bool` | Whether the instant is a fire time, judged by the wall clock of the value's own zone |
| `Cron::next(Cron, DateTime[Tz])` *(Tz : TimeZone)* | `-> DateTime[Tz]?` | The first fire time strictly after the given instant, in the same zone, with a whole-second time |

## Expression grammar

Fields are separated by runs of spaces or tabs. A five-field expression fires at second `0`.

| Field | Values | Names |
| :--- | :--- | :--- |
| second (six-field form only) | `0..=59` | |
| minute | `0..=59` | |
| hour | `0..=23` | |
| day of month | `1..=31`, `?` | |
| month | `1..=12` | `JAN`..`DEC` |
| day of week | `0..=7` (`0` and `7` are Sunday), `?` | `SUN`..`SAT` |

Each field is a comma list of `*`, `n`, `a-b`, `*/n` and `a-b/n` (`n` in a step is at least `1`); names are case-insensitive and may form ranges. `?` is `*` and is accepted only in the two day fields. `a/n` and ranges that wrap (`5-1`) are rejected. The shorthands are `@yearly` (`0 0 1 1 *`), `@monthly` (`0 0 1 * *`), `@weekly` (`0 0 * * 0`), `@daily` (`0 0 * * *`) and `@hourly` (`0 * * * *`).

## Day-of-month and day-of-week

When both day fields are restricted, a day matches if **either** does: `0 0 13 * 5` fires on every 13th and on every Friday, not only on Friday the 13th. When either field begins with `*` or is `?`, a day must match **both**, so `0 0 */2 * 5` fires on Fridays that fall on an odd day of the month.

## Time zones

`matches` and `next` read the wall clock of the zone carried by the `DateTime`, so `0 9 * * *` means 09:00 in that zone.

- A fire time inside a spring-forward gap does not exist and is skipped.
- A fire time inside a fall-back fold fires once, at the earlier occurrence; `matches` is `false` for the later one, and `next` never returns an instant at or before its argument.
- A fractional second of the argument is ignored by `matches`, and `next` returns the first fire time after it.

`next` searches the 400 years after the argument, the cycle of the Gregorian calendar, and returns `None` when an expression names no day in it (`0 0 30 2 *`) or the search leaves the representable dates.

## Example

```mbt check
///|
test {
  let cron = @cron.Cron::parse("30 9 * * mon-fri")
  let utc = @tz.Utc::new()
  let friday = @tz.DateTime::from_timestamp(1_709_890_800L, 0, utc).unwrap()
  assert_eq(friday.to_string(), "2024-03-08 09:40:00 UTC")
  let monday = cron.next(friday).unwrap()
  assert_eq(monday.to_string(), "2024-03-11 09:30:00 UTC")
}
```
