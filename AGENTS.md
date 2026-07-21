# Life Grid Agent Rules

These rules apply to every file in this repository.

1. Read `PROTOCOL.md` before modifying the project.
2. Read `docs/approved/Life_Grid_Product_Spec.md` completely before implementing features.
3. Inspect the approved layout for every screen being changed.
4. Declare the requirement IDs involved before beginning work.
5. Declare the files expected to change.
6. Declare the tests and visual evidence required.
7. Respect the current approval gate.
8. Stop when a product-affecting ambiguity is found.
9. Put unapproved improvement ideas in `backlog/SUGGESTED_IMPROVEMENTS.md`.
10. Run `python3 protocol/validate.py` for the relevant gate before claiming a milestone complete.
11. Report evidence instead of merely stating that work is finished.
12. Never modify an accepted approval record retroactively.
13. Never redesign the approved Life Grid icon.

Before implementation, publish this declaration:

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

Stop on the first failed test, build, code-sign, source-integrity, or protocol-validation check. Do not advance until the failure is resolved or the user explicitly directs a permitted alternative.
