ftpkit_init() {
    FTPKIT_LOG_LEVEL=${FTPKIT_LOG_LEVEL:-info}
    FTPKIT_LOG_FILE=${FTPKIT_LOG_FILE:-}
    FTPKIT_TMP_ROOT=${FTPKIT_TMP_ROOT:-${TMPDIR:-/tmp}}
    FTPKIT_CLEANUP_PATHS=${FTPKIT_CLEANUP_PATHS:-}
    FTPKIT_CHANGE_PLAN=${FTPKIT_CHANGE_PLAN:-}
    FTPKIT_CONFIRMED_PLAN=${FTPKIT_CONFIRMED_PLAN:-}
    umask 077
}

ftpkit_log() {
    _fk_level=$1; shift
    case $_fk_level in debug|info|warn|error) ;; *) _fk_level=info ;; esac
    case ${FTPKIT_LOG_LEVEL:-info}:$_fk_level in
        error:debug|error:info|error:warn|warn:debug|warn:info|info:debug) return 0 ;;
    esac
    _fk_line=$(date -u '+%Y-%m-%dT%H:%M:%SZ')" [$_fk_level] $*"
    if [ -n "${FTPKIT_LOG_FILE:-}" ]; then printf '%s\n' "$_fk_line" >> "$FTPKIT_LOG_FILE"; fi
    if [ "$_fk_level" = error ] || [ "$_fk_level" = warn ]; then printf '%s\n' "$_fk_line" >&2; else printf '%s\n' "$_fk_line"; fi
}

ftpkit_info() { ftpkit_log info "$@"; }
ftpkit_warn() { ftpkit_log warn "$@"; }
ftpkit_error() { ftpkit_log error "$@"; }
ftpkit_die() { ftpkit_error "$*"; return 1; }
ftpkit_command_exists() { command -v "$1" >/dev/null 2>&1; }
ftpkit_require_command() { ftpkit_command_exists "$1" || ftpkit_die "Required command missing: $1"; }
ftpkit_require_root() { [ "$(id -u)" -eq 0 ] || ftpkit_die "Root privileges are required"; }

ftpkit_changes_begin() {
    [ -n "${1:-}" ] || return 2
    FTPKIT_CHANGE_PLAN=$1
    FTPKIT_CONFIRMED_PLAN=
    export FTPKIT_CHANGE_PLAN FTPKIT_CONFIRMED_PLAN
}
ftpkit_confirm_changes() {
    [ -n "${FTPKIT_CHANGE_PLAN:-}" ] && [ "${1:-}" = "$FTPKIT_CHANGE_PLAN" ] || return 2
    FTPKIT_CONFIRMED_PLAN=$1
    export FTPKIT_CONFIRMED_PLAN
}
ftpkit_changes_end() { FTPKIT_CHANGE_PLAN=; FTPKIT_CONFIRMED_PLAN=; export FTPKIT_CHANGE_PLAN FTPKIT_CONFIRMED_PLAN; }
ftpkit_require_confirmed_change() {
    [ -n "${FTPKIT_CHANGE_PLAN:-}" ] && [ "$FTPKIT_CHANGE_PLAN" = "${FTPKIT_CONFIRMED_PLAN:-}" ] || ftpkit_die "A confirmed system change plan is required"
}
ftpkit_run() { ftpkit_require_confirmed_change || return; "$@"; }

ftpkit_cleanup_add() {
    [ -n "${1:-}" ] || return 2
    case $1 in *'
'*) return 2 ;; esac
    FTPKIT_CLEANUP_PATHS=${FTPKIT_CLEANUP_PATHS}${FTPKIT_CLEANUP_PATHS:+
}$1
    export FTPKIT_CLEANUP_PATHS
}
ftpkit_cleanup() {
    _fk_old_ifs=$IFS; IFS='
'
    for _fk_path in ${FTPKIT_CLEANUP_PATHS:-}; do [ -n "$_fk_path" ] && rm -rf -- "$_fk_path"; done
    IFS=$_fk_old_ifs; FTPKIT_CLEANUP_PATHS=; export FTPKIT_CLEANUP_PATHS
}
ftpkit_install_traps() { trap 'ftpkit_cleanup' EXIT HUP INT TERM; }
ftpkit_temp_dir() {
    ftpkit_require_command mktemp || return
    _fk_dir=$(mktemp -d "${FTPKIT_TMP_ROOT:-${TMPDIR:-/tmp}}/ftpkit.XXXXXX") || return
    ftpkit_cleanup_add "$_fk_dir" || { rm -rf -- "$_fk_dir"; return 1; }
    printf '%s\n' "$_fk_dir"
}
