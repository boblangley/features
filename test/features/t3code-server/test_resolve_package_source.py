#!/usr/bin/env python3

import importlib.util
import json
import pathlib
import unittest
from unittest import mock


SCRIPT = pathlib.Path(__file__).parents[3] / "src/features/t3code-server/resolve-package-source.py"
SPEC = importlib.util.spec_from_file_location("resolve_package_source", SCRIPT)
resolver = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(resolver)


class Response:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return json.dumps(self.payload).encode()


class ResolverTests(unittest.TestCase):
    def test_empty_source_preserves_default_npm_spec(self):
        self.assertEqual(resolver.resolve("", "latest"), ("t3@latest", ""))

    def test_explicit_default_npm_version_is_verified(self):
        self.assertEqual(resolver.resolve("", "1.2.3"), ("t3@1.2.3", "1.2.3"))

    def test_default_npm_ranges_and_dist_tags_remain_supported(self):
        for version in ("^1.2.3", "1.2", "next", "latest"):
            with self.subTest(version=version):
                self.assertEqual(resolver.resolve("", version), (f"t3@{version}", ""))

    def test_explicit_npm_spec_and_url_remain_unchanged(self):
        for source in ("example-package@1.2.3", "https://packages.example.test/tool.tgz"):
            with self.subTest(source=source):
                self.assertEqual(resolver.resolve(source, "latest"), (source, ""))

    def test_explicit_github_version_derives_tag_and_asset_url_without_discovery(self):
        with mock.patch.object(resolver, "fetch_refs") as fetch:
            self.assertEqual(
                resolver.resolve("github:sample-owner/sample-repository", "1.2.3-wyrd.4"),
                (
                    "https://github.com/sample-owner/sample-repository/releases/download/server/1.2.3-wyrd.4/t3-1.2.3-wyrd.4.tgz",
                    "1.2.3-wyrd.4",
                ),
            )
            fetch.assert_not_called()

    def test_latest_uses_semver_precedence_not_lexical_order(self):
        refs = [
            "refs/tags/server/1.9.0-wyrd.20",
            "refs/tags/server/1.10.0-wyrd.2",
            "refs/tags/server/1.10.0-wyrd.11",
        ]
        with mock.patch.object(resolver, "fetch_refs", return_value=refs):
            source, version = resolver.resolve("github:sample-owner/sample-repository", "latest")
        self.assertEqual(version, "1.10.0-wyrd.11")
        self.assertTrue(source.endswith("/server/1.10.0-wyrd.11/t3-1.10.0-wyrd.11.tgz"))

    def test_latest_rejects_unrelated_malformed_and_other_prerelease_tags(self):
        refs = [
            "refs/tags/v99.0.0",
            "refs/tags/web/99.0.0-wyrd.1",
            "refs/tags/server/99.0.0-alpha.1",
            "refs/tags/server/99.0.0-wyrd.01",
            "refs/tags/server/2.0.0-wyrd.3",
        ]
        self.assertEqual(resolver.select_latest(refs), "2.0.0-wyrd.3")

    def test_latest_fails_when_no_stable_fork_tag_exists(self):
        with self.assertRaisesRegex(ValueError, "No stable fork releases"):
            resolver.select_latest(["refs/tags/server/3.0.0-alpha.1"])

    def test_github_repository_identity_is_validated(self):
        invalid_sources = (
            "github:../sample-repository",
            "github:-sample-owner/sample-repository",
            "github:.sample-owner/sample-repository",
            "github:sample-owner/sample-repository/../../unexpected",
            "github:sample-owner/.",
            "github:sample-owner/..",
            "github:sample-owner/-sample-repository",
            "github:sample-owner/.sample-repository",
        )
        for source in invalid_sources:
            with self.subTest(source=source), self.assertRaisesRegex(ValueError, "github:<owner>/<repository>"):
                resolver.resolve(source, "1.2.3")

    def test_explicit_github_version_must_be_semver(self):
        for version in ("../../../unexpected/path", "1.2", "next"):
            with self.subTest(version=version), self.assertRaisesRegex(ValueError, "not valid SemVer"):
                resolver.resolve("github:sample-owner/sample-repository", version)

    def test_tag_discovery_uses_one_anonymous_matching_refs_request(self):
        payload = [{"ref": f"refs/tags/server/1.0.0-wyrd.{number}"} for number in range(1, 102)]
        with mock.patch.object(resolver.urllib.request, "urlopen", return_value=Response(payload)) as opened:
            refs = resolver.fetch_refs("sample-owner", "sample-repository")
        self.assertEqual(len(refs), 101)
        opened.assert_called_once()
        request = opened.call_args.args[0]
        self.assertEqual(
            request.full_url,
            "https://api.github.com/repos/sample-owner/sample-repository/git/matching-refs/tags/server/",
        )
        self.assertEqual(resolver.urllib.parse.urlsplit(request.full_url).query, "")
        self.assertNotIn("Authorization", request.headers)
        self.assertEqual(opened.call_args.kwargs["timeout"], 30)

    def test_tag_discovery_rejects_non_list_response(self):
        with mock.patch.object(resolver.urllib.request, "urlopen", return_value=Response({"tag_name": "unrelated"})):
            with self.assertRaisesRegex(ValueError, "invalid tag response"):
                resolver.fetch_refs("sample-owner", "sample-repository")


if __name__ == "__main__":
    unittest.main()
