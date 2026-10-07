# Changelog

<!--
When cutting a new release, update THREE places in this file:

1. Rename [Unreleased] to [X.Y.Z] with today's date (above), and add a fresh empty [Unreleased] section above it.
2. Update the reference links at the very bottom of this file:
    - Change [Unreleased] to compare the new tag against HEAD.
    - Add [X.Y.Z] comparing the new tag against the previous tag.
3. After the PR is merged, push the release tag. Pull main first so HEAD is the merge commit:

    ```console
    git checkout main && git pull origin main
    git tag vX.Y.Z && git push origin vX.Y.Z
    ```

   Pushing the tag triggers `.github/workflows/publish.yml`, which publishes
   to mooncakes.io, extracts this file's `[X.Y.Z]` section, and creates the
   GitHub Release from it automatically. Do not run `gh release create`
   manually; it would create the tag/Release ahead of the workflow with
   hand-pasted notes instead of the CHANGELOG-derived ones.
-->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-10-07

### Added

#### Calendar and clock values (`connect0459/almanac/core`)

- The open `Datelike` and `Timelike` traits, implemented by `NaiveDate`, `NaiveTime`, `NaiveDateTime` and `DateTime[Tz]`; any method added later has a default implementation, so existing implementations keep compiling
- `WeekdaySet::from_iter`, `TimeDelta::of` and `TimeDelta::seconds_of_day`
- `NaiveWeek::checked_first_day`, `checked_last_day` and `checked_days`, which stay total at the edge of the date range

#### Time zones (`connect0459/almanac/tz`)

- `Local` on the `js`, `wasm` and `wasm-gc` backends, in addition to native; on native it honours colon-prefixed and absolute-path `TZ` values
- `Location::load_system`, `Location::zone_names` and `Location::tzdata_version`; native targets also read `ZONEINFO` and the system zoneinfo directory
- `Location::load` memoizes each zone name
- An unnamed `FixedZone` renders its offset text as the abbreviation, and `%Z` reads that text back

#### Formatting and parsing (`connect0459/almanac/format`)

- `Locale`, with a `locale?` argument on every `format_*`, `parse_*` and `tokenize` function, so names, day periods and `%x`, `%X`, `%c` and `%r` follow the locale
- `parse_iso8601`, a lenient ISO 8601 reader returning `Iso8601`
- `parse_rfc2822_lenient` for RFC 2822 obsolete syntax, and `Item::Rfc2822` for item sequences
- `Parsed::new`, the `Parsed::set_*` methods and `Parsed::with_default_year` for layouts without a year
- ASN.1 `UTCTime` and `GeneralizedTime` through `parse_utc_time`, `parse_generalized_time`, `to_utc_time` and `to_generalized_time`
- ISO 8601 durations through `parse_iso8601_duration` and `to_iso8601_duration`

#### Scheduling (`connect0459/almanac/cron`)

- The `@annually` and `@midnight` shorthands; shorthands match in any case

### Changed

- **Breaking:** `Item` gains the `Rfc2822` variant and `FormatError` gains `InvalidIso8601` and `InvalidAsn1Time`; an exhaustive `match` on either type must handle the new cases
- **Breaking:** `parse_rfc2822` now checks the day of the week against the date and rejects long month names; use `parse_rfc2822_lenient` to accept them
- **Breaking:** the `Debug` output of `NaiveWeek` shows its first day alone
- **Breaking:** the `format_*`, `parse_*` and `tokenize` functions take an optional `locale?` argument; calls that omit it behave as before, but code that passes one of these functions around as a value sees a different type

### Fixed

- `NaiveDate::week`, `NaiveWeek::first_day`, `last_day` and `days` no longer abort for a week that touches either end of the date range; `first_day`, `last_day` and `days` still abort where the result would leave the range, and the new `checked_*` methods return `None` instead
- An unsigned `%Y` or `%G` reads at most 4 digits when parsing
- `%y`, `%g` and `%C` of a negative year are rendered with floor division
- POSIX TZ rules and offsets are validated
- The zone in effect before the first transition is chosen as Go and tzcode choose it

## [0.1.0] - 2026-10-05

### Added

#### Calendar and clock values (`connect0459/almanac/core`)

- `Weekday`, `Month`, `IsoWeek`, `NaiveWeek`, `WeekdaySet`, `NaiveDate`, `NaiveTime` and `NaiveDateTime`, with checked constructors returning `Option`, calendar arithmetic (`add_days`, `add_months`, `add_years` and their `sub_*`/`checked_*` forms), ISO week dates, ordinals and quarters
- `TimeDelta`, a fixed-length duration with checked arithmetic, unit constructors and `Double` conversions
- Rounding and truncation of `TimeDelta`, `NaiveTime`, `NaiveDateTime` and `DateTime`, reporting a rejected argument as `Result[T, RoundingError]`
- Iterators over days, weeks and the members of a `WeekdaySet`

#### Time zones (`connect0459/almanac/tz`)

- The `TimeZone` trait and the zones `Utc`, `FixedOffset`, `FixedZone`, `PosixTz`, `Location` and, on native targets, `Local`
- `DateTime[Tz]`, identified by its UTC instant, with local calendar steps, `with_*` replacements that report DST gaps and folds as `MappedLocalTime`, and `from_local_lenient`
- An embedded IANA tz database loaded through `Location::load`, plus parsers for TZif data and POSIX TZ strings

#### Formatting and parsing (`connect0459/almanac/format`)

- A strftime-style specifier engine with `format_*` and `parse_*` functions for dates, times, date-times and zoned date-times, a public `Item` model (`tokenize`, `parse_items`, `format_*_items`) and named layout constants
- RFC 3339, RFC 2822 and HTTP date (IMF-fixdate, with RFC 850 and `asctime` accepted on input) functions
- `parse_duration`, `parse_fixed_offset` and the `parse_*_default` inverses of `Show`

#### Scheduling (`connect0459/almanac/cron`)

- `Cron::parse` for the five-field and six-field forms, names, `?`, steps and the `@yearly`, `@monthly`, `@weekly`, `@daily` and `@hourly` shorthands, with `Cron::matches` and `Cron::next` evaluated in the wall clock of a `DateTime`'s zone

#### Root package (`connect0459/almanac`)

- A thin facade that re-exports the everyday types; `format` and `cron` are imported separately

---

[Unreleased]: <https://github.com/connect0459/almanac/compare/v0.2.0...HEAD>
[0.2.0]: <https://github.com/connect0459/almanac/compare/v0.1.0...v0.2.0>
[0.1.0]: <https://github.com/connect0459/almanac/releases/tag/v0.1.0>
