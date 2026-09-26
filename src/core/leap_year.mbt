///|
/// Whether `year` is a leap year in the proleptic Gregorian calendar:
/// divisible by 4, except centuries, which must be divisible by 400.
pub fn is_leap_year(year : Int) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}
