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
  /// `parse_duration`'s input is malformed (no digits, a missing or unknown
  /// unit, a misplaced sign, stray characters) or its value falls outside
  /// `TimeDelta`'s representable range.
  InvalidDuration
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
  /// position, including a `%Z` with no name to consume (see
  /// `parse_date`/`parse_time`/`parse_date_time`/`parse_date_time_tz`).
  InputMismatch
} derive(Eq, @debug.Debug)

///|
pub extend ParseError with Eq::{equal}

///|
pub extend ParseError with Eq::{not_equal}

///|
pub extend ParseError with @debug.Debug::{to_repr}

///|
/// Renders a one-line, human-readable message for the failure, e.g.
/// `input does not match the format`.
pub impl Show for ParseError with fn output(self, logger) {
  let message = match self {
    UnknownSpecifier(c) => "unknown format specifier '%\{c}'"
    TrailingPercent => "format string ends with a dangling '%'"
    MissingField(item) =>
      "format item requires a field the value does not have: " +
      @debug.to_string(item)
    InvalidRfc3339 => "invalid RFC 3339 date-time"
    InvalidRfc2822 => "invalid RFC 2822 date-time"
    InvalidDuration => "invalid duration"
    IncompleteFields => "not enough fields to build the requested value"
    InconsistentFields => "parsed fields are inconsistent or out of range"
    InputMismatch => "input does not match the format"
  }
  logger.write_string(message)
}

///|
pub extend ParseError with Show::{to_string, output}
