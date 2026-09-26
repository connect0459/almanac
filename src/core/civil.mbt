///|
/// Converts a proleptic Gregorian calendar date into a day count relative to
/// the Unix epoch (`1970-01-01` is day `0`). `month` and `day` are not range
/// checked; callers are responsible for validating the input.
///
/// Closed-form algorithm (no lookup table), following Neri and Schneider,
/// "Euclidean Affine Functions and Applications to Calendar Algorithms"
/// (as also used by Howard Hinnant's `days_from_civil`).
pub fn days_from_civil(year : Int, month : Int, day : Int) -> Int {
  let y = if month <= 2 { year - 1 } else { year }
  let era = (if y >= 0 { y } else { y - 399 }) / 400
  let yoe = y - era * 400
  let mp = if month > 2 { month - 3 } else { month + 9 }
  let doy = (153 * mp + 2) / 5 + day - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
/// Converts a day count relative to the Unix epoch (`1970-01-01` is day `0`)
/// back into a proleptic Gregorian `(year, month, day)` triple. Inverse of
/// `days_from_civil`.
pub fn civil_from_days(days : Int) -> (Int, Int, Int) {
  let z = days + 719468
  let era = (if z >= 0 { z } else { z - 146096 }) / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let day = doy - (153 * mp + 2) / 5 + 1
  let month = if mp < 10 { mp + 3 } else { mp - 9 }
  (if month <= 2 { y + 1 } else { y }, month, day)
}
