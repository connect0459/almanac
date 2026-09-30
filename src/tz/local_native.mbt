///|
/// Reads `/etc/localtime`'s raw bytes, or `Bytes::default()` if it could
/// not be read.
extern "C" fn read_etc_localtime() -> Bytes = "chrono_read_etc_localtime"

///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads live OS state (`$TZ`, `/etc/localtime`), so it is not a
/// pure function of its arguments; the `$TZ` precedence rules it applies are
/// described on `Local`.
pub fn Local::new() -> Local? {
  Local::resolve(@env.get_env_var("TZ"), Some(read_etc_localtime()))
}

///|
/// The current instant expressed in the host's local time zone, or `None`
/// if that zone could not be determined (see `Local::new`). The counterpart
/// of `Utc::now`, and like it reads the host clock; the `None` is about the
/// zone, not the clock.
pub fn Local::now() -> DateTime[Local]? {
  Local::new().map(zone => Utc::now().with_timezone(zone))
}
