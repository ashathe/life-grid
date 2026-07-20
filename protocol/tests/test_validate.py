import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from protocol.validate import validate_architecture, validate_build, validate_full, validate_visuals


ARCHITECTURE_FILES = (
    "architecture-summary.md",
    "state-model.md",
    "dependency-map.md",
    "persistence-plan.md",
    "test-strategy.md",
    "risk-register.md",
)


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def initialize_git_repository(root: Path) -> str:
    subprocess.run(["git", "init", "-q", "-b", "main"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "Validator Test"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "validator@example.invalid"], cwd=root, check=True)
    (root / "tracked.txt").write_text("reviewed\n", encoding="utf-8")
    subprocess.run(["git", "add", "tracked.txt"], cwd=root, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "fixture"], cwd=root, check=True)
    return subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def create_architecture_fixture(root: Path, *, approved: bool) -> str:
    commit = initialize_git_repository(root)
    evidence = root / "reviews/architecture"
    evidence.mkdir(parents=True)
    for filename in ARCHITECTURE_FILES:
        (evidence / filename).write_text("# Evidence\n\nNo blockers.\n", encoding="utf-8")
    write_json(
        root / "protocol/requirements.json",
        [
            {
                "id": "PST-001",
                "title": "Versioned snapshot",
                "spec_section": "5",
                "visual_references": [],
                "implementation_files": ["LifeGrid/Models/PersistedAppState.swift"],
                "test_files": ["LifeGridTests/Models/PersistedAppStateTests.swift"],
                "evidence_files": ["reviews/architecture/state-model.md"],
                "status": "implemented",
                "architecture_relevant": True,
                "planned_implementation": ["LifeGrid/Models/PersistedAppState.swift"],
                "planned_tests": ["LifeGridTests/Models/PersistedAppStateTests.swift"],
                "approved_variance": None,
                "change_request": None,
            }
        ],
    )
    approval = "\n".join(
        (
            "# Milestone Approval",
            "",
            "- Milestone: Architecture Gate 1",
            f"- Reviewed commit: {commit}",
            "- Review date: 2026-07-20",
            "- Reviewer: Test Reviewer",
            "- Validator result: Pre-approval validation complete",
            "- Evidence reviewed: reviews/architecture",
            "- Accepted variances: None",
            "- Rejected variances: None",
            "- Follow-up requirements: None",
            f"- Explicit approval statement: {'APPROVED' if approved else ''}",
            "",
        )
    )
    approval_path = root / "approvals/01-architecture-approved.md"
    approval_path.parent.mkdir(parents=True)
    approval_path.write_text(approval, encoding="utf-8")
    return commit


class ArchitectureValidationTests(unittest.TestCase):
    def test_missing_required_architecture_evidence_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = validate_architecture(Path(directory))
        self.assertFalse(result.passed)
        self.assertIn("missing architecture evidence", "\n".join(result.errors))

    def test_duplicate_requirement_ids_fail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            create_architecture_fixture(root, approved=True)
            requirements_path = root / "protocol/requirements.json"
            requirements = json.loads(requirements_path.read_text(encoding="utf-8"))
            requirements.append(requirements[0])
            write_json(requirements_path, requirements)
            result = validate_architecture(root)
        self.assertFalse(result.passed)
        self.assertIn("duplicate requirement id: PST-001", result.errors)

    def test_pending_approval_is_the_only_preapproval_blocker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            create_architecture_fixture(root, approved=False)
            result = validate_architecture(root)
        self.assertEqual(result.errors, ["architecture approval is pending"])

    def test_complete_architecture_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            create_architecture_fixture(root, approved=True)
            result = validate_architecture(root)
        self.assertTrue(result.passed, result.errors)


class LaterGateValidationTests(unittest.TestCase):
    def test_visual_gate_cannot_pass_without_visual_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = validate_visuals(Path(directory))
        self.assertFalse(result.passed)
        self.assertIn("missing visual reference manifest", result.errors)

    def test_build_gate_cannot_pass_without_build_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = validate_build(Path(directory))
        self.assertFalse(result.passed)
        self.assertIn("missing final compliance report", result.errors)

    def test_full_validation_does_not_write_success_report_when_gates_fail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = validate_full(root)
            report = root / "reports/final-compliance-report.md"
        self.assertFalse(result.passed)
        self.assertFalse(report.exists())


if __name__ == "__main__":
    unittest.main()
