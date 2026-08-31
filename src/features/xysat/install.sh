#!/usr/bin/env bash

set -euo pipefail

log() {
    echo "[xysat] $*"
}

err() {
    echo "[xysat] ERROR: $*" >&2
    exit 1
}

pick_service_user() {
    local requested="${1:-automatic}"
    local candidate

    if [ -n "${requested}" ] && [ "${requested}" != automatic ] && [ "${requested}" != auto ]; then
        id -u "${requested}" >/dev/null 2>&1 || err "Requested service user '${requested}' does not exist."
        echo "${requested}"
        return
    fi

    for candidate in "${_REMOTE_USER:-}" "${_CONTAINER_USER:-}" vscode root; do
        if [ -n "${candidate}" ] && id -u "${candidate}" >/dev/null 2>&1; then
            echo "${candidate}"
            return
        fi
    done

    err "Unable to resolve a service user."
}

[ "$(id -u)" -eq 0 ] || err "This Feature must run as root."
[ -r /etc/os-release ] || err "Unable to detect Linux distribution."
requested_version="${VERSION}"
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-} ${ID_LIKE:-}" in
    *debian*|*ubuntu*) ;;
    *) err "This Feature currently supports Debian/Ubuntu-based images." ;;
esac

for required_path in /init /command/s6-rc /etc/s6-overlay/s6-rc.d /etc/s6-overlay/user-bundles.d/user/contents.d; do
    [ -e "${required_path}" ] || err "This Feature requires an s6-overlay 3 image with /init as PID 1."
done

if [ "${requested_version}" = latest ]; then
    release_path=latest/download
elif [[ "${requested_version}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    release_path="download/v${requested_version#v}"
else
    err "version must be 'latest' or a semantic version such as '1.0.34'."
fi

case "$(uname -m)" in
    x86_64|amd64) architecture=x64 ;;
    arm64|aarch64) architecture=arm64 ;;
    *) err "Unsupported architecture: $(uname -m)." ;;
esac

service_user="$(pick_service_user "${SERVICEUSER}")"
service_group="$(id -gn "${service_user}")"
service_home="$(getent passwd "${service_user}" | cut -d: -f6)"
[ -n "${service_home}" ] || err "Unable to resolve the home directory for ${service_user}."

if [ -n "${CONDUCTORURL}" ]; then
    case "${CONDUCTORURL}" in
        http://*|https://*) ;;
        *) err "conductorUrl must use HTTP or HTTPS." ;;
    esac
