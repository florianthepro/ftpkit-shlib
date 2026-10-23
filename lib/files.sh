ftpkit_validate_absolute_path() { case ${1:-} in /*) case $1 in *'/../'*|*/..|*'/./'*|*/.|*'//'*) return 1 ;; esac ;; *) return 1 ;; esac; }
ftpkit_path_within() {
    ftpkit_validate_absolute_path "$1" && ftpkit_validate_absolute_path "$2" || return
    _fk_path=$(readlink -f -- "$1" 2>/dev/null || realpath -m -- "$1" 2>/dev/null) || return
    _fk_root=$(readlink -f -- "$2" 2>/dev/null || realpath -m -- "$2" 2>/dev/null) || return
    [ "$_fk_path" != "$_fk_root" ] || return 1
    case $_fk_path in "$_fk_root"/*) return 0 ;; *) return 1 ;; esac
}
ftpkit_atomic_replace() {
    ftpkit_require_confirmed_change || return
    _fk_source=$1; _fk_target=$2; _fk_mode=${3:-0600}; _fk_owner=${4:-}; _fk_group=${5:-}
    [ -f "$_fk_source" ] && ftpkit_validate_absolute_path "$_fk_target" || return 2
    _fk_parent=$(dirname -- "$_fk_target"); [ -d "$_fk_parent" ] || return 1
    _fk_tmp=$(mktemp "$_fk_parent/.ftpkit.XXXXXX") || return
    cp -- "$_fk_source" "$_fk_tmp" || { rm -f -- "$_fk_tmp"; return 1; }
    chmod "$_fk_mode" "$_fk_tmp" || { rm -f -- "$_fk_tmp"; return 1; }
    if [ -n "$_fk_owner" ]; then chown "$_fk_owner${_fk_group:+:$_fk_group}" "$_fk_tmp" || { rm -f -- "$_fk_tmp"; return 1; }; fi
    mv -f -- "$_fk_tmp" "$_fk_target"
}
ftpkit_backup_create() {
    ftpkit_require_confirmed_change || return
    _fk_source=$1; _fk_destination=$2
    [ -e "$_fk_source" ] && ftpkit_validate_absolute_path "$_fk_destination" || return 2
    _fk_parent=$(dirname -- "$_fk_destination"); mkdir -p -- "$_fk_parent" || return
    _fk_tmp=$(mktemp "$_fk_parent/.backup.XXXXXX") || return
    rm -f -- "$_fk_tmp"
    tar -C "$(dirname -- "$_fk_source")" -cpf "$_fk_tmp" -- "$(basename -- "$_fk_source")" || { rm -f -- "$_fk_tmp"; return 1; }
    chmod 0600 "$_fk_tmp" && mv -f -- "$_fk_tmp" "$_fk_destination"
}
ftpkit_backup_restore() {
    ftpkit_require_confirmed_change || return
    _fk_archive=$1; _fk_destination=$2
    [ -f "$_fk_archive" ] && ftpkit_validate_absolute_path "$_fk_destination" || return 2
    tar -tf "$_fk_archive" | while IFS= read -r _fk_member; do case $_fk_member in /*|*../*) exit 7 ;; esac; done || return 7
    tar -tvf "$_fk_archive" | awk 'substr($1,1,1) ~ /[lh]/ {exit 7}' || return 7
    _fk_parent=$(dirname -- "$_fk_destination")
    mkdir -p -- "$_fk_parent" || return
    _fk_stage=$(mktemp -d "$_fk_parent/.restore.XXXXXX") || return
    tar -C "$_fk_stage" -xpf "$_fk_archive" || { rm -rf -- "$_fk_stage"; return 1; }
    mkdir -p -- "$_fk_destination" || { rm -rf -- "$_fk_stage"; return 1; }
    cp -a -- "$_fk_stage/." "$_fk_destination/" || { rm -rf -- "$_fk_stage"; return 1; }
    rm -rf -- "$_fk_stage"
}
ftpkit_rollback_file() {
    ftpkit_require_confirmed_change || return
    [ -f "$1" ] || return 2
    ftpkit_atomic_replace "$1" "$2" "${3:-0600}" "${4:-}" "${5:-}"
}
