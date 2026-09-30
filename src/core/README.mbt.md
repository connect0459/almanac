# `core` package

Calendar and clock primitives with no time zone awareness. Import `connect0459/chrono/core` for `Weekday`, `WeekdaySet`, `Month`, `IsoWeek`, `NaiveWeek`, `NaiveDate`, `NaiveTime`, `TimeDelta`, and `NaiveDateTime`. The `tz` package layers a time zone on top of `NaiveDateTime`.

## Key types

| Type | Description |
| :--- | :--- |
| `Weekday` | Cyclic day-of-week enum (`Mon`..`Sun`) |
| `WeekdaySet` | An immutable set of `Weekday` values, stored as a bitset |
| `Month` | Cyclic month enum (`Jan`..`Dec`) |
| `IsoWeek` | ISO 8601 week-numbering year and week |
| `NaiveDate` | A proleptic Gregorian calendar date, no time zone |
| `NaiveWeek` | The week containing a date, under a configurable first day of the week |
| `NaiveDateDaysIterator` / `NaiveDateWeeksIterator` | Lazy, bounded, double-ended iterators over successive dates from `NaiveDate::iter_days`/`iter_weeks` |
| `WeekdaySetIterator` | Double-ended iterator over a `WeekdaySet`'s members in cyclic weekday order from a chosen start, from `WeekdaySet::iter_from` |
| `NaiveTime` | A time of day, precise to the nanosecond, with leap-second support |
| `TimeDelta` | A signed duration, precise to the nanosecond |
| `NaiveDateTime` | A `NaiveDate` and `NaiveTime` combined into one zone-less instant |
| `YearCe` / `ClockHour12` | Named results of `year_ce()` and `hour12()`: `is_ce()`/`year()` and `is_pm()`/`hour()`, so the meaning of each part is in its name rather than its position in a tuple |
| `RoundingError` | Why a `round`/`round_up`/`truncate` call failed: `InvalidGranularity` (zero or negative), `MixedGranularity` (a whole-second part combined with a sub-second remainder, e.g. 1.5 seconds), or `OutOfRange` (the result would leave the type's representable range) |

`NaiveDate` (`1970-01-01`), `NaiveTime` (midnight), `NaiveDateTime` (the Unix epoch), `TimeDelta` (zero) and `WeekdaySet` (empty) implement `Default`. Struct-valued constants are exposed as functions (`NaiveTime::midnight()`, `NaiveDateTime::unix_epoch()`, `TimeDelta::zero()`) because MoonBit's `const` is limited to primitive types.

Every value type above (all but the two iterators) implements `Hash` consistently with its `Eq`, so values can be `Map` keys. `NaiveWeek` hashes by `first_day()` alone, matching its `Eq`: two weeks anchored on different dates of the same calendar week are equal and hash equally.

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
  assert_eq(half_hour.round(hour), Ok(hour))
  assert_eq(half_hour.truncate(hour), Ok(@core.TimeDelta::zero()))
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

---

### `Weekday`

`Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `succ()` | `-> Self` | Next day, wrapping `Sun` to `Mon` |
| `add_days(n)` | `(Int) -> Self` | The weekday `n` days later (earlier for negative `n`), wrapping around the week; total for every `Int` |
| `pred()` | `-> Self` | Previous day, wrapping `Mon` to `Sun` |
| `number_from_monday()` | `-> Int` | 1-based, `Mon` is `1` |
| `number_from_sunday()` | `-> Int` | 1-based, `Sun` is `1` |
| `num_days_from_monday()` | `-> Int` | 0-based, `Mon` is `0` |
| `num_days_from_sunday()` | `-> Int` | 0-based, `Sun` is `0` |
| `days_since(Weekday)` | `-> Int` | Days elapsed since `other`, counting forward |
| `name()` | `-> String` | English name, e.g. `"Monday"` |
| `Weekday::from_number_from_monday(Int)` | `-> Weekday?` | Inverse of `number_from_monday()`; `None` outside `1..=7` |
| `Weekday::from_number_from_sunday(Int)` | `-> Weekday?` | Inverse of `number_from_sunday()`; `None` outside `1..=7` |
| `Weekday::from_num_days_from_monday(Int)` | `-> Weekday?` | Inverse of `num_days_from_monday()`; `None` outside `0..=6` |
| `Weekday::from_num_days_from_sunday(Int)` | `-> Weekday?` | Inverse of `num_days_from_sunday()`; `None` outside `0..=6` |
| `Weekday::from_name(String)` | `-> Weekday?` | The weekday for a full English name (`"Monday"`) or three-letter abbreviation (`"Mon"`), ignoring ASCII letter case; `None` for anything else (a prefix, `"Tues"`, surrounding whitespace, non-ASCII text) |

Naming rule: `number_from_*` counts from 1 (ISO 8601 for Monday), and `num_days_from_*` counts whole days elapsed since that start day, from 0; each has a `from_*` inverse that returns `None` outside its range.

`Weekday` also implements `Eq` and `Show` (renders `name()`). It deliberately has no `Compare`: a weekday ordering depends on which day starts the week, so use `num_days_from_monday`/`num_days_from_sunday`/`days_since` to compare with an explicit starting day.

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
| `iter(start? : Weekday)` | `-> Iter[Weekday]` | Members in cyclic order from `start` (default `Mon`, matching `to_array()`), wrapping from `Sun` to `Mon`; a `start` that is not a member begins at the next member. A standard `Iter`, so `for day in set.iter(start=Sun)` and adapters work (`for day in set` does not: `for` needs a zero-argument `iter()`) |
| `iter_from(start? : Weekday)` | `-> WeekdaySetIterator` | The same order as a double-ended iterator with `next()`, `next_back()`, `length()` and `iter()`; the ends converge without skipping or repeating a weekday |

`WeekdaySet` also implements `Eq`, `Hash` and `Show`; it deliberately has no `Compare`, since an order over sets would only reflect the bit layout (use `is_subset` for the meaningful relation), rendering the members' short names in `Mon..Sun` order (`[Mon, Fri]`, empty is `[]`).

---

### `Month`

`Jan`, `Feb`, `Mar`, `Apr`, `May`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `succ()` | `-> Self` | Next month, wrapping `Dec` to `Jan` |
| `add_months(n)` | `(Int) -> Self` | The month `n` months later (earlier for negative `n`), wrapping around the year; total for every `Int` |
| `pred()` | `-> Self` | Previous month, wrapping `Jan` to `Dec` |
| `number()` | `-> Int` | 1-based, `Jan` is `1` |
| `name()` | `-> String` | Full English name, e.g. `"February"` |
| `num_days(Int)` | `-> Int` | Number of days in this month for the given year |
| `Month::from_number(Int)` | `-> Month?` | Inverse of `number()`; `None` outside `1..=12` |
| `Month::from_name(String)` | `-> Month?` | The month for a full English name (`"January"`) or three-letter abbreviation (`"Jan"`), ignoring ASCII letter case; `None` for anything else (a prefix, `"Sept"`, surrounding whitespace, non-ASCII text) |

`Month` also implements `Eq`, `Compare` (`Jan` < ... < `Dec`) and `Show` (renders `name()`).

---

### `IsoWeek`

| Method | Signature | Description |
| :--- | :--- | :--- |
| `year()` | `-> Int` | ISO 8601 week-numbering year (can differ from the calendar year near a year boundary) |
| `week()` | `-> Int` | 1-based week number within that year |
| `week0()` | `-> Int` | 0-based week number |

`IsoWeek` also implements `Eq`, `Compare` (`<`/`<=`/`>`/`>=` via `compare`) and `Show`, rendering `YYYY-Www` (`2015-W38`); a year outside `0..=9999` gets an explicit sign (`+10000-W01`).

---

### `NaiveDate`

A proleptic Gregorian calendar date. Constructors are `Option`-returning: an invalid combination reports `None` rather than clamping.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveDate::from_ymd(Int, Int, Int)` | `-> Self?` | From year, month, day |
| `NaiveDate::from_yo(Int, Int)` | `-> Self?` | From year and ordinal day (`1..=365`/`366`) |
| `NaiveDate::from_isoywd(Int, Int, Weekday)` | `-> Self?` | From ISO week-numbering year, week, and weekday |
| `NaiveDate::from_weekday_of_month(Int, Int, Weekday, Int)` | `-> Self?` | The `n`-th (1-indexed) occurrence of a weekday in a month, e.g. the 2nd Friday of March 2017; `None` if `n` isn't positive or that occurrence doesn't exist |
| `year()` | `-> Int` | Calendar year |
| `month()` | `-> Month` | Calendar month |
| `day()` | `-> Int` | Day of month |
| `ymd()` | `-> (Int, Month, Int)` | Year, month and day of month together |
| `ordinal()` | `-> Int` | Day of year, 1-based |
| `month0()` / `day0()` / `ordinal0()` | `-> Int` | The zero-based forms of the month (`0..=11`), day of month (`0..=30`) and day of year (`0..=365`) |
| `year_ce()` | `-> YearCe` | The year as a Common Era flag (`is_ce()`) and a positive year number (`year()`): `2024` CE, and `1` BCE for year `0`, `2` BCE for year `-1` |
| `num_days_in_month()` | `-> Int` | Length of this date's month, honoring leap years |
| `abs_diff(Self)` | `-> Int64` | Non-negative number of days between two dates, in either order |
| `weekday()` | `-> Weekday` | Day of week |
| `iso_week()` | `-> IsoWeek` | ISO 8601 week-numbering year and week |
| `leap_year()` | `-> Bool` | Whether this date's year is a leap year |
| `with_year(Int)` | `-> Self?` | Same month/day in a different year; `None` if that combination is invalid (e.g. Feb 29 into a non-leap year) |
| `with_month(Int)` | `-> Self?` | Same year/day in a different month; `None` if the day doesn't exist in that month |
| `with_day(Int)` | `-> Self?` | Same year/month with a different day |
| `with_ordinal(Int)` | `-> Self?` | Same year with a different ordinal day |
| `with_month0(Int)` / `with_day0(Int)` / `with_ordinal0(Int)` | `-> Self?` | As `with_month`/`with_day`/`with_ordinal`, taking a zero-based value |
| `succ()` | `-> Self` | The next day |
| `pred()` | `-> Self` | The previous day |
| `add_days(Int)` | `-> Self` | Shift forward (or back, if negative) by a day count |
| `sub_days(Int)` | `-> Self` | Shift backward by a day count |
| `add_signed(TimeDelta)` | `-> Self` | Shift forward by the duration's whole days (sub-day remainder truncated toward zero); aborts if out of range |
| `sub_signed(TimeDelta)` | `-> Self` | Shift backward by the duration's whole days; aborts if out of range |
| `checked_add_signed(TimeDelta)` / `checked_sub_signed(TimeDelta)` | `-> Self?` | As `add_signed`/`sub_signed`, but `None` if out of range |
| `signed_duration_since(Self)` | `-> TimeDelta` | Whole-day duration from `other` to this date |
| `and_time(NaiveTime)` | `-> NaiveDateTime` | Combine with a time of day |
| `and_hms(Int, Int, Int)` | `-> NaiveDateTime?` | Combine with `hour:min:sec`; `None` if a component is out of range |
| `and_hms_milli(Int, Int, Int, Int)` | `-> NaiveDateTime?` | As `and_hms`, plus milliseconds |
| `and_hms_micro(Int, Int, Int, Int)` | `-> NaiveDateTime?` | As `and_hms`, plus microseconds |
| `and_hms_nano(Int, Int, Int, Int)` | `-> NaiveDateTime?` | As `and_hms`, plus nanoseconds (`>= 1_000_000_000` encodes a leap second) |
| `epoch_days()` | `-> Int` | Days since the Unix epoch (`1970-01-01` is `0`) |
| `NaiveDate::from_epoch_days(Int)` | `-> NaiveDate?` | Inverse of `epoch_days()`; `None` if out of range |
| `num_days_from_ce()` | `-> Int` | Days since the Common Era (`0001-01-01` is `1`); also available on `NaiveDateTime` and `DateTime`, whereas `epoch_days()`/`from_epoch_days` exist only here, because a count of days since the epoch would be ambiguous between a date and an instant |
| `NaiveDate::from_num_days_from_ce(Int)` | `-> NaiveDate?` | Inverse of `num_days_from_ce()`; `None` if out of range |
| `add_months(Int)` | `-> Self` | Shift by whole months, clamping the day of month to the target month's length |
| `sub_months(Int)` | `-> Self` | Shift backward by whole months, with the same clamping |
| `checked_succ()` | `-> Self?` | The next day; `None` at the last representable date |
| `checked_pred()` | `-> Self?` | The previous day; `None` at the first representable date |
| `checked_add_days(Int)` / `checked_sub_days(Int)` | `-> Self?` | As `add_days`/`sub_days`, but `None` if out of range |
| `checked_add_months(Int)` / `checked_sub_months(Int)` | `-> Self?` | As `add_months`/`sub_months`, but `None` if out of range |
| `add_years(Int)` / `sub_years(Int)` | `-> Self` | Shift by whole years, clamping February 29 to February 28 in a non-leap year (same as `add_months(12 * years)`) |
| `checked_add_years(Int)` / `checked_sub_years(Int)` | `-> Self?` | As `add_years`/`sub_years`, but `None` if out of range |
| `week(Weekday)` | `-> NaiveWeek` | The calendar week containing this date, with weeks starting on the given weekday |
| `years_since(Self)` | `-> Int?` | Full elapsed calendar years from `other` to `self` (a year counts once the month and day have both recurred); `None` if `self` is before `other` |
| `quarter()` | `-> Int` | Calendar quarter, `1..=4` |
| `iter_days()` | `-> NaiveDateDaysIterator` | Lazy, bounded, double-ended iterator over successive dates one day apart, starting from `self` |
| `iter_weeks()` | `-> NaiveDateWeeksIterator` | Lazy, bounded, double-ended iterator over successive dates one week apart, starting from `self` |

`NaiveDate` also implements `Eq`, `Compare` (`<`/`<=`/`>`/`>=` via `compare`) and `Show`, rendering `YYYY-MM-DD` (`2024-01-02`); a year outside `0..=9999` gets an explicit sign (`-0001-12-31`, `+10000-01-01`).

---

### `NaiveDateDaysIterator` / `NaiveDateWeeksIterator`

Returned by `NaiveDate::iter_days`/`iter_weeks`. Both are lazy and double-ended: `next()` advances from the front, `next_back()` from the back, and they converge without skipping or repeating a date. Both are bounded above by a conservative, round practical limit, `+275760-09-13` (matching the well-known ECMAScript `Date` representable range) — not `NaiveDate`'s actual much larger overflow-safe range — reaching and including that bound if the iterator gets that far; a date already past it yields nothing. Each also has `iter()`, returning a standard `Iter[NaiveDate]` that shares the iterator's state, so `for date in start.iter_days() { ... }` works directly and adapters are available through it (`start.iter_days().iter().take(7).map(...).collect()`); the iterator types themselves cannot be `Iter` values, since MoonBit's `Iter` is a concrete closure-based type rather than a trait.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `next()` | `-> NaiveDate?` | The next date from the front, or `None` once exhausted |
| `next_back()` | `-> NaiveDate?` | The next date from the back, or `None` once exhausted |
| `length()` | `-> Int` | The number of dates (`NaiveDateDaysIterator`) or weekly steps (`NaiveDateWeeksIterator`) remaining |

---

### `NaiveWeek`

The week containing a `NaiveDate`, under a configurable first day of the week (via `NaiveDate::week`). Distinct from `IsoWeek`, which is always Monday-based and tied to the ISO 8601 week-numbering year. Two `NaiveWeek`s are equal (and compare) by the calendar week they denote — `first_day()` alone — regardless of which date within it was used to construct them.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `first_day()` | `-> NaiveDate` | The first day of the week |
| `last_day()` | `-> NaiveDate` | The last day of the week, six days after `first_day()` |
| `days()` | `-> Array[NaiveDate]` | All seven days of the week, from `first_day()` to `last_day()` |

`NaiveWeek` also implements `Eq` and `Compare` (`<`/`<=`/`>`/`>=` via `compare`).

---

### `NaiveTime`

A time of day, precise to the nanosecond. Constructors are `Option`-returning. Supports leap seconds: a nanosecond component `>= 1_000_000_000` at `second() == 59` represents one — `second()` never itself reports `60`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveTime::from_hms(Int, Int, Int)` | `-> Self?` | From hour, minute, second |
| `NaiveTime::midnight()` | `-> Self` | The start of the day, `00:00:00`, the earliest time of day; also `NaiveTime`'s `Default` |
| `NaiveTime::from_hms_milli(Int, Int, Int, Int)` | `-> Self?` | With a millisecond component |
| `NaiveTime::from_hms_micro(Int, Int, Int, Int)` | `-> Self?` | With a microsecond component |
| `NaiveTime::from_hms_nano(Int, Int, Int, Int)` | `-> Self?` | With a nanosecond component (`0..=1_999_999_999`, the upper half representing a leap second) |
| `NaiveTime::from_num_seconds_from_midnight(Int, Int)` | `-> Self?` | From a seconds-since-midnight count plus a nanosecond component |
| `hour()` | `-> Int` | Hour, `0..=23` |
| `minute()` | `-> Int` | Minute, `0..=59` |
| `second()` | `-> Int` | Second, `0..=59` (never `60`; see leap seconds above) |
| `hms()` | `-> (Int, Int, Int)` | Hour, minute and second together (a leap second reports second `59`, as `second()` does) |
| `nanosecond()` | `-> Int` | Nanosecond component, `0..=1_999_999_999` |
| `hour12()` | `-> ClockHour12` | 12-hour clock hour (`hour()`) and PM flag (`is_pm()`), wrapping midnight/noon to `12` |
| `round_subsecs(Int)` / `truncate_subsecs(Int)` | `-> Self` | Round (ties up) or truncate to a number of fractional-second digits (`0..=9`; other values abort). A carry wraps past the end of the day to midnight and the day carry is discarded (`NaiveDateTime::round_subsecs` moves the date forward instead). A time with no digits beyond that count is returned unchanged, leap second included (`9` is the identity); otherwise a leap second is folded into the following second |
| `num_seconds_from_midnight()` | `-> Int` | Seconds elapsed since midnight |
| `overflowing_add_signed(TimeDelta)` | `-> (Self, Int64)` | Add a duration, wrapping at midnight; also reports the number of days crossed |
| `overflowing_sub_signed(TimeDelta)` | `-> (Self, Int64)` | Subtract a duration, with the same wrapping and day-count report |
| `wrapping_add_signed(TimeDelta)` / `wrapping_sub_signed(TimeDelta)` | `-> Self` | As `overflowing_add_signed`/`overflowing_sub_signed`, discarding the day count |
| `with_hour(Int)` | `-> Self?` | Same minute/second/nanosecond in a different hour; `None` if outside `0..=23` |
| `with_minute(Int)` | `-> Self?` | Same hour/second/nanosecond in a different minute; `None` if outside `0..=59` |
| `with_second(Int)` | `-> Self?` | Same hour/minute/nanosecond in a different second; `None` if outside `0..=59` |
| `with_nanosecond(Int)` | `-> Self?` | Same hour/minute/second with a different nanosecond component; `None` if outside `0..=1_999_999_999` |
| `signed_duration_since(Self)` | `-> TimeDelta` | The signed duration from `other` to `self`, with no day carry; a leap second is treated as coinciding with the prior non-leap second until time moves away from it |

`NaiveTime` also implements `Eq`, `Compare` (`<`/`<=`/`>`/`>=` via `compare`) and `Show`, rendering `HH:MM:SS` plus, only when the nanoseconds are nonzero, the fewest of 3, 6 or 9 fractional digits that represent them exactly (`.500`, `.123456`, `.000000789`); a leap second is rendered with second `60`.

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
| `TimeDelta::new(Int64, Int)` | `-> Self?` | Whole seconds plus a nanosecond remainder in `0..=999_999_999` (the sign lives in the seconds: `new(-1, 500_000_000)` is minus half a second); `None` if the remainder is out of range or the result is out of range |
| `TimeDelta::from_seconds_double(Double)` | `-> Self?` | From fractional seconds, rounded to the nearest nanosecond (an exact half-nanosecond tie goes away from zero, so `0.3` is exactly 300 000 000 ns); `None` for NaN, an infinity or an out-of-range value. Nanosecond precision holds only while the whole-second part is below about 9 million seconds, a `Double` limit |
| `TimeDelta::zero()` | `-> Self` | The zero-length duration |
| `TimeDelta::min_value()` | `-> Self` | The most negative representable duration, exactly `-9_223_372_036_854_774` seconds |
| `TimeDelta::max_value()` | `-> Self` | The most positive representable duration, exactly `9_223_372_036_854_774` seconds; the range is symmetric, so `neg()` and `abs()` never leave it |
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
| `as_seconds_double()` | `-> Double` | Total length in fractional seconds, as a 64-bit float; loses precision for a very large duration, never fails |
| `as_minutes_double()` / `as_hours_double()` | `-> Double` | Total length in fractional minutes / hours, as a 64-bit float; same precision caveat |
| `add(TimeDelta)` | `-> Self` | Sum; aborts on overflow |
| `sub(TimeDelta)` | `-> Self` | Difference; aborts on overflow |
| `mul(Int)` | `-> Self` | Scale by an integer scalar; aborts on overflow |
| `div(Int)` | `-> Self` | Divide by an integer scalar, truncated toward zero; aborts if the scalar is zero |
| `TimeDelta::sum(Array[TimeDelta])` | `-> Self` | Total of an array, `zero()` when empty; aborts only if the true total is out of range (see `checked_sum`) |
| `checked_add(TimeDelta)` / `checked_sub(TimeDelta)` | `-> Self?` | As `add`/`sub`, but `None` on overflow |
| `checked_mul(Int)` | `-> Self?` | As `mul`, but `None` on overflow |
| `checked_div(Int)` | `-> Self?` | As `div`, but `None` if the scalar is zero |
| `TimeDelta::checked_sum(Array[TimeDelta])` | `-> Self?` | As `sum`, but `None` if the true total is out of range; unlike folding with `checked_add`, independent of order, so a partial sum that would leave the range does not spoil a representable total |
| `neg()` | `-> Self` | Negation |
| `+` / `-` / unary `-` | `Add`/`Sub`/`Neg` | Operator forms of `add`, `sub` and `neg`; `+` and `-` abort on overflow like `add`/`sub` |
| `abs()` | `-> Self` | Absolute value |
| `is_zero()` | `-> Bool` | Whether this duration is exactly zero |
| `round(TimeDelta)` | `-> Result[Self, RoundingError]` | Round to the nearest multiple of a granularity, ties breaking away from zero; `Err(InvalidGranularity)` if the granularity is zero or negative, `Err(MixedGranularity)` if it mixes a whole-second part with a sub-second remainder (e.g. 1.5 seconds — every named duration unit is either purely sub-second or a whole-second-or-larger multiple), `Err(OutOfRange)` if the result would leave the representable range |
| `truncate(TimeDelta)` | `-> Result[Self, RoundingError]` | Truncate toward zero to the nearest multiple of a granularity; same granularity restriction as `round` |
| `round_up(TimeDelta)` | `-> Result[Self, RoundingError]` | Round up (toward positive infinity) to a multiple of a granularity: unchanged if already a multiple, otherwise the next one above (for a negative duration that is toward zero, equal to `truncate`); `Err` with the same reasons as `round` |

`TimeDelta` also implements `Eq`, `Compare` (`<`/`<=`/`>`/`>=` via `compare`) and `Show`. `Show` renders compactly: a leading `-` for a negative value, then hours/minutes/seconds (`1h2m3.5s`) with hours as the largest unit (never days) and trailing fractional zeros trimmed; units between the largest and the seconds are kept even when zero (`1h0m0s`); a duration under one second uses `ns`/`us`/`ms` (`1.5ms`); zero is `0s`. `format`'s `parse_duration` reads this form back.

---

### `NaiveDateTime`

A `NaiveDate` and `NaiveTime` combined into one zone-less instant.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `NaiveDateTime::new(NaiveDate, NaiveTime)` | `-> Self` | Compose a date and a time of day |
| `NaiveDateTime::from_ymd_hms(Int, Int, Int, Int, Int, Int)` | `-> Self?` | From year, month, day, hour, minute and second; `None` if any component is out of range |
| `NaiveDateTime::unix_epoch()` | `-> Self` | The Unix epoch, `1970-01-01 00:00:00` (timestamp zero); also `NaiveDateTime`'s `Default` |
| `year()` / `month()` / `day()` / `ordinal()` / `weekday()` / `iso_week()` / `leap_year()` | `-> Int` / `Month` / `Int` / `Int` / `Weekday` / `IsoWeek` / `Bool` | The date's components, as on `NaiveDate` |
| `hour()` / `minute()` / `second()` / `nanosecond()` | `-> Int` | The time's components, as on `NaiveTime` (`nanosecond() >= 1_000_000_000` encodes a leap second) |
| `ymd()` / `hms()` | `-> (Int, Month, Int)` / `(Int, Int, Int)` | The date and time components together, as on `NaiveDate`/`NaiveTime` |
| `years_since(Self)` | `-> Int?` | Full calendar years elapsed from `base`, comparing the dates and ignoring the time of day; `None` if `self` is before `base` |
| `month0()` / `day0()` / `ordinal0()` / `quarter()` / `num_days_in_month()` / `num_days_from_ce()` | `-> Int` | The zero-based month/day/ordinal, the quarter (`1..=4`), the month's length and the Common Era day count, as on `NaiveDate` |
| `year_ce()` | `-> YearCe` | The year as a Common Era flag and positive year number, as on `NaiveDate` |
| `hour12()` | `-> ClockHour12` | The 12-hour clock as a PM flag and an hour in `1..=12`, as on `NaiveTime` |
| `num_seconds_from_midnight()` | `-> Int` | Seconds since midnight, as on `NaiveTime` |
| `with_date(NaiveDate)` / `with_time(NaiveTime)` | `-> Self` | Replace the date or the time of day, keeping the other; total |
| `with_year(Int)` / `with_month(Int)` / `with_day(Int)` / `with_ordinal(Int)` | `-> Self?` | Replace one date component, keeping the time of day; `None` if the result is not a valid date |
| `with_month0(Int)` / `with_day0(Int)` / `with_ordinal0(Int)` | `-> Self?` | As `with_month`/`with_day`/`with_ordinal`, taking a zero-based value, keeping the time of day |
| `with_hour(Int)` / `with_minute(Int)` / `with_second(Int)` / `with_nanosecond(Int)` | `-> Self?` | Replace one time component, keeping the date and every other time field (including a leap second); `None` if out of range |
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
| `add_years(Int)` / `sub_years(Int)` | `-> Self` | Shift the date by whole years, keeping the time of day; February 29 clamps to February 28 in a non-leap year |
| `sub_months(Int)` | `-> Self` | Shift the date backward by whole months |
| `add_days(Int)` | `-> Self` | Shift the date by a day count, keeping the time of day |
| `sub_days(Int)` | `-> Self` | Shift the date backward by a day count |
| `add_seconds(Int64)` / `sub_seconds(Int64)` | `-> Self` | Shift by a whole number of seconds (e.g. to apply a UTC offset), like `add_signed` with the same seconds: a nonzero shift follows its leap-second rule, a zero shift changes nothing |
| `checked_add_seconds(Int64)` / `checked_sub_seconds(Int64)` | `-> Self?` | As `add_seconds`/`sub_seconds`, but `None` if the date is out of range |
| `checked_add_signed(TimeDelta)` / `checked_sub_signed(TimeDelta)` | `-> Self?` | As `add_signed`/`sub_signed`, but `None` if the date is out of range |
| `checked_add_days(Int)` / `checked_sub_days(Int)` | `-> Self?` | As `add_days`/`sub_days`, but `None` if out of range |
| `checked_add_months(Int)` / `checked_sub_months(Int)` | `-> Self?` | As `add_months`/`sub_months`, but `None` if out of range |
| `checked_add_years(Int)` / `checked_sub_years(Int)` | `-> Self?` | As `add_years`/`sub_years`, but `None` if out of range |

An abort cannot be recovered from in MoonBit, so it is a contract violation by the caller: every function that can abort names the `checked_*` (or other non-aborting) form in its documentation, and a caller that cannot guarantee the precondition uses that form. Ordering follows one rule: a type implements `Compare` only where there is a single natural total order that every user agrees on (chronological for times and dates, magnitude for `TimeDelta`, calendar-year order for `Month`). A `Weekday` order depends on the locale's first day, a `WeekdaySet` order would only reflect its bit layout, and `FixedOffset`, `Utc` and the zone types have no such order, so none of them implement it; compare `FixedOffset` values through `local_minus_utc()` when that is wanted. Trait coverage follows one rule across the packages: every public value type implements `Eq` and `Debug` (a structural dump for diagnostics and `assert_eq` failures), while `Show` is reserved for types with a canonical text form and a parser that reads it back (`parse_*_default`, `parse_duration`, `parse_fixed_offset`); types without one, such as `NaiveWeek`, `LocalTimeType`, `PosixTz`, `TransitionBounds` and `MappedLocalTime`, have `Debug` only. The iterators are the one stateful kind of value: `next()` and `next_back()` advance the iterator in place, `iter()` does not advance it but returns an `Iter` sharing its state, and `NaiveDate::iter_days`/`iter_weeks` and `WeekdaySet::iter_from` return a fresh iterator on every call, leaving the date or set unchanged. Floating-point conversions of `TimeDelta` are `Double` only: `as_seconds_double`/`as_minutes_double`/`as_hours_double` read a duration out, and `from_seconds_double` builds one from fractional seconds; there is no `Float` form, since 32 bits cannot hold whole seconds beyond a few months exactly. Month types follow one rule: accessors return the typed `Month` (`month()`, `ymd()`), with `month().number()` as the one-based number and `month0()` as the zero-based one, while numeric inputs (`from_ymd`, `with_month`, `NaiveDate::from_yo`) are plain `Int`s that are validated and rejected with `None` when out of range. So `ymd()` does not feed `from_ymd` directly; convert the month with `number()`. `succ` and `pred` share their names across types but not their edge behavior, as in chrono: on `Month` and `Weekday`, which are cyclic, they wrap around (`Dec` to `Jan`, `Sun` to `Mon`), while on `NaiveDate` they abort at the ends of the representable range, with `checked_succ`/`checked_pred` returning `None` there. Integer widths follow one rule: a count of fixed-length time (seconds, milliseconds, microseconds, nanoseconds, timestamps, and the `TimeDelta` unit constructors) or a difference that can exceed `Int` (`NaiveDate::abs_diff`) is `Int64`; a calendar step (`add_days`, `add_months`, `add_years`), a calendar or clock field, a sub-second component within one second, and a scalar multiplier or divisor are `Int`.

The non-`checked` arithmetic on `NaiveDate` and `NaiveDateTime` (`succ`, `pred`, `add_*`, `sub_*`) aborts if the result falls outside the representable date range (about ±5.87 million years around the epoch) rather than wrapping into an invalid date; use the `checked_*` forms to get `None` instead.
| `signed_duration_since(Self)` | `-> TimeDelta` | The signed duration from `other` to `self` |
| `round(TimeDelta)` | `-> Result[Self, RoundingError]` | Round to the nearest multiple of a granularity since the Unix epoch, ties breaking away from the epoch; see `TimeDelta::round` for which granularities are supported |
| `truncate(TimeDelta)` | `-> Result[Self, RoundingError]` | Truncate toward the Unix epoch to the nearest multiple of a granularity; a datetime before the epoch is truncated *forward* in time (see Quick start above), never further into the past |
| `round_subsecs(Int)` / `truncate_subsecs(Int)` | `-> Result[Self, RoundingError]` / `-> Self` | Round or truncate to a number of fractional-second digits (`0..=9`; other values abort), with the tie-breaking and epoch direction of `round`/`truncate`; `round_subsecs` fails with `OutOfRange` if rounding up leaves the range. A datetime with no digits beyond that count is returned unchanged, leap second included; otherwise a leap second folds into the following second |
| `round_up(TimeDelta)` | `-> Result[Self, RoundingError]` | Round up (toward positive infinity) to the next multiple of a granularity since the Unix epoch, unchanged if already a multiple; a datetime before the epoch moves toward the epoch; `Err` for a rejected granularity, or `Err(OutOfRange)` if the result would leave `NaiveDate`'s range |

`NaiveDateTime` also implements `Eq`, `Compare` (`<`/`<=`/`>`/`>=` via `compare`) and `Show`, rendering the date and time joined by a space (`2024-01-02 13:45:06.500`).
