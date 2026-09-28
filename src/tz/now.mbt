///|
/// The current UTC instant, read from the host's wall clock.
pub fn Utc::now() -> DateTime[Utc] {
  let naive = @core.NaiveDateTime::from_timestamp_millis(
    @env.now().reinterpret_as_int64(),
  ).unwrap()
  DateTime::from_utc(naive, Utc::new())
}
