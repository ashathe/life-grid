# Life Grid Codex Design-Control Protocol

**Status:** Approved  
**Applies to:** Life Grid  
**Primary agent:** Codex  
**Purpose:** Prevent design drift, unapproved feature changes, silent requirement reinterpretation, and unsupported claims of completion.

---

## 1. Protocol objective

Codex must implement Life Grid according to the approved product specification, approved visual layouts, approved feature decisions, and approved change-control process.

This protocol is not advisory. It is a required operating procedure for all architecture, design, implementation, testing, review, and completion work on Life Grid.

Codex must not:

- Replace approved layouts with its own preferred layout.
- Add features because they are common in similar apps.
- Remove or simplify approved behavior without permission.
- Resolve meaningful contradictions silently.
- Mark work complete without evidence.
- Continue past an approval gate without explicit approval.
- Rewrite prior approvals to make later work appear compliant.

When this protocol and an informal implementation preference conflict, this protocol controls.

---

## 2. Authoritative source hierarchy

Codex must interpret project instructions in this order:

1. **Later explicit user corrections and approved change requests**
2. **`Life_Grid_Product_Spec.md`** for features, rules, data behavior, edge cases, persistence, accessibility, and acceptance criteria
3. **Approved visual layouts and `Life_Grid_Approved_Designs.pdf`** for visual structure, hierarchy, placement, density, spacing direction, color intent, and component appearance
4. **`Life_Grid_Codex_Implementation_Prompt.md`** for implementation order and delivery expectations
5. **Native SwiftUI conventions** only where the approved materials are silent

The following additional rules apply:

- A later explicit correction overrides an earlier decision.
- Written behavior in the product specification controls behavior.
- Approved visual references control layout and visual placement.
- The implementation prompt controls workflow, not product behavior.
- Codex may use a native SwiftUI equivalent for harmless rendering details.
- Codex must document every visible deviation from an approved reference.
- Codex must not silently choose one source when a meaningful conflict affects layout, navigation, wording, features, or behavior.

---

## 3. Ambiguity rule

Codex must classify ambiguity before continuing.

### 3.1 Minor implementation ambiguity

Codex may use the closest approved pattern and continue when the decision:

- Does not alter layout hierarchy.
- Does not add or remove a feature.
- Does not change navigation.
- Does not change user-facing wording with product meaning.
- Does not change persistence or game behavior.
- Does not conflict with an approved visual.
- Is a normal native-platform rendering or engineering detail.

Codex must record the assumption in the relevant implementation or variance report.

### 3.2 Product-affecting ambiguity

Codex must stop and request approval when the ambiguity could affect:

- Layout or placement.
- Navigation.
- Feature scope.
- User-visible behavior.
- User-facing terminology.
- State transitions.
- Persistence.
- Reset or preservation rules.
- Accessibility behavior.
- Approved visual identity.
- The app icon.
- Any acceptance criterion.

Codex may not continue by guessing.

---

## 4. Required workspace structure

The project repository must contain the following control files and directories:

```text
AGENTS.md
PROTOCOL.md

protocol/
  requirements.json
  visual-references.json
  validate.py
  schemas/
    requirements.schema.json
    visual-references.schema.json
    approval.schema.json
    variance.schema.json
    change-request.schema.json

approvals/
  01-architecture-approved.md
  02-visuals-approved.md
  03-build-approved.md
  templates/
    APPROVAL_TEMPLATE.md

changes/
  TEMPLATE.md

reviews/
  visuals/

backlog/
  SUGGESTED_IMPROVEMENTS.md

reports/
  COMPLIANCE_REPORT_TEMPLATE.md
  test-results/
```

The repository may contain additional files, but these protocol files must not be removed without an approved change request.

---

## 5. `AGENTS.md` enforcement rules

The root `AGENTS.md` must instruct Codex to:

1. Read this protocol before modifying the project.
2. Read the product specification completely before implementing features.
3. Inspect the approved layout for every screen being changed.
4. Declare the requirement IDs involved before beginning work.
5. Declare the files expected to change.
6. Declare the tests and visual evidence required.
7. Respect the current approval gate.
8. Stop when a product-affecting ambiguity is found.
9. Put unapproved improvement ideas in the backlog.
10. Run the validator before claiming a milestone complete.
11. Report evidence instead of merely stating that work is finished.
12. Never modify approval records retroactively.
13. Never redesign the approved Life Grid icon.

---

## 6. Three hard approval gates

Codex must use three milestone gates.

