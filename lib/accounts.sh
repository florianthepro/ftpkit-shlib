ftpkit_group_exists() { getent group "$1" >/dev/null 2>&1; }
ftpkit_user_exists() { getent passwd "$1" >/dev/null 2>&1; }
ftpkit_group_ensure() {
    ftpkit_require_root && ftpkit_require_confirmed_change || return
    ftpkit_group_exists "$1" || groupadd --system -- "$1"
}
ftpkit_user_ensure() {
    ftpkit_require_root && ftpkit_require_confirmed_change || return
    _fk_user=$1; _fk_group=$2; _fk_home=${3:-/nonexistent}; _fk_shell=${4:-/usr/sbin/nologin}
    ftpkit_group_ensure "$_fk_group" || return
    ftpkit_user_exists "$_fk_user" || useradd --system --gid "$_fk_group" --home-dir "$_fk_home" --shell "$_fk_shell" --no-create-home -- "$_fk_user"
}
ftpkit_directory_ensure() {
    ftpkit_require_confirmed_change || return
    _fk_path=$1; _fk_mode=${2:-0750}; _fk_owner=${3:-}; _fk_group=${4:-}
    ftpkit_validate_absolute_path "$_fk_path" || return 2
    mkdir -p -- "$_fk_path" && chmod "$_fk_mode" "$_fk_path" || return
    if [ -n "$_fk_owner" ]; then chown "$_fk_owner${_fk_group:+:$_fk_group}" "$_fk_path"; fi
}
ftpkit_permissions_set() {
    ftpkit_require_confirmed_change || return
    _fk_path=$1; _fk_mode=$2; _fk_owner=${3:-}; _fk_group=${4:-}
    [ -e "$_fk_path" ] || return 2
    chmod "$_fk_mode" "$_fk_path" || return
    if [ -n "$_fk_owner" ]; then chown "$_fk_owner${_fk_group:+:$_fk_group}" "$_fk_path"; fi
}
ftpkit_safe_remove_tree() {
    ftpkit_require_confirmed_change || return
    _fk_path=$1; _fk_root=$2
    ftpkit_path_within "$_fk_path" "$_fk_root" || return 2
    [ -e "$_fk_path" ] || return 0
    rm -rf -- "$_fk_path"
}
