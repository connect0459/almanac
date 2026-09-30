///|
/// The reason a `round`, `round_up` or `truncate` call could not produce a
/// result.
pub(all) enum RoundingError {
  /// The granularity is zero or negative.
  InvalidGranularity
  /// The granularity combines a whole-second part with a sub-second
  /// remainder (e.g. 1.5 seconds); only a purely sub-second or a
  /// whole-second-or-larger granularity is supported.
  MixedGranularity
  /// The rounded value would leave the representable range of the type.
  OutOfRange
} derive(Eq, @debug.Debug)

///|
pub extend RoundingError with Eq::{equal}

///|
pub extend RoundingError with Eq::{not_equal}

///|
pub extend RoundingError with @debug.Debug::{to_repr}

///|
pub impl Show for RoundingError with fn output(self, logger) {
  let message = match self {
    InvalidGranularity => "rounding granularity must be positive"
    MixedGranularity =>
      "rounding granularity must be either sub-second or a whole number of seconds"
    OutOfRange => "rounded value is out of range"
  }
  logger.write_string(message)
}

///|
pub extend RoundingError with Show::{to_string, output}
