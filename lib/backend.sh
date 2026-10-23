ftpkit_http_health() {
    _fk_url=$1; _fk_timeout=${2:-5}
    case $_fk_url in https://*|http://*) ;; *) return 2 ;; esac
    if ftpkit_command_exists curl; then curl -fsS --max-time "$_fk_timeout" "$_fk_url" >/dev/null
    elif ftpkit_command_exists wget; then wget -q -T "$_fk_timeout" -O /dev/null "$_fk_url"
    else return 3; fi
}
ftpkit_backend_status() {
    _fk_root=${FTPKIT_BACKEND_ROOT:-/sites/backend}
    _fk_registry=${FTPKIT_BACKEND_REGISTRY:-$_fk_root/data/registry.json}
    _fk_service=${FTPKIT_BACKEND_SERVICE:-ftpkit-backend.service}
    _fk_health=${FTPKIT_BACKEND_HEALTH_URL:-}
    _fk_protocol=${FTPKIT_MANAGEMENT_PROTOCOL_VERSION:-1}
    [ -d "$_fk_root" ] || { printf '%s\n' missing-root; return 10; }
    [ -f "$_fk_registry" ] || { printf '%s\n' missing-registry; return 11; }
    grep -q '"app_id"[[:space:]]*:[[:space:]]*"backend"' "$_fk_registry" || { printf '%s\n' unregistered; return 12; }
    ftpkit_service_exists "$_fk_service" || { printf '%s\n' missing-service; return 13; }
    ftpkit_service_active "$_fk_service" || { printf '%s\n' inactive-service; return 14; }
    [ -n "$_fk_health" ] || { printf '%s\n' missing-health-url; return 15; }
    ftpkit_http_health "$_fk_health" || { printf '%s\n' unhealthy; return 16; }
    grep -q '"protocol_version"[[:space:]]*:[[:space:]]*'"$_fk_protocol" "$_fk_registry" || { printf '%s\n' incompatible-protocol; return 17; }
    printf '%s\n' ready
}
ftpkit_download_verified() {
    _fk_url=$1; _fk_digest=$2; _fk_output=$3
    case $_fk_digest in [0-9a-fA-F][0-9a-fA-F]*) [ "${#_fk_digest}" -eq 64 ] || return 2 ;; *) return 2 ;; esac
    case $_fk_url in https://*) ;; *) return 2 ;; esac
    if ftpkit_command_exists curl; then curl -fsSL --proto '=https' --tlsv1.2 -o "$_fk_output" "$_fk_url"
    elif ftpkit_command_exists wget; then wget -q --https-only -O "$_fk_output" "$_fk_url"
    else return 3; fi || return
    _fk_actual=$(sha256sum "$_fk_output" | awk '{print $1}') || return
    [ "$(printf '%s' "$_fk_actual" | tr 'A-F' 'a-f')" = "$(printf '%s' "$_fk_digest" | tr 'A-F' 'a-f')" ] || { rm -f -- "$_fk_output"; return 4; }
}
ftpkit_backend_bootstrap() {
    ftpkit_require_root && ftpkit_require_confirmed_change || return
    [ -n "${FTPKIT_BACKEND_ARCHIVE_URL:-}" ] && [ -n "${FTPKIT_BACKEND_ARCHIVE_SHA256:-}" ] && [ -n "${FTPKIT_BACKEND_INSTALLER:-}" ] || return 2
    [ -x "$FTPKIT_BACKEND_INSTALLER" ] || return 2
    _fk_stage=$(ftpkit_temp_dir) || return
    _fk_archive=$_fk_stage/backend.archive
    ftpkit_download_verified "$FTPKIT_BACKEND_ARCHIVE_URL" "$FTPKIT_BACKEND_ARCHIVE_SHA256" "$_fk_archive" || return
    "$FTPKIT_BACKEND_INSTALLER" "$_fk_archive" "$_fk_stage" || return
    ftpkit_backend_status
}
ftpkit_backend_ensure() {
    ftpkit_backend_status >/dev/null 2>&1 && return 0
    ftpkit_backend_bootstrap
}
