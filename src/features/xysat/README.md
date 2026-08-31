# xySat Worker

Installs the official xyOps xySat release and supervises it as an s6-overlay longrun service. The Feature requires a Debian/Ubuntu image with s6-overlay 3 and supports `x64` and `arm64`.

xySat runs as the selected devcontainer user so that jobs receive that user's home directory, permissions, Git configuration, SSH credentials, and development tools. Automatic selection prefers the remote user, container user, `vscode`, then `root`.

The Feature does not add access to the host Docker socket. Add that access separately and grant the selected service user permission when xySat jobs require it.

## Automatic registration

xySat stores its generated worker identity and conductor configuration at `/etc/xysat/config.json`. A named volume preserves this file across devcontainer rebuilds.

Create a dedicated xyOps API key with only the `add_servers` privilege. Store the key in a file outside the repository and mount it read-only at `/run/secrets/xyops-api-key`.

Configure the non-secret conductor URL on the Feature:

```json
{
  "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
  "overrideCommand": false,
  "mounts": [
    "source=${localEnv:XYOPS_API_KEY_FILE},target=/run/secrets/xyops-api-key,type=bind,readonly"
  ],
  "features": {
    "ghcr.io/wyrd-company/devcontainers/xysat:1": {
      "conductorUrl": "http://conductor:5522"
    }
  }
}
```

Set `XYOPS_API_KEY_FILE` on the host to the absolute path of the API key file before creating the devcontainer. When the container starts without an existing configuration, the root bootstrap step reads the mounted key, calls the conductor's `/api/app/satellite/config` endpoint, writes the generated configuration for the service user, and deletes its temporary key copy. The API key is not placed in an environment variable, Feature option, command argument, image layer, or generated xySat configuration.

Registration is skipped whenever `/etc/xysat/config.json` exists. The mounted API key can remain available for future container identities, but xySat does not read it after registration.

The conductor hostname must resolve and be reachable from inside the devcontainer. When the conductor runs in another Compose service, attach both containers to a shared network and use the conductor service name.

## Options

| Option         | Type   | Default                      | Description                                                              |
| -------------- | ------ | ---------------------------- | ------------------------------------------------------------------------ |
| `version`      | string | `latest`                     | xySat release version, with or without the upstream `v` prefix.          |
| `serviceUser`  | string | `automatic`                  | User that runs xySat and its jobs. Automatic selection prefers `vscode`. |
| `conductorUrl` | string | `""`                         | Base URL used to register with the conductor on first start.             |
| `apiKeyFile`   | string | `/run/secrets/xyops-api-key` | Runtime-mounted API key file used for automatic registration.            |

## Well-known locations

| Purpose            | Location                         |
| ------------------ | -------------------------------- |
| xySat installation | `/opt/xyops/satellite`           |
| Persistent config  | `/etc/xysat/config.json`         |
| Default API key    | `/run/secrets/xyops-api-key`     |
| Bootstrap command  | `/usr/local/bin/xysat-bootstrap` |
| Service launcher   | `/usr/local/bin/xysat-run`       |
| s6 service         | `/etc/s6-overlay/s6-rc.d/xysat`  |
