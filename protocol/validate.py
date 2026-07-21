from __future__ import annotations

import argparse
import json
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


ARCHITECTURE_EVIDENCE = (
    "architecture-summary.md",
    "state-model.md",
    "dependency-map.md",
    "persistence-plan.md",
    "test-strategy.md",
    "risk-register.md",
)

REQUIRED_APPROVAL_FIELDS = (
    "Milestone",
    "Reviewed commit",
    "Review date",
    "Reviewer",
    "Validator result",
    "Evidence reviewed",
    "Accepted variances",
    "Rejected variances",
    "Follow-up requirements",
    "Explicit approval statement",
)


@dataclass
class ValidationResult:
    errors: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.errors

    def extend(self, other: "ValidationResult") -> None:
        for error in other.errors:
            if error not in self.errors:
                self.errors.append(error)


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _commit_exists(root: Path, commit: str) -> bool:
    completed = subprocess.run(
        ["git", "cat-file", "-e", f"{commit}^{{commit}}"],
        cwd=root,
        capture_output=True,
        check=False,
        text=True,
    )
    return completed.returncode == 0


def _approval_fields(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    fields: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("- ") or ":" not in line:
            continue
        key, value = line[2:].split(":", 1)
        fields[key.strip()] = value.strip()
    return fields


def _validate_approval(root: Path, filename: str, label: str) -> ValidationResult:
    result = ValidationResult()
    fields = _approval_fields(root / "approvals" / filename)
    missing_fields = [field for field in REQUIRED_APPROVAL_FIELDS if not fields.get(field)]
    if fields.get("Explicit approval statement") != "APPROVED":
        result.errors.append(f"{label} approval is pending")
        return result
    if missing_fields:
        result.errors.append(f"{label} approval fields incomplete: {', '.join(missing_fields)}")
        return result
    reviewed_commit = fields["Reviewed commit"]
    if not _commit_exists(root, reviewed_commit):
        result.errors.append("reviewed commit does not exist")
    return result


def _load_requirements(root: Path, result: ValidationResult) -> list[dict[str, Any]]:
    path = root / "protocol/requirements.json"
    if not path.is_file():
        result.errors.append("missing requirement manifest")
        return []
    try:
        value = _load_json(path)
        if not isinstance(value, list):
            raise TypeError("root must be an array")
        requirements = [entry for entry in value if isinstance(entry, dict)]
        if len(requirements) != len(value):
            raise TypeError("every requirement must be an object")
    except (OSError, ValueError, TypeError) as error:
        result.errors.append(f"invalid requirement manifest: {error}")
        return []
    identifiers = [str(entry.get("id", "")) for entry in requirements]
    duplicates = sorted({identifier for identifier in identifiers if identifiers.count(identifier) > 1})
    if duplicates:
        result.errors.append("duplicate requirement id: " + ", ".join(duplicates))
    if any(not identifier for identifier in identifiers):
        result.errors.append("requirement id is missing")
    return requirements


def validate_architecture(root: Path) -> ValidationResult:
    result = ValidationResult()
    evidence_root = root / "reviews/architecture"
    missing = [name for name in ARCHITECTURE_EVIDENCE if not (evidence_root / name).is_file()]
    if missing:
        result.errors.append("missing architecture evidence: " + ", ".join(missing))

    requirements = _load_requirements(root, result)
    for entry in requirements:
        if entry.get("architecture_relevant") and (
            not entry.get("planned_implementation") or not entry.get("planned_tests")
        ):
            result.errors.append(f"architecture requirement lacks plan: {entry.get('id', '')}")

    result.extend(_validate_approval(root, "01-architecture-approved.md", "architecture"))
    return result


def validate_visuals(root: Path) -> ValidationResult:
    result = ValidationResult()
    manifest_path = root / "protocol/visual-references.json"
    if not manifest_path.is_file():
        result.errors.append("missing visual reference manifest")
        references: list[dict[str, Any]] = []
    else:
        try:
            value = _load_json(manifest_path)
            if not isinstance(value, list):
                raise TypeError("root must be an array")
            references = [entry for entry in value if isinstance(entry, dict)]
        except (OSError, ValueError, TypeError) as error:
            result.errors.append(f"invalid visual reference manifest: {error}")
            references = []

    for reference in references:
        review_directory = root / str(reference.get("review_directory", ""))
        screen_id = str(reference.get("id", "unknown"))
        for filename in ("approved-reference.png", "implementation.png", "comparison.md"):
            if not (review_directory / filename).is_file():
                result.errors.append(f"missing visual evidence for {screen_id}: {filename}")
        comparison = review_directory / "comparison.md"
        if comparison.is_file():
            text = comparison.read_text(encoding="utf-8")
            for field_name in ("Device", "Orientation", "Appearance", "App scale"):
                if f"- {field_name}:" not in text:
                    result.errors.append(f"visual comparison missing {field_name}: {screen_id}")
            if "V2" in text and "Blocking defect: None" not in text:
                result.errors.append(f"unresolved V2 variance: {screen_id}")

    icon = root / "docs/approved/Life_Grid_Selected_Icon_Reference.png"
    if not icon.is_file():
        result.errors.append("approved icon is missing")
    result.extend(_validate_approval(root, "02-visuals-approved.md", "visual"))
    return result


def validate_build(root: Path) -> ValidationResult:
    result = ValidationResult()
    requirements = _load_requirements(root, result)
    for entry in requirements:
        if entry.get("status") != "verified":
            result.errors.append(f"requirement is not verified: {entry.get('id', '')}")
    report = root / "reports/final-compliance-report.md"
    if not report.is_file():
        result.errors.append("missing final compliance report")
    test_results = root / "reports/test-results"
    if not test_results.is_dir() or not any(test_results.iterdir()):
        result.errors.append("missing test result evidence")
    result.extend(_validate_approval(root, "03-build-approved.md", "build"))
    return result


def validate_full(root: Path) -> ValidationResult:
    result = ValidationResult()
    result.extend(validate_architecture(root))
    result.extend(validate_visuals(root))
    result.extend(validate_build(root))
    if result.passed:
        report = root / "reports/final-compliance-report.md"
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(
            "# Final Compliance Report\n\n- Final validator status: PASS\n",
            encoding="utf-8",
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Life Grid approval gates")
    parser.add_argument("command", choices=("gate", "full"))
    parser.add_argument("gate_name", nargs="?", choices=("architecture", "visuals", "build"))
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()

    if args.command == "full":
        result = validate_full(args.root)
    elif args.gate_name == "architecture":
        result = validate_architecture(args.root)
    elif args.gate_name == "visuals":
        result = validate_visuals(args.root)
    elif args.gate_name == "build":
        result = validate_build(args.root)
    else:
        parser.error("gate requires architecture, visuals, or build")

    for error in result.errors:
        print(f"FAIL: {error}")
    if result.passed:
        print("PASS")
    return 0 if result.passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
