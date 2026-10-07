///|
/// Reads the file at the NUL-terminated `path`'s raw bytes, or
/// `Bytes::default()` if it could not be read.
#borrow(path)
extern "C" fn read_file_bytes(path : Bytes) -> Bytes = "almanac_read_file"

///|
fn read_host_file(path : String) -> Bytes? {
  let bytes = read_file_bytes(@utf8.encode(path) + b"\x00")
  if bytes.length() == 0 {
    None
  } else {
    Some(bytes)
  }
}

///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads live OS state (`$TZ`, `/etc/localtime`), so it is not a
/// pure function of its arguments; the `$TZ` precedence rules it applies are
/// described on `Local`.
pub fn Local::new() -> Local? {
  Local::resolve(@env.get_env_var("TZ"), read_host_file)
}
