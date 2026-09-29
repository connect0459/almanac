///|
/// A format-string or parse-input error raised by the `format` package.
pub suberror ParseError {
  UnknownSpecifier(Char)
  TrailingPercent
  MissingField(Item)
  InvalidRfc3339
  /// `to_rfc2822`'s year is outside RFC 2822's `0..=9999` range, or
  /// `parse_from_rfc2822` fails to match the (strict, non-obsolete)
  /// grammar this project supports.
  InvalidRfc2822
  /// A required field (e.g. no date field at all, or an offset missing
  /// when `%z` isn't in the format) was never populated while walking
  /// the token sequence.
  IncompleteFields
  /// Two populated fields disagree (a parsed `%A`/`%a` weekday, or a
  /// redundant `%j`, doesn't match the date built from `%Y`/`%m`/`%d`),
  /// or a field's value doesn't form a valid date/time/offset (e.g. an
  /// out-of-range hour).
  InconsistentFields
  /// The input text didn't match a literal or specifier at some
  /// position, including `%Z`, which is never parseable (see
  /// `parse_date`/`parse_time`/`parse_date_time`/`parse_date_time_tz`).
  InputMismatch
} derive(Eq, @debug.Debug)

///|
pub extend ParseError with Eq::{equal}

///|
pub extend ParseError with Eq::{not_equal}

///|
pub extend ParseError with @debug.Debug::{to_repr}
