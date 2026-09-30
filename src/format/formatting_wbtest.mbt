///|
test "rendering a padded numeric of a kind without a default width reports MissingField" {
  let date = Some(@core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
  let time = Some(@core.NaiveTime::from_hms(9, 5, 3).unwrap())
  for kind in [Nanosecond, DotFraction, Nanosecond3, Nanosecond6, Timestamp] {
    let item = PaddedNumeric(kind, NoPad)
    try render([item], date, time, None, Some(0L)) |> ignore catch {
      MissingField(reported) => assert_eq(reported, item)
      e => fail("expected MissingField for \{@debug.to_string(kind)}, got \{e}")
    } noraise {
      _ => fail("expected MissingField for \{@debug.to_string(kind)}")
    }
  }
}
