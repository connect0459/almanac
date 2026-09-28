///|
/// Reads `/etc/localtime`'s raw bytes, or `Bytes::default()` if it could
/// not be read.
extern "C" fn read_etc_localtime() -> Bytes = "chrono_read_etc_localtime"

///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads live OS state (`$TZ`, `/etc/localtime`): unlike
/// `Local::resolve`, not a pure function of its arguments.
pub fn Local::new() -> Local? {
  let localtime_bytes = match read_etc_localtime() {
    b if b.length() == 0 => None
    b => Some(b)
  }
  Local::resolve(@env.get_env_var("TZ"), localtime_bytes)
}
