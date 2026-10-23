#!/bin/sh

if [ "${FTPKIT_SHLIB_LOADED:-0}" = 1 ]; then
    return 0 2>/dev/null || exit 0
fi
FTPKIT_SHLIB_LOADED=1
FTPKIT_SHLIB_VERSION=1.0.0

_ftpkit_main=${FTPKIT_SHLIB_PATH:-${0}}
if [ -n "${FTPKIT_SHLIB_DIR:-}" ]; then
    _ftpkit_root=$FTPKIT_SHLIB_DIR
else
    _ftpkit_root=$(CDPATH= cd -- "$(dirname -- "$_ftpkit_main")" 2>/dev/null && pwd)
fi

for _ftpkit_module in core platform files accounts network services certificates backend; do
    if [ ! -r "$_ftpkit_root/lib/$_ftpkit_module.sh" ]; then
        printf '%s
' "ftpkit-shlib: missing module $_ftpkit_module" >&2
        return 1 2>/dev/null || exit 1
    fi
    . "$_ftpkit_root/lib/$_ftpkit_module.sh"
done
unset _ftpkit_main _ftpkit_root _ftpkit_module