Codex cannot proceed to the next gate until:

- Required evidence exists.
- The local protocol validator passes for the gate.
- The user has given explicit approval.
- The approval file records that approval.

### Gate 1 — Architecture approval

Scope:

- Domain models.
- Application-state model.
- Persistence design.
- State migrations.
- Dependency injection.
- Feature boundaries.
- Error handling.
- Test strategy.
- Responsive-layout strategy.
- Accessibility strategy.

Required evidence:

```text
reviews/architecture/
  architecture-summary.md
  state-model.md
  dependency-map.md
  persistence-plan.md
  test-strategy.md
  risk-register.md
```

Approval record:

```text
approvals/01-architecture-approved.md
```

Codex must not begin full feature implementation before this gate is approved. Small compile-only scaffolding and test harness setup may exist solely to validate the architecture, but no screen may be treated as final.

### Gate 2 — Visual approval

Scope:

- Every major approved screen implemented with representative mock data.
- iPhone portrait layout.
- iPhone landscape layout.
- iPad adaptive layout.
- Dark, Light, and System appearances.
- Compact, Balanced, and Large app scales.
- Approved status badges.
- Approved lethal warning treatment.
- Approved app icon.

Required screen reviews include:

- New Game.
- Game on iPhone.
- Game on iPad.
- Counters.
- Pin picker and pin editing.
- Dice and custom dice.
- Random-player tools.
- Settings.
- Player menus and statuses.
- Monarch transfer.
- Out of Game.
- Quick Restart.
- App icon.

Approval record:

```text
approvals/02-visuals-approved.md
```

Codex must not treat the visual system as approved until every required screen has comparison evidence and all blocking variances are resolved or explicitly accepted.

### Gate 3 — Functional build approval

Scope:

- Features connected to real state.
- Persistence and auto-resume.
- Reset and preservation rules.
- Commander behavior.
- Counters.
- Dice.
- Player statuses.
- Accessibility.
- Responsive layout.
- Automated tests.
- Final visual verification.
- Final compliance report.

Approval record:

```text
approvals/03-build-approved.md
```

Codex must not declare Life Grid complete before this gate is approved.

---

## 7. Approval-file requirements

Approval files are hard gates.

Each approval file must include:

```markdown
# Milestone Approval

- Milestone:
- Reviewed commit:
- Review date:
- Reviewer:
- Validator result:
- Evidence reviewed:
- Accepted variances:
- Rejected variances:
- Follow-up requirements:
- Explicit approval statement:
```

The explicit approval statement must be an affirmative user decision. An empty template, inferred approval, or Codex-authored statement does not count.

Approval records are immutable historical records after acceptance.

Later changes must not edit old approvals. They must use the change-request process.

---

## 8. Requirement traceability

Every testable Life Grid requirement must have a stable requirement ID.

Recommended prefixes:

```text
APP   App identity and global behavior
NAV   Navigation
NEW   New Game
LIFE  Local life controls
CMD   Commander behavior
OPP   Opponent behavior
STS   Player statuses
CTR   Counters and pins
CST   Custom counters
WARN  Lethal warnings
DICE  Dice and randomizers
SET   Settings
RST   Reset and restart
PST   Persistence and auto-resume
VIS   Visual design
A11Y  Accessibility
TEST  Verification requirements
```

Examples:

```text
NAV-001   Use Game, Counters, Dice, and Settings tabs
LIFE-004  Permit negative life totals
CMD-009   Apply commander-damage changes to life by delta
CTR-012   Permit no more than four pinned counters
DICE-008  Retain the last five complete dice-roll entries
VIS-006   Use Balanced as the default app scale
```

The traceability record for each requirement must include:

- Requirement ID.
- Requirement title.
- Specification section.
- Approved design reference, when applicable.
- Implementation files.
- Test files.
- Evidence files.
- Current status.
- Approved variance, when applicable.
- Change request, when applicable.

A requirement cannot be marked complete without implementation and verification evidence.

---

## 9. Visual-fidelity workflow

Every approved screen must have a visual-review directory:

```text
reviews/visuals/<screen-id>/
  approved-reference.png
  implementation.png
  comparison.md
```

Use additional images where needed:

```text
implementation-dark.png
implementation-light.png
implementation-compact.png
implementation-balanced.png
implementation-large.png
implementation-ipad.png
```

### 9.1 Required `comparison.md` content

Each comparison must state:

