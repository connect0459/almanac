///|
/// The current UTC instant, read from the host's wall clock.
///
/// The one function in this library that reads the host clock, so it is not
/// a function of its arguments. It is total: a clock outside `NaiveDate`'s
/// range (about 5.8 million years either side of 1970) is a broken
/// environment rather than a caller error, and this aborts on it. The
/// failure `Local::now` reports is different, an undetermined local zone.
pub fn Utc::now() -> DateTime[Utc] {
  let naive = @core.NaiveDateTime::from_timestamp_millis(
    @env.now().reinterpret_as_int64(),
  ).unwrap()
  DateTime::from_utc(naive, Utc::new())
}
