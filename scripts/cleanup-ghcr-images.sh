#!/usr/bin/env bash

set -euo pipefail

owner="${GHCR_OWNER:-wyrd-company}"
package="${GHCR_PACKAGE:-devcontainers/base}"
encoded_package="${package//\//%2F}"
keep="${GHCR_KEEP_BUILDS:-12}"
execute="false"

if [ "${1:-}" = "--execute" ]; then
    execute="true"
fi

versions_json="$(gh api --paginate --slurp \
    -H 'Accept: application/vnd.github+json' \
    "/users/${owner}/packages/container/${encoded_package}/versions?per_page=100" | jq 'add')"

for variant in noble resolute; do
    candidates="$(printf '%s' "${versions_json}" | jq --arg variant "${variant}" '
        [ .[]
          | . as $version
          | (.metadata.container.tags // []) as $tags
          | select(any($tags[]?; test("^[0-9]{8}\\.[0-9]+-" + $variant + "$")))
          | select(all($tags[]?; . != "noble" and . != "ubuntu24.04" and . != "resolute" and . != "ubuntu26.04"))
          | { id, created_at, tags: $tags }
        ]
        | sort_by(.created_at)
        | reverse
    ')"

    printf '%s' "${candidates}" | jq -r --argjson keep "${keep}" '
        to_entries[] | if (.key < $keep) then
          "KEEP \(.value.id) \(.value.created_at) \(.value.tags | join(","))"
        else
          "DELETE \(.value.id) \(.value.created_at) \(.value.tags | join(","))"
        end
    '

    mapfile -t delete_ids < <(printf '%s' "${candidates}" | jq -r --argjson keep "${keep}" '.[ $keep: ][].id')
    for id in "${delete_ids[@]}"; do
        if [ "${execute}" = "true" ]; then
            gh api --method DELETE \
                -H 'Accept: application/vnd.github+json' \
                "/users/${owner}/packages/container/${encoded_package}/versions/${id}"
        fi
    done
done

if [ "${execute}" != "true" ]; then
    echo "Dry run only. Pass --execute to delete the listed versions."
fi
