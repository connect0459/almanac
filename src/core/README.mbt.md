# `core` package

Calendar and clock primitives with no time zone awareness. Import `connect0459/chrono/core` for `Weekday`, `WeekdaySet`, `Month`, `IsoWeek`, `NaiveDate`, `NaiveTime`, `TimeDelta`, and `NaiveDateTime`. The `tz` package layers a time zone on top of `NaiveDateTime`.

## Key types

| Type | Description |
| :--- | :--- |
| `Weekday` | Cyclic day-of-week enum (`Mon`..`Sun`) |
| `WeekdaySet` | An immutable set of `Weekday` values, stored as a bitset |
| `Month` | Cyclic month enum (`Jan`..`Dec`) |
| `IsoWeek` | ISO 8601 week-numbering year and week |
| `NaiveDate` | A proleptic Gregorian calendar date, no time zone |
| `NaiveTime` | A time of day, precise to the nanosecond, with leap-second support |
| `TimeDelta` | A signed duration, precise to the nanosecond |
| `NaiveDateTime` | A `NaiveDate` and `NaiveTime` combined into one zone-less instant |

## Quick start

Constructing a date and reading its calendar fields:

```mbt check
///|
test {
  let date = @core.NaiveDate::from_ymd(2024, 2, 29).unwrap()
  assert_eq(date.month(), @core.Feb)
  assert_eq(date.weekday(), @core.Thu)
  assert_eq(@core.NaiveDate::from_ymd(2023, 2, 29), None)
}
```

`TimeDelta::round`/`truncate` snap a duration to a multiple of a granularity: `truncate` always moves toward zero, while `round` breaks an exact halfway tie by moving away from zero:

```mbt check
///|
test {
  let half_hour = @core.TimeDelta::minutes(30L).unwrap()
  let hour = @core.TimeDelta::hours(1L).unwrap()
  assert_eq(half_hour.round(hour), Some(hour))
  assert_eq(half_hour.truncate(hour), Some(@core.TimeDelta::zero()))
}
```

`NaiveDateTime::round`/`truncate` measure that granularity since the Unix epoch, so truncating a datetime *before* the epoch moves it *forward* in time, toward the epoch, not further into the past:

```mbt check
///|
test {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1969, 12, 31).unwrap(),
    @core.NaiveTime::from_hms(14, 45, 30).unwrap(),
  )
  let truncated = dt.truncate(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(truncated.time(), @core.NaiveTime::from_hms(15, 0, 0).unwrap())
}
```

## API reference

### Free functions

| Function | Signature | Description |
| :--- | :--- | :--- |
| `is_leap_year(Int)` | `-> Bool` | Standard 4/100/400 leap-year rule |
| `days_from_civil(Int, Int, Int)` | `-> Int` | `(year, month, day)` to a day count since `1970-01-01` |
| `civil_from_days(Int)` | `-> (Int, Int, Int)` | Inverse of `days_from_civil` |

---

### `Weekday`

`Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `succ()` | `-> Self` | Next day, wrapping `Sun` to `Mon` |
| `pred()` | `-> Self` | Previous day, wrapping `Mon` to `Sun` |
| `number_from_monday()` | `-> Int` | 1-based, `Mon` is `1` |
| `number_from_sunday()` | `-> Int` | 1-based, `Sun` is `1` |
| `num_days_from_monday()` | `-> Int` | 0-based, `Mon` is `0` |
| `num_days_from_sunday()` | `-> Int` | 0-based, `Sun` is `0` |
| `days_since(Weekday)` | `-> Int` | Days elapsed since `other`, counting forward |

`Weekday` also implements `Eq`.

---

### `WeekdaySet`

An immutable set of `Weekday` values. Every mutating-looking operation (`insert`, `remove`) returns a new set rather than changing `self` in place.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `WeekdaySet::empty()` | `-> Self` | The empty set |
| `WeekdaySet::all()` | `-> Self` | The set containing all seven weekdays |
| `WeekdaySet::single(Weekday)` | `-> Self` | A set containing exactly one weekday |
| `WeekdaySet::from_array(Array[Weekday])` | `-> Self` | A set containing exactly the given weekdays |
| `single_day()` | `-> Weekday?` | The one member, if the set has exactly one; `None` otherwise |
| `insert(Weekday)` | `-> Self` | The set with a weekday added |
| `remove(Weekday)` | `-> Self` | The set with a weekday removed |
| `contains(Weekday)` | `-> Bool` | Whether a weekday is a member |
| `is_subset(Self)` | `-> Bool` | Whether every member of `self` is also in `other` |
| `union(Self)` | `-> Self` | Members in either set |
| `intersection(Self)` | `-> Self` | Members in both sets |
| `difference(Self)` | `-> Self` | Members in `self` but not in `other` |
| `symmetric_difference(Self)` | `-> Self` | Members in exactly one of the two sets |
| `first()` | `-> Weekday?` | The earliest member, starting from `Mon`; `None` if empty |
| `last()` | `-> Weekday?` | The latest member, starting from `Sun`; `None` if empty |
| `is_empty()` | `-> Bool` | Whether the set has no members |
| `length()` | `-> Int` | The number of members |
| `to_array()` | `-> Array[Weekday]` | Members in `Mon..Sun` order |

`WeekdaySet` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `Month`

`Jan`, `Feb`, `Mar`, `Apr`, `May`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `succ()` | `-> Self` | Next month, wrapping `Dec` to `Jan` |
| `pred()` | `-> Self` | Previous month, wrapping `Jan` to `Dec` |
| `number_from_month()` | `-> Int` | 1-based, `Jan` is `1` |
| `name()` | `-> String` | Full English name, e.g. `"February"` |
| `num_days(Int)` | `-> Int` | Number of days in this month for the given year |

`Month` also implements `Eq`.

---

### `IsoWeek`

| Method | Signature | Description |
| :--- | :--- | :--- |
| `year()` | `-> Int` | ISO 8601 week-numbering year (can differ from the calendar year near a year boundary) |
| `week()` | `-> Int` | 1-based week number within that year |
| `week0()` | `-> Int` | 0-based week number |

`IsoWeek` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `NaiveDate`

A proleptic Gregorian calendar date. Constructors are `Option`-returning: an invalid combination reports `None` rather than clamping.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveDate::from_ymd(Int, Int, Int)` | `-> Self?` | From year, month, day |
| `NaiveDate::from_yo(Int, Int)` | `-> Self?` | From year and ordinal day (`1..=365`/`366`) |
| `NaiveDate::from_isoywd(Int, Int, Weekday)` | `-> Self?` | From ISO week-numbering year, week, and weekday |
| `year()` | `-> Int` | Calendar year |
| `month()` | `-> Month` | Calendar month |
| `day()` | `-> Int` | Day of month |
| `ordinal()` | `-> Int` | Day of year, 1-based |
| `weekday()` | `-> Weekday` | Day of week |
| `iso_week()` | `-> IsoWeek` | ISO 8601 week-numbering year and week |
| `leap_year()` | `-> Bool` | Whether this date's year is a leap year |
| `with_year(Int)` | `-> Self?` | Same month/day in a different year; `None` if that combination is invalid (e.g. Feb 29 into a non-leap year) |
| `with_month(Int)` | `-> Self?` | Same year/day in a different month; `None` if the day doesn't exist in that month |
| `with_day(Int)` | `-> Self?` | Same year/month with a different day |
| `with_ordinal(Int)` | `-> Self?` | Same year with a different ordinal day |
| `succ()` | `-> Self` | The next day |
| `pred()` | `-> Self` | The previous day |
| `add_days(Int)` | `-> Self` | Shift forward (or back, if negative) by a day count |
| `sub_days(Int)` | `-> Self` | Shift backward by a day count |
| `add_months(Int)` | `-> Self` | Shift by whole months, clamping the day of month to the target month's length |
| `sub_months(Int)` | `-> Self` | Shift backward by whole months, with the same clamping |