fi
case "${APIKEYFILE}" in
    /*) ;;
    *) err "apiKeyFile must be an absolute path." ;;
esac

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl

install_dir=/opt/xyops/satellite
archive="$(mktemp)"
trap 'rm -f "${archive}"' EXIT
download_url="https://github.com/pixlcore/xysat/releases/${release_path}/satellite-linux-${architecture}.tar.gz"

log "Downloading ${download_url}"
curl --fail --location --silent --show-error --retry 5 --retry-all-errors \
    --output "${archive}" "${download_url}"
install -d -m 0755 "${install_dir}"
tar -xzf "${archive}" -C "${install_dir}"
[ -f "${install_dir}/package.json" ] || err "The xySat release did not contain package.json."
[ -x "${install_dir}/bin/node" ] || err "The xySat release did not contain its Node.js runtime."

chown -R "${service_user}:${service_group}" "${install_dir}"
install -d -m 0700 -o "${service_user}" -g "${service_group}" /etc/xysat

printf -v quoted_install_dir '%q' "${install_dir}"
printf -v quoted_conductor_url '%q' "${CONDUCTORURL%/}"
printf -v quoted_api_key_file '%q' "${APIKEYFILE}"
printf -v quoted_service_user '%q' "${service_user}"
printf -v quoted_service_group '%q' "${service_group}"
cat >/usr/local/bin/xysat-fix-ownership <<EOF
#!/usr/bin/env bash
set -euo pipefail

install_dir=${quoted_install_dir}
service_user=${quoted_service_user}
service_group=${quoted_service_group}
service_uid="\$(id -u "\${service_user}")"

if [ "\$(stat -c %u "\${install_dir}")" != "\${service_uid}" ]; then
    chown -R "\${service_user}:\${service_group}" "\${install_dir}"
fi
chown -R "\${service_user}:\${service_group}" /etc/xysat
chmod 0700 /etc/xysat
EOF
chmod 0755 /usr/local/bin/xysat-fix-ownership

cat >/usr/local/bin/xysat-bootstrap <<EOF
#!/usr/bin/env bash
set -euo pipefail

config_file=/etc/xysat/config.json
conductor_url=${quoted_conductor_url}
api_key_file=${quoted_api_key_file}
service_user=${quoted_service_user}
service_group=${quoted_service_group}

if [ -s "\${config_file}" ]; then
    chown "\${service_user}:\${service_group}" "\${config_file}"
    chmod 0600 "\${config_file}"
    exit 0
fi

if [ -z "\${conductor_url}" ]; then
    echo "[xysat] No configuration exists. Configure conductorUrl or provide \${config_file}." >&2
    exit 1
fi
if [ ! -r "\${api_key_file}" ]; then
    echo "[xysat] Cannot read the API key file: \${api_key_file}" >&2
    exit 1
fi

normalized_key="\$(mktemp /run/xysat-api-key.XXXXXX)"
temporary_config="\$(mktemp /etc/xysat/config.json.XXXXXX)"
trap 'rm -f "\${normalized_key}" "\${temporary_config}"' EXIT
tr -d '\\r\\n' <"\${api_key_file}" >"\${normalized_key}"
chmod 0600 "\${normalized_key}"
[ -s "\${normalized_key}" ] || {
    echo "[xysat] The API key file is empty: \${api_key_file}" >&2
    exit 1
}

curl --fail --location --silent --show-error --retry 5 --retry-all-errors \\
    --get --data-urlencode "t@\${normalized_key}" \\
    --output "\${temporary_config}" \\
    "\${conductor_url}/api/app/satellite/config"
chown "\${service_user}:\${service_group}" "\${temporary_config}"
chmod 0600 "\${temporary_config}"
mv "\${temporary_config}" "\${config_file}"
rm -f "\${normalized_key}"
trap - EXIT
EOF
chmod 0755 /usr/local/bin/xysat-bootstrap

cat >/usr/local/bin/xysat-run <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

install_dir=/opt/xyops/satellite
config_file=/etc/xysat/config.json
[ -s "${config_file}" ] || {
    echo "[xysat] Configuration is missing: ${config_file}" >&2
    exit 1
}

cd "${install_dir}"
exec env \
    SATELLITE_foreground=1 \
    XYSAT_config_file="${config_file}" \
    "${install_dir}/bin/node" main.js --echo --foreground
EOF
chmod 0755 /usr/local/bin/xysat-run

service_dir=/etc/s6-overlay/s6-rc.d/xysat
install -d -m 0755 "${service_dir}/dependencies.d"
printf 'longrun\n' >"${service_dir}/type"
touch "${service_dir}/dependencies.d/base"
printf -v quoted_user '%q' "${service_user}"
printf -v quoted_home '%q' "${service_home}"
cat >"${service_dir}/run" <<EOF
#!/command/with-contenv bash
/usr/local/bin/xysat-fix-ownership
if ! /usr/local/bin/xysat-bootstrap; then
    sleep 5
    exit 1
fi
exec s6-setuidgid ${quoted_user} env HOME=${quoted_home} USER=${quoted_user} /usr/local/bin/xysat-run
EOF
chmod 0755 "${service_dir}/run"
touch /etc/s6-overlay/user-bundles.d/user/contents.d/xysat

rm -rf /var/lib/apt/lists/*
installed_version="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "${install_dir}/package.json" | head -n 1)"
log "Installed xySat ${installed_version:-unknown} as an s6 service running as ${service_user}."
