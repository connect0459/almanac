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
  Local::resolve(
    @env.get_env_var("TZ"),
    read_host_file,
    zoneinfo_dirs=zoneinfo_dirs(@env.get_env_var("ZONEINFO")),
  )
}

///|
/// The directories searched for TZif files by name: the `ZONEINFO` directory
/// when set and non-empty, then the standard system locations.
fn zoneinfo_dirs(zoneinfo_env : String?) -> Array[String] {
  let standard = [
    "/usr/share/zoneinfo", "/usr/share/lib/zoneinfo", "/usr/lib/locale/TZ", "/etc/zoneinfo",
  ]
  match zoneinfo_env {
    Some(dir) if dir != "" => [dir, ..standard]
    _ => standard
  }
}

///|
/// Loads the zone `name` (e.g. `"Asia/Tokyo"`) from the first of these that
/// has it: the directory named by `$ZONEINFO`, the system zoneinfo
/// directories (`/usr/share/zoneinfo` and its peers), then the embedded
/// database. This lets a host's tzdata newer than the embedded release take
/// effect. `None` if no source has `name`, or `name` is empty, absolute, or
/// contains `..`. Whether a file name matches regardless of case follows the
/// host file system (e.g. `"asia/tokyo"` is found on macOS); the embedded
/// database is always case-sensitive. Reads live OS state, so it is not a pure function of its
/// arguments; `Location::load` is the embedded-only counterpart.
pub fn Location::load_system(name : String) -> Location? {
  Location::load_from_dirs(
    name,
    zoneinfo_dirs(@env.get_env_var("ZONEINFO")),
    read_host_file,
  )
}
