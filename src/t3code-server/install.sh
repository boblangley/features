#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_root
check_debian_family
ensure_nodejs "${NODEVERSION}"
ensure_apt_packages build-essential python3 make g++

if [ "${INSTALLCODEXCLI}" = "true" ] && ! command -v codex >/dev/null 2>&1; then
    install_npm_global "@openai/codex" "${CODEXVERSION}"
fi

if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI is not installed. T3 Code requires codex to be available and authenticated before the service can be used."
fi

install_npm_global "t3" "${VERSION}"
ensure_apt_packages ca-certificates

service_user="$(pick_service_user "${SERVICEUSER}")"
service_home="$(user_home_dir "${service_user}")"

cat >/usr/local/bin/t3code-server <<EOF
#!/usr/bin/env bash
set -euo pipefail

export HOME="${service_home}"
export T3CODE_PORT="\${T3CODE_PORT:-${PORT}}"
export T3CODE_HOST="\${T3CODE_HOST:-${HOST}}"

exec /usr/local/bin/t3 serve --host="\${T3CODE_HOST}" --port="\${T3CODE_PORT}" "\$@"
EOF
chmod 0755 /usr/local/bin/t3code-server

cat >/etc/default/t3code <<EOF
T3CODE_PORT=${PORT}
T3CODE_HOST=${HOST}
EOF

cat >/etc/systemd/system/t3code.service <<EOF
[Unit]
Description=T3 Code headless server
After=network.target

[Service]
Type=simple
User=${service_user}
WorkingDirectory=${service_home}
EnvironmentFile=-/etc/default/t3code
ExecStart=/usr/local/bin/t3code-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable t3code.service || true
else
    warn "systemctl is not available in this image. The T3 Code service unit was installed but not enabled."
fi

command -v t3 >/dev/null 2>&1 || err "T3 Code was not added to PATH."
log "Installed T3 Code $(t3 --version)"
