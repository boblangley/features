#!/usr/bin/env python3

import json
import re
import sys
import urllib.parse
import urllib.request


GITHUB_SOURCE = re.compile(r"^github:([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/([A-Za-z0-9_.-]+)$")
SEMVER = re.compile(
    r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-((?:0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9A-Za-z-][0-9A-Za-z-]*))*))?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)
FORK_VERSION = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-wyrd\.(0|[1-9][0-9]*)$")


def fork_version_key(version):
    match = FORK_VERSION.fullmatch(version)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


def select_latest(refs):
    candidates = []
    for ref in refs:
        prefix = "refs/tags/server/"
        if not ref.startswith(prefix):
            continue
        version = ref[len(prefix) :]
        key = fork_version_key(version)
        if key is not None:
            candidates.append((key, version))
    if not candidates:
        raise ValueError("No stable fork releases exist in the server/*-wyrd.* tag namespace.")
    return max(candidates)[1]


def fetch_refs(owner, repository, api_base="https://api.github.com"):
    refs = []
    page = 1
    while True:
        path = f"/repos/{owner}/{repository}/git/matching-refs/tags/server/"
        url = f"{api_base.rstrip('/')}{path}?per_page=100&page={page}"
        request = urllib.request.Request(
            url,
            headers={"Accept": "application/vnd.github+json", "User-Agent": "t3code-server-feature"},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
        if not isinstance(payload, list):
            raise ValueError("GitHub returned an invalid tag response.")
        page_refs = [item.get("ref", "") for item in payload if isinstance(item, dict)]
        refs.extend(page_refs)
        if len(payload) < 100:
            return refs
        page += 1


def resolve(package_source, version, api_base="https://api.github.com", web_base="https://github.com"):
    match = GITHUB_SOURCE.fullmatch(package_source)
    if not match:
        if package_source.startswith("github:"):
            raise ValueError("GitHub package source must have the form github:<owner>/<repository>.")
        return package_source or f"t3@{version}", ""

    owner, repository = match.groups()
    resolved_version = select_latest(fetch_refs(owner, repository, api_base)) if version.lower() == "latest" else version
    if not SEMVER.fullmatch(resolved_version):
        raise ValueError(f"GitHub package version is not valid SemVer: {resolved_version!r}.")
    tag = urllib.parse.quote(f"server/{resolved_version}", safe="/")
    asset = urllib.parse.quote(f"t3-{resolved_version}.tgz", safe="")
    source = f"{web_base.rstrip('/')}/{owner}/{repository}/releases/download/{tag}/{asset}"
    return source, resolved_version


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: resolve-package-source.py PACKAGE_SOURCE VERSION")
    try:
        source, resolved_version = resolve(sys.argv[1], sys.argv[2])
    except (ValueError, OSError) as error:
        raise SystemExit(f"ERROR: {error}") from error
    print(source)
    print(resolved_version)


if __name__ == "__main__":
    main()
