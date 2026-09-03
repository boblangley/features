#!/usr/bin/env python3

import json
import pathlib
import unittest


ROOT = pathlib.Path(__file__).parents[3]
FEATURE = ROOT / "src/features/t3code-server"
TEST = ROOT / "test/features/t3code-server"


class SourceContractTests(unittest.TestCase):
    def test_metadata_documents_github_source_and_semver_latest(self):
        metadata = json.loads((FEATURE / "devcontainer-feature.json").read_text())
        self.assertIn("github:wyrd-company/t3code", metadata["options"]["packageSource"]["description"])
        self.assertIn("SemVer precedence", metadata["options"]["version"]["description"])

    def test_fork_scenario_and_assertion_agree_on_explicit_version(self):
        scenarios = json.loads((TEST / "scenarios.json").read_text())
        options = scenarios["t3code-server-fork-package-source"]["features"]["t3code-server"]
        assertion = (TEST / "t3code-server-fork-package-source.sh").read_text()
        self.assertEqual(options["packageSource"], "github:wyrd-company/t3code")
        self.assertIn(f't3 v{options["version"]}', assertion)

    def test_installer_checks_resolved_version_after_global_install(self):
        installer = (FEATURE / "install.sh").read_text()
        self.assertIn('npm install --global --prefix /usr/local "${package_spec}"', installer)
        self.assertIn('[ "${installed_version}" = "t3 v${resolved_version}" ]', installer)

    def test_readme_documents_explicit_and_latest_github_examples(self):
        readme = (FEATURE / "README.md").read_text()
        self.assertGreaterEqual(readme.count('"packageSource": "github:wyrd-company/t3code"'), 2)
        self.assertIn('"version": "0.0.37-wyrd.1"', readme)
        self.assertIn('"version": "latest"', readme)


if __name__ == "__main__":
    unittest.main()