```markdown
# Visual Comparison

- Screen:
- Requirement IDs:
- Approved reference:
- Implementation commit:
- Device:
- Orientation:
- Appearance:
- App scale:
- Dynamic Type setting:
- Reduce Motion setting:

## Matching elements

## Visible differences

## Reason for each difference

## Classification

- Harmless native rendering:
- Requires approval:
- Blocking defect:

## Resolution

## Reviewer decision
```

### 9.2 Visual completion rule

Codex may not call a screen visually complete when:

- A meaningful variance remains undocumented.
- A blocking variance remains unresolved.
- A required device or orientation is missing.
- The implementation is compared against the wrong approved layout.
- The screenshot uses placeholder UI that does not represent the actual implementation.
- The approved app scale or appearance is not stated.
- Text contrast or touch-target problems remain.

### 9.3 Visual tolerance

Pixel-perfect identity is not required where SwiftUI, font rendering, safe areas, or device geometry cause harmless differences.

However, Codex must preserve:

- Information hierarchy.
- Control placement.
- Relative emphasis.
- Layout direction.
- Approved interaction model.
- Color role.
- Status and warning visibility.
- App-scale intent.
- Responsive behavior.

---

## 10. Variance classification

Every variance must be assigned one category.

### V0 — Native rendering difference

Examples:

- Minor font rasterization.
- Standard SwiftUI control geometry.
- Safe-area adjustment.
- A few points of spacing needed for a supported device.

Action:

- Record it.
- Continue if it does not affect the approved design intent.

### V1 — Minor design variance

Examples:

- Slight spacing change.
- Small text wrapping difference.
- Native control substitution that preserves behavior and hierarchy.

Action:

- Record it.
- Include it in the visual review.
- User approval is required at the visual gate when the difference is visible and intentional.

### V2 — Product-affecting variance

Examples:

- Moving Add Opponent.
- Changing tab structure.
- Removing a status badge.
- Changing a reset rule.
- Altering an interaction.
- Adding an unapproved control.
- Changing the app icon.

Action:

- Stop.
- Create or request a change request.
- Do not implement without explicit approval.

---

## 11. Change-control process

Approved milestones are immutable.

All later product changes must use numbered change requests:

```text
changes/
  CR-001-<description>.md
  CR-002-<description>.md
```

### 11.1 Required change-request content

```markdown
# CR-### — Change title

- Status:
- Requested by:
- Request date:
- Approval date:
- Approved by:
- Implementation commit:

## Requested change

## Reason

## Affected requirement IDs

## Affected specification sections

## Affected approved layouts

## Before evidence

## Proposed after state

## Risks and side effects

## Test impact

## Documentation updates

## Explicit approval statement

## Completion evidence
```

### 11.2 Change-request rules

- Codex may draft a change request.
- Codex may not approve its own change request.
- The original approval files remain unchanged.
- The affected specification, layouts, requirements, and tests must be updated after approval.
- The change request must identify the implementing commit.
- The validator must fail when implemented behavior references an unapproved change request.
- Cosmetic fixes that correct implementation drift back toward the approved design do not require a change request.
- Any intentional change to the approved product does require one.

---

## 12. Feature-creep rule

Codex must not add unapproved features.

Potential improvements belong in:

```text
backlog/SUGGESTED_IMPROVEMENTS.md
```

Each suggestion may contain:

```markdown
## Suggestion title

- Problem or opportunity:
- Proposed improvement:
- Benefit:
- Cost:
- Risk:
- Requirements affected:
- Design areas affected:
- Recommendation:
```

A suggestion remains outside the build until it becomes an approved change request.

Examples of prohibited silent additions:

- Opponent life totals.
- Initiative.
- Cloud sync.
- Accounts.
- Analytics.
- Additional tabs.
- New game modes.
- Different icon artwork.
- Extra counters not approved in the specification.

---

## 13. Task-start declaration

Before starting any implementation task, Codex must state:

```markdown
## Task Declaration

- Objective:
- Requirement IDs:
- Approved layouts:
- Current approval gate:
- Files expected to change:
- Tests required:
- Visual evidence required:
- Known ambiguity:
- Approval needed before work:
```

Codex must not begin when the declaration reveals an unresolved product-affecting ambiguity.

---

## 14. Task-completion evidence

At task completion, Codex must provide:

```markdown
## Completion Evidence

- Requirement IDs completed:
- Files changed:
- Tests added or updated:
- Test commands:
- Test results:
- Visual evidence:
- Variances:
- Validator command:
- Validator result:
- Remaining limitations:
- Approval required:
```

