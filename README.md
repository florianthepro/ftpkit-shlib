# ftpkit-shlib

`ftpkit-shlib` is the generic POSIX-shell foundation for the four-repository ftpkit architecture. It supplies guarded system helpers used by the `backend` and app bootstrap scripts. It contains no Python business logic and no application-specific rules.

## Install

```sh
sudo ./install.sh
```

The default installation target is `/usr/local/lib/ftpkit-shlib`. Override it with `PREFIX=/custom/path`.

## Use

```sh
. /usr/local/lib/ftpkit-shlib/ftpkit.sh
ftpkit_init
ftpkit_detect_os
ftpkit_find_free_port 8765 8865
```

Mutating functions require both an explicit change scope and confirmation:

```sh
ftpkit_changes_begin "approved-plan-id"
ftpkit_confirm_changes "approved-plan-id"
ftpkit_directory_ensure /sites/example 0750 app-user app-group
ftpkit_changes_end
```

`ftpkit_changes_begin` alone does not authorize changes. The same non-empty plan identifier must be confirmed. This lets the central `backend` keep planning, confirmation and execution separate.

## Bootstrap contract

`ftpkit_backend_ensure` checks `/sites/backend`, registry, systemd service, service state, health endpoint and protocol compatibility. If installation is required, supply a verified backend archive:

```sh
FTPKIT_BACKEND_ARCHIVE_URL=https://downloads.example.invalid/backend.tar.gz \
FTPKIT_BACKEND_ARCHIVE_SHA256=<64-hex-digest> \
FTPKIT_BACKEND_INSTALLER=./install-backend.sh \
ftpkit_backend_ensure
```

The installer is invoked with the downloaded archive path and staging directory. It must perform the backend-specific transaction. This library never invents repository URLs or duplicates manager business logic.

## Tests

```sh
./tests/run.sh
```

The test suite runs with POSIX `sh`, uses isolated temporary paths and does not modify the host system.
