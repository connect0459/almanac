///|
/// An unpadded 12-hour clock immediately followed by the (uppercase)
/// am/pm marker, no space.
pub const KITCHEN : String = "%-I:%M%p"

///|
/// A short month, space-padded day, and 24-hour `HH:MM:SS` — no year
/// (meant for display alongside separately-known context, not a
/// self-sufficient parseable timestamp).
pub const STAMP : String = "%b %e %H:%M:%S"

///|
/// `STAMP` with milliseconds.
pub const STAMP_MILLI : String = "%b %e %H:%M:%S.%3f"

///|
/// `STAMP` with microseconds.
pub const STAMP_MICRO : String = "%b %e %H:%M:%S.%6f"

///|
/// `STAMP` with nanoseconds.
pub const STAMP_NANO : String = "%b %e %H:%M:%S.%9f"

///|
/// Equivalent to `%F`.
pub const DATE_ONLY : String = "%F"

///|
/// Equivalent to `%T`.
pub const TIME_ONLY : String = "%T"

///|
/// A date and a time joined by one space, equivalent to `%F %T`.
pub const DATE_TIME : String = "%F %T"

///|
/// Equivalent to `%c`.
pub const ANSIC : String = "%a %b %e %H:%M:%S %Y"

///|
/// `ANSIC` with the zone name before the year.
pub const UNIX_DATE : String = "%a %b %e %H:%M:%S %Z %Y"

///|
/// A zero-padded day and a numeric offset before the year.
pub const RUBY_DATE : String = "%a %b %d %H:%M:%S %z %Y"
