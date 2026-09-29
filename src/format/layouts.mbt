///|
/// Named convenience format strings, mirroring Go's `time` package
/// layout constants (translated into this project's `%`-specifier style
/// rather than copied as Go's reference-time-layout syntax, per this
/// project's own format/parse design). Pass one to `format_date`/
/// `format_time`/`format_date_time`/`format_date_time_tz` (or their
/// `parse_*` counterparts) like any other format string.
pub let rfc1123 : String = "%a, %d %b %Y %H:%M:%S %Z"

///|
/// `"3:04PM"` in Go: an unpadded 12-hour clock immediately followed by
/// the (uppercase) am/pm marker, no space.
pub let kitchen : String = "%-I:%M%p"

///|
/// `"Jan _2 15:04:05"` in Go: a short month, space-padded day, and
/// 24-hour `HH:MM:SS` — no year, matching Go's own `Stamp` (meant for
/// display alongside separately-known context, not a self-sufficient
/// parseable timestamp).
pub let stamp : String = "%b %e %H:%M:%S"

///|
/// `stamp` with milliseconds.
pub let stamp_milli : String = "%b %e %H:%M:%S.%3f"

///|
/// `stamp` with microseconds.
pub let stamp_micro : String = "%b %e %H:%M:%S.%6f"

///|
/// `stamp` with nanoseconds.
pub let stamp_nano : String = "%b %e %H:%M:%S.%9f"

///|
/// `"2006-01-02"` in Go: equivalent to `%F`.
pub let date_only : String = "%F"

///|
/// `"15:04:05"` in Go: equivalent to `%T`.
pub let time_only : String = "%T"
