///|
/// A format-string or parse-input error raised by the `format` package.
pub suberror ParseError {
  UnknownSpecifier(Char)
  TrailingPercent
  MissingField(Item)
} derive(Eq, @debug.Debug)

///|
pub extend ParseError with Eq::{equal}

///|
pub extend ParseError with Eq::{not_equal}

///|
pub extend ParseError with @debug.Debug::{to_repr}
