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

### Added

- `parse_rfc2822_lenient`, an opt-in reader for RFC 2822's obsolete syntax (legacy zone names, optional day of week and seconds, folding whitespace, comments, and two- and three-digit years)

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

[Unreleased]: <https://github.com/connect0459/almanac/compare/v0.1.0...HEAD>
[0.1.0]: <https://github.com/connect0459/almanac/releases/tag/v0.1.0>
