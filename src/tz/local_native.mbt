///|
/// Reads `/etc/localtime`'s raw bytes, or `Bytes::default()` if it could
/// not be read.
extern "C" fn read_etc_localtime() -> Bytes = "chrono_read_etc_localtime"

///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads live OS state (`$TZ`, `/etc/localtime`): unlike
/// `Local::resolve`, not a pure function of its arguments.
pub fn Local::new() -> Local? {
  Local::resolve(@env.get_env_var("TZ"), Some(read_etc_localtime()))
}