Statements such as “done,” “fixed,” or “matches the design” are insufficient without evidence.

---

## 15. Python validation system

Use a Python validator with structured JSON manifests.

Recommended commands:

```bash
python3 protocol/validate.py gate architecture
python3 protocol/validate.py gate visuals
python3 protocol/validate.py gate build
python3 protocol/validate.py full
```

A failed validator returns a nonzero exit status.

Codex must not claim a milestone complete when the relevant validator command fails.

### 15.1 Architecture-gate checks

The validator must check:

- Required architecture evidence exists.
- Requirement manifest parses.
- No duplicate requirement IDs exist.
- Every architecture requirement has a planned implementation and test strategy.
- The architecture approval file is complete.
- The recorded reviewed commit exists.
- No unresolved architecture blocker remains.

### 15.2 Visual-gate checks

The validator must check:

- Every required visual reference is registered.
- Every required screen has an implementation screenshot.
- Every required screen has a comparison report.
- Every comparison states device, orientation, appearance, and app scale.
- No unresolved V2 variance exists.
- Every intentional V1 variance has a reviewer decision.
- The approved icon is present.
- The visual approval file is complete.

### 15.3 Build-gate checks

The validator must check:

- Every required requirement has implementation evidence.
- Every testable requirement has test evidence.
- Required test-result files exist.
- Required persistence and restoration evidence exists.
- Required accessibility evidence exists.
- Required visual reviews are current for the reviewed commit.
- No unapproved change request is implemented.
- No blocking variance remains.
- The final compliance report exists.
- The build approval file is complete.

### 15.4 Full validation

`python3 protocol/validate.py full` must run all gate checks and produce:

```text
reports/final-compliance-report.md
```

The report must include:

- Requirement totals.
- Complete requirements.
- Incomplete requirements.
- Approved variances.
- Unresolved variances.
- Approved change requests.
- Test summary.
- Visual review summary.
- Accessibility summary.
- Persistence summary.
- Final validator status.

---

## 16. Structured manifest expectations

### 16.1 `requirements.json`

Each entry should resemble:

```json
{
  "id": "LIFE-004",
  "title": "Permit negative life totals",
  "spec_section": "10.2",
  "visual_references": ["02_Game_iPhone.png"],
  "implementation_files": [],
  "test_files": [],
  "evidence_files": [],
  "status": "not_started",
  "approved_variance": null,
  "change_request": null
}
```

Allowed statuses:

```text
not_started
in_progress
implemented
verified
blocked
deferred_by_approval
```

Only `verified` counts as complete.

### 16.2 `visual-references.json`

Each entry should include:

- Stable screen ID.
- Approved source path.
- Required devices.
- Required orientations.
- Required appearances.
- Required app scales.
- Related requirement IDs.
- Review directory.
- Current approval status.

---

## 17. Test evidence

Codex must save machine-readable or plain-text test output under:

```text
reports/test-results/
```

Required categories include:

- Model tests.
- Persistence tests.
- State-transition tests.
- Dice and randomness tests.
- Reset and preservation tests.
- Accessibility checks.
- UI tests.
- Relaunch or restoration tests.

Test evidence must identify:

- Command.
- Date.
- Commit.
- Environment.
- Result.
- Failing tests, when any.

A test mentioned only in prose does not count as evidence.

---

## 18. Completion definition

Life Grid is complete only when:

- All required acceptance criteria are verified.
- All three approval gates are approved.
- The full validator passes.
- No blocking variance remains.
- No unapproved feature exists.
- The approved app icon is used without redesign.
- Required screenshots and comparison reports exist.
- Persistence and forced-relaunch restoration are verified.
- Tests pass.
- Accessibility evidence exists.
- The final compliance report is generated.
- The user explicitly approves the build.

Codex must report remaining limitations honestly.

---

## 19. Required protocol package additions

The Life Grid handoff must include:

```text
Life_Grid_Codex_Design_Control_Protocol.md
Reusable_Codex_Design_Control_Protocol.md
```

The Life Grid repository should copy the project-specific file to:

```text
PROTOCOL.md
```

The reusable file is a template for future projects and does not override the Life Grid-specific protocol.

---

## 20. Final operating principle

**Evidence before assertion. Approval before deviation.**

Codex is responsible for proving that Life Grid follows:

- The approved features.
- The approved behavior.
- The approved layouts.
- The approved visual identity.
- The approved change process.

When uncertain about product intent, Codex stops and asks. When certain, Codex implements and produces evidence.
