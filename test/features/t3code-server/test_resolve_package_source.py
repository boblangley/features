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
        source = "github:sample-owner/sample-repository/../../unexpected"
        with self.assertRaisesRegex(ValueError, "github:<owner>/<repository>"):
            resolver.resolve(source, "latest")

    def test_tag_discovery_is_anonymous_and_paginates(self):
        first = [{"ref": f"refs/tags/server/1.0.0-wyrd.{number}"} for number in range(1, 101)]
        second = [{"ref": "refs/tags/server/1.0.0-wyrd.101"}]
        with mock.patch.object(resolver.urllib.request, "urlopen", side_effect=[Response(first), Response(second)]) as opened:
            refs = resolver.fetch_refs("sample-owner", "sample-repository")
        self.assertEqual(len(refs), 101)
        self.assertNotIn("Authorization", opened.call_args_list[0].args[0].headers)
        self.assertEqual(opened.call_args_list[0].kwargs["timeout"], 30)
        self.assertIn("page=2", opened.call_args_list[1].args[0].full_url)


if __name__ == "__main__":
    unittest.main()
