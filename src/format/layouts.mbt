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

///|
/// `"2006-01-02 15:04:05"` in Go: a date and a time joined by one space,
/// equivalent to `%F %T`.
pub let date_time : String = "%F %T"

///|
/// `"Mon Jan _2 15:04:05 2006"` in Go: equivalent to `%c`.
pub let ansic : String = "%a %b %e %H:%M:%S %Y"

///|
/// `"Mon Jan _2 15:04:05 MST 2006"` in Go: `ansic` with the zone name before
/// the year.
pub let unix_date : String = "%a %b %e %H:%M:%S %Z %Y"

///|
/// `"Mon Jan 02 15:04:05 -0700 2006"` in Go: a zero-padded day and a
/// numeric offset before the year.
pub let ruby_date : String = "%a %b %d %H:%M:%S %z %Y"

///|
/// `"02 Jan 06 15:04 MST"` in Go: a two-digit year (`69` and below read as
/// 20xx, `70` and above as 19xx), no seconds, and a zone name. Parsing reads
/// the missing seconds as zero.
pub let rfc822 : String = "%d %b %y %H:%M %Z"

///|
/// `"02 Jan 06 15:04 -0700"` in Go: `rfc822` with a numeric offset.
pub let rfc822z : String = "%d %b %y %H:%M %z"

///|
/// `"Monday, 02-Jan-06 15:04:05 MST"` in Go: the long weekday name and a
/// two-digit year.
pub let rfc850 : String = "%A, %d-%b-%y %H:%M:%S %Z"

///|
/// `"Mon, 02 Jan 2006 15:04:05 -0700"` in Go: `rfc1123` with a numeric
/// offset.
pub let rfc1123z : String = "%a, %d %b %Y %H:%M:%S %z"
