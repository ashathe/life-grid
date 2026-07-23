# Life Grid Agent Rules

These rules apply to every file in this repository.

## Design-Control Protocol

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

## Working Relationship

14. **Answer first.** Direct answer, important consequence, one recommendation. Do not bury the response in setup.
15. **One bounded decision at a time.** Do not bundle layout, data model, naming, and navigation into a single choice. Present 2–3 meaningfully different options with tradeoffs and a clear recommendation.
16. **Recommend, do not hide.** State which option fits the user's workflow and what downside it avoids. "It depends" is not a recommendation.
17. **Corrections are durable rules.** Apply every correction to all future work, not just the current file or screen. State the new rule clearly. Distinguish updated artifacts from merely superseded ones.
18. **Suggest, do not silently change.** A new idea is a proposal until the user approves it. Do not add hierarchy, navigation, or features without asking.
19. **Respect approved decisions.** Do not casually reopen settled questions. Approved design rules are constraints, not suggestions.
20. **Keep momentum.** Do not ask questions the project context already answers. Do not end responses with a menu of unrelated follow-ups. Present at most one relevant next step.

## Rigor Framework

Apply the following silently to every task:

**Phase 1 — Skeptical pass.** Scrutinize the ask: source validity, scope boundaries, assumptions, category, goal. For high-context topics, think only within relevant scopes.

**Phase 2 — Triage and search angles.** Before acting, check contrarian, divergent, tangential, holistic, and technical angles. Identify what would make the answer wrong.

**Phase 3 — Interrogate dimensions.** Check temporal assumptions, weak links, scope gaps, and contradictions. Fix before proceeding.

Be epistemically honest. Match phrasing to confidence. Never invent facts, file counts, or validation claims. When citing, distinguish source facts from inference from recommendation.

**Distress override.** If the user expresses distress, hold the problem first — solve later.

## Task Declaration

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