`NaiveDate` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `NaiveTime`

A time of day, precise to the nanosecond. Constructors are `Option`-returning. Supports leap seconds: a nanosecond component `>= 1_000_000_000` at `second() == 59` represents one — `second()` never itself reports `60`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveTime::from_hms(Int, Int, Int)` | `-> Self?` | From hour, minute, second |
| `NaiveTime::from_hms_milli(Int, Int, Int, Int)` | `-> Self?` | With a millisecond component |
| `NaiveTime::from_hms_micro(Int, Int, Int, Int)` | `-> Self?` | With a microsecond component |
| `NaiveTime::from_hms_nano(Int, Int, Int, Int)` | `-> Self?` | With a nanosecond component (`0..=1_999_999_999`, the upper half representing a leap second) |
| `NaiveTime::from_num_seconds_from_midnight(Int, Int)` | `-> Self?` | From a seconds-since-midnight count plus a nanosecond component |
| `hour()` | `-> Int` | Hour, `0..=23` |
| `minute()` | `-> Int` | Minute, `0..=59` |
| `second()` | `-> Int` | Second, `0..=59` (never `60`; see leap seconds above) |
| `nanosecond()` | `-> Int` | Nanosecond component, `0..=1_999_999_999` |
| `hour12()` | `-> (Bool, Int)` | 12-hour clock hour and PM flag, wrapping midnight/noon to `12` |
| `num_seconds_from_midnight()` | `-> Int` | Seconds elapsed since midnight |
| `overflowing_add_signed(TimeDelta)` | `-> (Self, Int64)` | Add a duration, wrapping at midnight; also reports the number of days crossed |
| `overflowing_sub_signed(TimeDelta)` | `-> (Self, Int64)` | Subtract a duration, with the same wrapping and day-count report |

`NaiveTime` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `TimeDelta`

A signed duration, precise to the nanosecond. Constructors and checked arithmetic are `Option`-returning, reporting `None` on overflow or invalid input.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `TimeDelta::weeks(Int64)` | `-> Self?` | Whole weeks |
| `TimeDelta::days(Int64)` | `-> Self?` | Whole days |
| `TimeDelta::hours(Int64)` | `-> Self?` | Whole hours |
| `TimeDelta::minutes(Int64)` | `-> Self?` | Whole minutes |
| `TimeDelta::seconds(Int64)` | `-> Self?` | Whole seconds |
| `TimeDelta::milliseconds(Int64)` | `-> Self?` | Whole milliseconds |
| `TimeDelta::microseconds(Int64)` | `-> Self?` | Whole microseconds |
| `TimeDelta::nanoseconds(Int64)` | `-> Self?` | Whole nanoseconds |
| `TimeDelta::zero()` | `-> Self` | The zero-length duration |
| `TimeDelta::min_value()` | `-> Self` | The most negative representable duration |
| `TimeDelta::max_value()` | `-> Self` | The most positive representable duration |
| `num_weeks()` | `-> Int64` | Whole weeks, truncated toward zero |
| `num_days()` | `-> Int64` | Whole days, truncated toward zero |
| `num_hours()` | `-> Int64` | Whole hours, truncated toward zero |
| `num_minutes()` | `-> Int64` | Whole minutes, truncated toward zero |
| `num_seconds()` | `-> Int64` | Whole seconds, truncated toward zero |
| `num_milliseconds()` | `-> Int64` | Whole milliseconds, truncated toward zero; always succeeds |
| `num_microseconds()` | `-> Int64?` | Whole microseconds, truncated toward zero; `None` if it overflows `Int64` |
| `num_nanoseconds()` | `-> Int64?` | Whole nanoseconds; `None` if it overflows `Int64` |
| `subsec_nanoseconds()` | `-> Int` | Nanosecond remainder, signed to match the overall duration |
| `subsec_milliseconds()` | `-> Int` | `subsec_nanoseconds()` in whole milliseconds |
| `subsec_microseconds()` | `-> Int` | `subsec_nanoseconds()` in whole microseconds |
| `add(TimeDelta)` | `-> Self?` | Sum; `None` on overflow |
| `sub(TimeDelta)` | `-> Self?` | Difference; `None` on overflow |
| `mul(Int)` | `-> Self?` | Scale by an integer scalar; `None` on overflow |
| `div(Int)` | `-> Self?` | Divide by an integer scalar, truncated toward zero; `None` if the scalar is zero |
| `neg()` | `-> Self` | Negation |
| `abs()` | `-> Self` | Absolute value |
| `is_zero()` | `-> Bool` | Whether this duration is exactly zero |
| `round(TimeDelta)` | `-> Self?` | Round to the nearest multiple of a granularity, ties breaking away from zero; `None` if the granularity is zero, negative, or mixes a whole-second part with a sub-second remainder (e.g. 1.5 seconds — every named duration unit is either purely sub-second or a whole-second-or-larger multiple) |
| `truncate(TimeDelta)` | `-> Self?` | Truncate toward zero to the nearest multiple of a granularity; same granularity restriction as `round` |

`TimeDelta` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `NaiveDateTime`

A `NaiveDate` and `NaiveTime` combined into one zone-less instant.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveDateTime::new(NaiveDate, NaiveTime)` | `-> Self` | Compose a date and a time of day |
| `NaiveDateTime::from_timestamp(Int64, Int)` | `-> Self?` | From a Unix timestamp (whole seconds) plus a nanosecond component (`0..=1_999_999_999`) |
| `NaiveDateTime::from_timestamp_millis(Int64)` | `-> Self?` | From a Unix timestamp in whole milliseconds |
| `NaiveDateTime::from_timestamp_micros(Int64)` | `-> Self?` | From a Unix timestamp in whole microseconds |
| `NaiveDateTime::from_timestamp_nanos(Int64)` | `-> Self?` | From a Unix timestamp in whole nanoseconds |
| `date()` | `-> NaiveDate` | The date component |
| `time()` | `-> NaiveTime` | The time-of-day component |
| `timestamp()` | `-> Int64` | Unix timestamp in whole seconds, truncated toward negative infinity |
| `timestamp_millis()` | `-> Int64` | Unix timestamp in whole milliseconds; always succeeds |
| `timestamp_micros()` | `-> Int64?` | Unix timestamp in whole microseconds; `None` if it overflows `Int64` (a date far from the epoch) |
| `timestamp_nanos()` | `-> Int64?` | Unix timestamp in whole nanoseconds; same overflow caveat |
| `timestamp_subsec_nanos()` | `-> Int` | Nanosecond component of this instant |
| `timestamp_subsec_millis()` | `-> Int` | That component in whole milliseconds |
| `timestamp_subsec_micros()` | `-> Int` | That component in whole microseconds |
| `add_signed(TimeDelta)` | `-> Self` | Advance by a signed duration, propagating any day overflow into the date |
| `sub_signed(TimeDelta)` | `-> Self` | Move back by a signed duration |
| `add_months(Int)` | `-> Self` | Shift the date by whole months, keeping the time of day |
| `sub_months(Int)` | `-> Self` | Shift the date backward by whole months |
| `add_days(Int)` | `-> Self` | Shift the date by a day count, keeping the time of day |
| `sub_days(Int)` | `-> Self` | Shift the date backward by a day count |
| `signed_duration_since(Self)` | `-> TimeDelta` | The signed duration from `other` to `self` |
| `round(TimeDelta)` | `-> Self?` | Round to the nearest multiple of a granularity since the Unix epoch, ties breaking away from the epoch; see `TimeDelta::round` for which granularities are supported |
| `truncate(TimeDelta)` | `-> Self?` | Truncate toward the Unix epoch to the nearest multiple of a granularity; a datetime before the epoch is truncated *forward* in time (see Quick start above), never further into the past |

`NaiveDateTime` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).
