ftpkit_systemd_available() { ftpkit_command_exists systemctl && [ -d /run/systemd/system ]; }
ftpkit_service_exists() { ftpkit_systemd_available && systemctl cat "$1" >/dev/null 2>&1; }
ftpkit_service_active() { ftpkit_systemd_available && systemctl is-active --quiet "$1"; }
ftpkit_service_enable_start() { ftpkit_require_root && ftpkit_require_confirmed_change && ftpkit_systemd_available || return; systemctl enable --now "$1"; }
ftpkit_service_stop() { ftpkit_require_root && ftpkit_require_confirmed_change && ftpkit_systemd_available || return; systemctl stop "$1"; }
ftpkit_service_restart() { ftpkit_require_root && ftpkit_require_confirmed_change && ftpkit_systemd_available || return; systemctl restart "$1"; }
ftpkit_service_install() {
    ftpkit_require_root && ftpkit_require_confirmed_change && ftpkit_systemd_available || return
    _fk_source=$1; _fk_name=$2
    case $_fk_name in ''|*[!A-Za-z0-9_.@-]*) return 2 ;; esac
    ftpkit_atomic_replace "$_fk_source" "/etc/systemd/system/$_fk_name" 0644 root root && systemctl daemon-reload
}
ftpkit_service_remove() {
    ftpkit_require_root && ftpkit_require_confirmed_change && ftpkit_systemd_available || return
    _fk_name=$1; case $_fk_name in ''|*[!A-Za-z0-9_.@-]*) return 2 ;; esac
    systemctl disable --now "$_fk_name" 2>/dev/null || true
    rm -f -- "/etc/systemd/system/$_fk_name" && systemctl daemon-reload
}
ftpkit_caddy_validate() {
    _fk_config=$1; [ -f "$_fk_config" ] || return 2
    ftpkit_require_command caddy || return
    caddy validate --config "$_fk_config" --adapter caddyfile
}
