ftpkit_certificate_key_valid() {
    [ -f "$1" ] || return 2
    ftpkit_require_command openssl || return
    openssl pkey -in "$1" -noout -passin pass: >/dev/null 2>&1
}
ftpkit_certificate_valid() {
    [ -f "$1" ] || return 2
    ftpkit_require_command openssl || return
    openssl x509 -in "$1" -noout >/dev/null 2>&1
}
ftpkit_certificate_matches_key() {
    ftpkit_certificate_valid "$1" && ftpkit_certificate_key_valid "$2" || return
    _fk_cert=$(openssl x509 -in "$1" -pubkey -noout | openssl pkey -pubin -outform DER 2>/dev/null | openssl dgst -sha256)
    _fk_key=$(openssl pkey -in "$2" -pubout -outform DER -passin pass: 2>/dev/null | openssl dgst -sha256)
    [ "$_fk_cert" = "$_fk_key" ]
}
ftpkit_certificate_info() {
    ftpkit_certificate_valid "$1" || return
    openssl x509 -in "$1" -noout -subject -issuer -serial -dates -fingerprint -sha256
}
ftpkit_certificate_not_expiring() {
    ftpkit_certificate_valid "$1" || return
    _fk_seconds=${2:-0}; case $_fk_seconds in ''|*[!0-9]*) return 2 ;; esac
    openssl x509 -in "$1" -noout -checkend "$_fk_seconds" >/dev/null
}
