///|
/// The part of a cron expression that `Cron::parse` rejected: one of the six
/// time fields, the number of fields, or the `@` shorthand.
pub(all) enum CronField {
  Second
  Minute
  Hour
  DayOfMonth
  Month
  DayOfWeek
  FieldCount
  Shorthand
} derive(Eq, @debug.Debug)

///|
pub extend CronField with Eq::{equal}

///|
pub extend CronField with Eq::{not_equal}

///|
pub extend CronField with @debug.Debug::{to_repr}

///|
/// The failure of `Cron::parse`, carrying the field that could not be read.
pub suberror CronError {
  InvalidField(CronField)
} derive(Eq, @debug.Debug)

///|
pub extend CronError with Eq::{equal}

///|
pub extend CronError with Eq::{not_equal}

///|
pub extend CronError with @debug.Debug::{to_repr}

///|
fn CronField::label(self : CronField) -> String {
  match self {
    Second => "second"
    Minute => "minute"
    Hour => "hour"
    DayOfMonth => "day of month"
    Month => "month"
    DayOfWeek => "day of week"
    FieldCount => "number of fields"
    Shorthand => "shorthand"
  }
}

///|
/// Renders a one-line message naming the offending field, e.g.
/// `invalid cron expression: month`.
pub impl Show for CronError with fn output(self, logger) {
  match self {
    InvalidField(field) =>
      logger.write_string("invalid cron expression: " + field.label())
  }
}

///|
pub extend CronError with Show::{to_string, output}
