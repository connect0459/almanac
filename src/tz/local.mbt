///|
priv enum LocalKind {
  Iana(Location)
  Fixed(FixedOffset)
}

///|
/// The OS-configured local time zone, resolved from `$TZ` or, when unset,
/// `/etc/localtime`. Only available on `native`: resolving it requires file
/// I/O that `js`/`wasm`/`wasm-gc` have no host-provided access to.
pub struct Local {
  priv kind : LocalKind
}

///|
/// Resolves `tz_env` (the `TZ` environment variable) and `localtime_bytes`
/// (raw TZif bytes, e.g. from `/etc/localtime`) into a `Local`, following
/// the same precedence as the POSIX `TZ` convention: an empty `TZ` means
/// UTC, a non-empty `TZ` is looked up as an IANA zone name (`None` if it
/// names no known zone, regardless of `localtime_bytes`), and `localtime_bytes`
/// is only consulted when `TZ` is unset entirely.
pub fn Local::resolve(tz_env : String?, localtime_bytes : Bytes?) -> Local? {
  match tz_env {
    Some("") => Some(Local::{ kind: Fixed(FixedOffset::east(0).unwrap()), })
    Some(name) => Location::load(name).map(loc => Local::{ kind: Iana(loc), })
    None =>
      localtime_bytes
      .bind(bytes => Location::from_tzif_bytes(bytes))
      .map(loc => Local::{ kind: Iana(loc), })
  }
}

///|
pub impl TimeZone for Local with fn offset_from_utc(self, utc) {
  match self.kind {
    Iana(loc) => loc.offset_from_utc(utc)
    Fixed(off) => off.offset_from_utc(utc)
  }
}

///|
pub impl TimeZone for Local with fn offset_from_local(self, naive_local) {
  match self.kind {
    Iana(loc) => loc.offset_from_local(naive_local)
    Fixed(off) => off.offset_from_local(naive_local)
  }
}

///|
pub impl TimeZone for Local with fn tz_name(self, utc) {
  match self.kind {
    Iana(loc) => loc.tz_name(utc)
    Fixed(off) => off.tz_name(utc)
  }
}

///|
pub extend Local with TimeZone::{offset_from_utc, offset_from_local, tz_name}
