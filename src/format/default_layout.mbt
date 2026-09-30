///|
/// Parses a date in the layout `NaiveDate`'s `Show` renders, `YYYY-MM-DD`,
/// with `-` for a negative year and `+` beyond 9999 (`-0001-12-31`,
/// `+10000-01-01`). The inverse of `Show`: every rendered date reads back.
pub fn parse_date_default(input : String) -> @core.NaiveDate raise FormatError {
  parse_date(input, "%F")
}

///|
/// Parses a time in the layout `NaiveTime`'s `Show` renders, `HH:MM:SS` with
/// an optional fractional part, a leap second as second `60`. The fraction
/// accepts any number of digits, not only the 3, 6 or 9 `Show` renders. The
/// inverse of `Show`.
pub fn parse_time_default(input : String) -> @core.NaiveTime raise FormatError {
  parse_time(input, "%T%.f")
}

///|
/// Parses a date-time in the layout `NaiveDateTime`'s `Show` renders, a date
/// and a time joined by one space. The inverse of `Show`.
pub fn parse_date_time_default(
  input : String,
) -> @core.NaiveDateTime raise FormatError {
  parse_date_time(input, "%F %T%.f")
}

///|
/// Parses a UTC date-time in the layout `DateTime[Utc]`'s `Show` renders:
/// `parse_date_time_default`'s layout followed by a space and `UTC`. The
/// inverse of `Show` for `DateTime[Utc]`.
pub fn parse_date_time_utc_default(
  input : String,
) -> @tz.DateTime[@tz.Utc] raise FormatError {
  let naive = parse_date_time(input, "%F %T%.f UTC")
  @tz.DateTime::from_utc(naive, @tz.Utc::new())
}

///|
/// Parses a date-time in the layout `DateTime[FixedOffset]`'s `Show`
/// renders: `parse_date_time_default`'s layout followed by a space and the
/// offset as `parse_fixed_offset` reads it (`+09:00`, or `+09:00:30` for a
/// sub-minute offset). The written clock is the local wall-clock time in
/// that offset. The inverse of `Show` for `DateTime[FixedOffset]`.
pub fn parse_date_time_fixed_offset_default(
  input : String,
) -> @tz.DateTime[@tz.FixedOffset] raise FormatError {
  let (wall_clock, rest) = parse_date_time_and_remainder(input, "%F %T%.f ")
  let offset = parse_fixed_offset(rest)
  @tz.DateTime::from_utc(
    wall_clock.sub_seconds(offset.local_minus_utc().to_int64()),
    offset,
  )
}
