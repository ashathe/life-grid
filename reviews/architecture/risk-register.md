# Life Grid Phase 1 Risk Register

Gate status in this document means evidence readiness, not approval. Architecture Gate 1 remains pending.

| Risk | Severity | Likelihood | Mitigation | Evidence | Gate status |
| --- | --- | --- | --- | --- | --- |
| JSON corruption | High | Low | Preserve unreadable bytes, return an error, retain in-memory state | `JSONAppStateRepositoryTests.corruptJSONThrowsWithoutDeletingFile` | Mitigated; approval pending |
| Unsupported future schema | High | Medium | Decode version envelope first and reject without replacement | `StateMigration.swift`; future-schema repository test | Mitigated; approval pending |
| Save failure | High | Medium | Atomic write, retain memory state, record diagnostic, retry complete snapshot | `AppStateStoreTests` failure and retry cases | Mitigated; approval pending |
| Swift concurrency isolation | High | Medium | Main-actor store, actor repositories/doubles, Sendable contracts | `AppStateStore.swift`; clean Swift test compilation | Mitigated; approval pending |
| Manual Xcode project drift | Medium | Medium | Shared scheme, source membership review, iPhone/iPad builds, structural Git review | `LifeGrid.xcodeproj`; Phase 1 verification plan | Open until fresh builds |
| Dynamic Type pressure in two columns | Medium | Medium | Geometry-based layout, vertical expansion policy, 44-point floor; visual testing later | `GameLayoutMode.swift`; `AppScaleTokens.swift` | Foundation mitigated; visual review pending |
| Missing reusable protocol template | Medium | Low | Repository-local schemas, templates, validator, and immutable approval records | `protocol/`; `approvals/templates/`; `changes/TEMPLATE.md`; `reports/COMPLIANCE_REPORT_TEMPLATE.md` | Mitigated; approval pending |
| Approved icon asset production deferred | Medium | Medium | Preserve exact selected PNG and explicit no-redesign requirement VIS-009 | `docs/approved/Life_Grid_Selected_Icon_Reference.png`; visual manifest | Deferred to visual phase |

## Residual decisions

No risk above authorizes feature implementation or a visual variance. Any change to an approved requirement, layout, icon, or error behavior must use the protocol’s ambiguity, variance, or change-request workflow.
