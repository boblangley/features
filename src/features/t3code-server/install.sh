#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

require_root
check_debian_family
ensure_s6_overlay
ensure_apt_packages build-essential ca-certificates python3

[[ "${PORT}" =~ ^[0-9]+$ ]] || err "port must be an integer between 1 and 65535."
[ "${#PORT}" -le 5 ] || err "port must be an integer between 1 and 65535."
((10#${PORT} >= 1 && 10#${PORT} <= 65535)) || err "port must be an integer between 1 and 65535."

if [ -n "${DNSNAME}" ]; then
    [ "${#DNSNAME}" -le 253 ] || err "dnsName exceeds the 253-character DNS limit."
    IFS=. read -r -a dns_labels <<<"${DNSNAME}"
    [ "${#dns_labels[@]}" -ge 2 ] || err "dnsName must be a fully qualified DNS name."
    for label in "${dns_labels[@]}"; do
        [[ "${label}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] \
            || err "dnsName contains an invalid DNS label: '${label}'."
    done
    [ -d /etc/caddy/conf.d ] \
        || err "dnsName requires the Caddy Feature and its /etc/caddy/conf.d directory."
fi

service_user="$(pick_service_user "${SERVICEUSER}")"
service_home="$(user_home_dir "${service_user}")"
[ -n "${service_home}" ] || err "Unable to resolve the home directory for ${service_user}."

install -d -m 0755 -o "${service_user}" -g "$(id -gn "${service_user}")" \
    "${service_home}/.t3"

package_spec="t3@${VERSION}"
log "Installing ${package_spec} globally"
env \
    NPM_CONFIG_ENGINE_STRICT=true \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    npm install --global --prefix /usr/local "${package_spec}"

t3_binary=/usr/local/bin/t3
[ -x "${t3_binary}" ] || err "T3 Code was not installed at ${t3_binary}."

printf -v quoted_home '%q' "${service_home}"
printf -v quoted_t3 '%q' "${t3_binary}"
printf -v quoted_port '%q' "${PORT}"
printf -v quoted_host '%q' "${HOST}"
printf -v quoted_mode '%q' "${SERVEMODE}"

cat >/usr/local/bin/t3code-server <<EOF
#!/usr/bin/env bash
set -euo pipefail

export HOME=${quoted_home}
export T3CODE_NO_BROWSER=1

default_port=${quoted_port}
default_host=${quoted_host}
default_mode=${quoted_mode}
port="\${T3CODE_PORT:-\${default_port}}"
host="\${T3CODE_HOST:-\${default_host}}"
mode="\${T3CODE_SERVE_MODE:-\${default_mode}}"
args=(serve --host="\${host}" --port="\${port}" --base-dir "\${HOME}/.t3")
if [ -n "\${mode}" ]; then
    args+=(--mode="\${mode}")
fi

exec ${quoted_t3} "\${args[@]}" "\$@"
EOF
chmod 0755 /usr/local/bin/t3code-server

service_dir=/etc/s6-overlay/s6-rc.d/t3code-server
install -d -m 0755 "${service_dir}/dependencies.d"
printf 'longrun\n' >"${service_dir}/type"
touch "${service_dir}/dependencies.d/base"

printf -v quoted_user '%q' "${service_user}"
cat >"${service_dir}/run" <<EOF
#!/command/with-contenv bash
exec s6-setuidgid ${quoted_user} /usr/local/bin/t3code-server
EOF
chmod 0755 "${service_dir}/run"
touch /etc/s6-overlay/user-bundles.d/user/contents.d/t3code-server

if [ -n "${DNSNAME}" ]; then
    cat >/etc/caddy/conf.d/t3code-server.caddy <<EOF
${DNSNAME} {
    reverse_proxy 127.0.0.1:${PORT}
}
EOF
    chmod 0644 /etc/caddy/conf.d/t3code-server.caddy
    log "Configured https://${DNSNAME} to proxy to T3 Code on 127.0.0.1:${PORT}."
fi

run_as_user "${service_user}" env HOME="${service_home}" "${t3_binary}" --version >/dev/null
log "Installed T3 Code $(run_as_user "${service_user}" env HOME="${service_home}" "${t3_binary}" --version)"
