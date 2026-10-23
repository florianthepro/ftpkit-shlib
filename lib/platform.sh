ftpkit_detect_os() {
    [ -r "${FTPKIT_OS_RELEASE:-/etc/os-release}" ] || return 1
    _fk_id= _fk_version= _fk_like=
    while IFS='=' read -r _fk_key _fk_value; do
        _fk_value=$(printf '%s' "$_fk_value" | sed 's/^"//;s/"$//')
        case $_fk_key in ID) _fk_id=$_fk_value ;; VERSION_ID) _fk_version=$_fk_value ;; ID_LIKE) _fk_like=$_fk_value ;; esac
    done < "${FTPKIT_OS_RELEASE:-/etc/os-release}"
    [ -n "$_fk_id" ] || return 1
    printf '%s|%s|%s\n' "$_fk_id" "$_fk_version" "$_fk_like"
}
ftpkit_detect_package_manager() {
    for _fk_pm in apt-get dnf yum apk pacman zypper; do ftpkit_command_exists "$_fk_pm" && { printf '%s\n' "$_fk_pm"; return 0; }; done
    return 1
}
ftpkit_package_installed() {
    [ -n "${1:-}" ] || return 2
    _fk_pm=${2:-$(ftpkit_detect_package_manager)}
    case $_fk_pm in
        apt-get) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed' ;;
        dnf|yum) rpm -q "$1" >/dev/null 2>&1 ;;
        apk) apk info -e "$1" >/dev/null 2>&1 ;;
        pacman) pacman -Q "$1" >/dev/null 2>&1 ;;
        zypper) rpm -q "$1" >/dev/null 2>&1 ;;
        *) return 2 ;;
    esac
}
ftpkit_package_install() {
    ftpkit_require_root && ftpkit_require_confirmed_change || return
    [ "$#" -gt 0 ] || return 2
    _fk_pm=$(ftpkit_detect_package_manager) || return
    case $_fk_pm in
        apt-get) DEBIAN_FRONTEND=noninteractive apt-get install -y -- "$@" ;;
        dnf|yum) "$_fk_pm" install -y -- "$@" ;;
        apk) apk add -- "$@" ;;
        pacman) pacman --noconfirm -S -- "$@" ;;
        zypper) zypper --non-interactive install -- "$@" ;;
    esac
}
