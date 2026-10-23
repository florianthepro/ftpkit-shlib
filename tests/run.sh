#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export FTPKIT_SHLIB_DIR=$ROOT
. "$ROOT/ftpkit.sh"
ftpkit_init

_pass=0
_fail=0
ok() { _pass=$((_pass + 1)); printf '.\n'; }
not_ok() { _fail=$((_fail + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { if "$@"; then ok; else not_ok "$*"; fi; }
assert_failure() { if "$@"; then not_ok "unexpected success: $*"; else ok; fi; }
assert_equal() { if [ "$1" = "$2" ]; then ok; else not_ok "expected [$2], got [$1]"; fi; }

assert_equal "$FTPKIT_SHLIB_VERSION" 1.0.0
assert_success ftpkit_port_valid 443
assert_failure ftpkit_port_valid 0
assert_failure ftpkit_port_valid 65536
assert_failure ftpkit_port_valid '8;id'
assert_success ftpkit_validate_absolute_path /sites/example
assert_failure ftpkit_validate_absolute_path ../etc/passwd
assert_failure ftpkit_validate_absolute_path /sites/../etc
assert_failure ftpkit_require_confirmed_change
ftpkit_changes_begin plan-1
assert_failure ftpkit_require_confirmed_change
assert_failure ftpkit_confirm_changes wrong
assert_success ftpkit_confirm_changes plan-1
assert_success ftpkit_require_confirmed_change

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$TMP/root/child" "$TMP/outside"
assert_success ftpkit_path_within "$TMP/root/child" "$TMP/root"
assert_failure ftpkit_path_within "$TMP/root" "$TMP/root"
assert_failure ftpkit_path_within "$TMP/outside" "$TMP/root"
printf old > "$TMP/root/target"
printf new > "$TMP/source"
assert_success ftpkit_atomic_replace "$TMP/source" "$TMP/root/target" 0600
assert_equal "$(cat "$TMP/root/target")" new
assert_success ftpkit_backup_create "$TMP/root/target" "$TMP/backup.tar"
mkdir "$TMP/restore"
assert_success ftpkit_backup_restore "$TMP/backup.tar" "$TMP/restore"
assert_equal "$(cat "$TMP/restore/target")" new
assert_equal "$(sha256sum "$TMP/source" | awk '{print $1}')" "$(sha256sum "$TMP/root/target" | awk '{print $1}')"

OS_RELEASE=$TMP/os-release
printf 'ID="synthetic"\nVERSION_ID="1"\nID_LIKE="test"\n' > "$OS_RELEASE"
FTPKIT_OS_RELEASE=$OS_RELEASE
assert_equal "$(ftpkit_detect_os)" 'synthetic|1|test'
assert_failure ftpkit_download_verified http://example.invalid/a "$(printf '%064d' 0)" "$TMP/x"
ftpkit_changes_end
assert_failure ftpkit_safe_remove_tree "$TMP/root/child" "$TMP/root"

for file in "$ROOT"/*.sh "$ROOT"/lib/*.sh "$ROOT"/tests/*.sh; do sh -n "$file" || not_ok "syntax $file"; done
[ "$_fail" -eq 0 ] || exit 1
printf '%s\n' "PASS: $_pass assertions"
