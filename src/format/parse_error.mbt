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
  /// Two populated fields contradict each other (a parsed `%A`/`%a`
  /// weekday, or a redundant `%j`, doesn't match the date built from
  /// `%Y`/`%m`/`%d`; two `%H` readings differ), or a combination is not
  /// allowed (an offset given to `to_date_time_in`).
  InconsistentFields
  /// A parsed field's value lies outside what it can hold, so no date,
  /// time or offset can be built from it (an hour of 24, February 30, a
  /// week that does not exist in its year, an offset beyond `±23:59:59`).
  FieldOutOfRange
  /// The input text didn't match a literal or specifier at some
  /// position, including a `%Z` with no name to consume (see
  /// `parse_date`/`parse_time`/`parse_date_time`/`parse_date_time_tz`).
  InputMismatch
  /// The input was exhausted when the format still had an item to match
  /// (e.g. `"2024-03"` against `%F`).
  InputTooShort
  /// The format was fully matched but input remains after it (e.g.
  /// `"2024-03-05 rest"` against `%F`); the `_and_remainder` and
  /// `parse_items_and_remainder` functions return that tail instead.
  TrailingInput
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
    InconsistentFields => "parsed fields contradict each other"
    FieldOutOfRange => "a parsed field is out of range"
    InputMismatch => "input does not match the format"
    InputTooShort => "input ended before the format did"
    TrailingInput => "input has unparsed text after the format"
  }
  logger.write_string(message)
}

///|
pub extend ParseError with Show::{to_string, output}
