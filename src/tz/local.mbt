///|
priv enum LocalKind {
  Iana(Location)
  Fixed(FixedOffset)
  Posix(PosixTz)
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
/// UTC, a non-empty `TZ` is looked up as an IANA zone name and, failing
/// that, parsed as a bare POSIX rule (e.g. `JST-9`); `None` if it is
/// neither, regardless of `localtime_bytes`. `localtime_bytes` is only
/// consulted when `TZ` is unset entirely.
fn Local::resolve(tz_env : String?, localtime_bytes : Bytes?) -> Local? {
  match tz_env {
    Some("") => Some(Local::{ kind: Fixed(FixedOffset::east(0).unwrap()), })
    Some(name) =>
      match Location::load(name) {
        Some(loc) => Some(Local::{ kind: Iana(loc), })
        None => parse_posix_tz(name).map(p => Local::{ kind: Posix(p), })
      }
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
    Posix(p) => p.offset_from_utc(utc)
  }
}

///|
pub impl TimeZone for Local with fn offset_from_local(self, naive_local) {
  match self.kind {
    Iana(loc) => loc.offset_from_local(naive_local)
    Fixed(off) => off.offset_from_local(naive_local)
    Posix(p) => p.offset_from_local(naive_local)
  }
}

///|
pub impl TimeZone for Local with fn zone_name(self, utc) {
  match self.kind {
    Iana(loc) => loc.zone_name(utc)
    Fixed(off) => off.zone_name(utc)
    Posix(p) => p.zone_name(utc)
  }
}

///|
pub impl TimeZone for Local with fn is_dst(self, utc) {
  match self.kind {
    Iana(loc) => loc.is_dst(utc)
    Fixed(off) => off.is_dst(utc)
    Posix(p) => p.is_dst(utc)
  }
}

///|
pub impl TimeZone for Local with fn transition_bounds(self, utc) {
  match self.kind {
    Iana(loc) => loc.transition_bounds(utc)
    Fixed(off) => off.transition_bounds(utc)
    Posix(p) => p.transition_bounds(utc)
  }
}

///|
pub impl TimeZone for Local with fn offset_from_abbreviation(
  self,
  abbreviation,
  near,
) {
  match self.kind {
    Iana(loc) => loc.offset_from_abbreviation(abbreviation, near)
    Fixed(off) => off.offset_from_abbreviation(abbreviation, near)
    Posix(p) => p.offset_from_abbreviation(abbreviation, near)
  }
}

///|
pub extend Local with TimeZone::{
  offset_from_utc,
  offset_from_local,
  zone_name,
  is_dst,
  transition_bounds,
  offset_from_abbreviation,
}
