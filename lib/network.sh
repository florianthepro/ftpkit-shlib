ftpkit_port_valid() { case ${1:-} in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 65535 ] 2>/dev/null; }
ftpkit_listener_list() {
    if ftpkit_command_exists ss; then ss -lntup 2>/dev/null; elif ftpkit_command_exists netstat; then netstat -lntup 2>/dev/null; else return 1; fi
}
ftpkit_port_in_use() {
    ftpkit_port_valid "$1" || return 2
    if ftpkit_command_exists ss; then ss -lntH 2>/dev/null | awk -v p="$1" '{a=$4; sub(/^.*:/,"",a); if (a==p) found=1} END {exit !found}'
    elif ftpkit_command_exists netstat; then netstat -lnt 2>/dev/null | awk -v p="$1" 'NR>2 {a=$4; sub(/^.*:/,"",a); if (a==p) found=1} END {exit !found}'
    else return 3; fi
}
ftpkit_find_free_port() {
    _fk_port=$1; _fk_end=${2:-65535}; ftpkit_port_valid "$_fk_port" && ftpkit_port_valid "$_fk_end" && [ "$_fk_port" -le "$_fk_end" ] || return 2
    while [ "$_fk_port" -le "$_fk_end" ]; do ftpkit_port_in_use "$_fk_port"; _fk_status=$?; [ "$_fk_status" -eq 1 ] && { printf '%s\n' "$_fk_port"; return 0; }; [ "$_fk_status" -gt 1 ] && return "$_fk_status"; _fk_port=$((_fk_port + 1)); done
    return 1
}
ftpkit_process_for_port() {
    ftpkit_port_valid "$1" || return 2
    if ftpkit_command_exists ss; then ss -lntpH 2>/dev/null | awk -v p="$1" '{a=$4; sub(/^.*:/,"",a); if(a==p){print; found=1}} END{exit !found}'; else return 3; fi
}
ftpkit_detect_webservers() {
    _fk_found=1
    for _fk_service in caddy apache2 httpd nginx; do
        if ftpkit_command_exists systemctl && systemctl is-active --quiet "$_fk_service" 2>/dev/null; then printf '%s|active\n' "$_fk_service"; _fk_found=0
        elif pgrep -x "$_fk_service" >/dev/null 2>&1; then printf '%s|process\n' "$_fk_service"; _fk_found=0; fi
    done
    return "$_fk_found"
}
