# Life Grid iPhone-Primary Delivery Scope Design

**Status:** User-approved design

**Scope:** Future delivery policy, beginning with Phase 3

## Decision

Life Grid remains a universal SwiftUI target with its present adaptive iPad fallback. The iPhone app is the sole active delivery target. This is the selected first approach from the scope review: retain the fallback without removing platform eligibility or spending new development and verification effort on it.

## Authority and boundaries

`changes/CR-002-iphone-primary-delivery.md` is the explicit user correction that supersedes iPad-delivery obligations in the approved source material for future work. The supplied specifications and existing iPad artifacts remain unchanged historical authorities.

This decision does not:

- change `TARGETED_DEVICE_FAMILY = "1,2"`;
- remove iPad installation capability;
- claim that iPad behavior is verified or supported;
- alter the completed Phase 1 or Phase 2 evidence; or
- authorize Phase 3 implementation.

## Delivery policy

All pending work uses the iPhone portrait layout as its design, implementation, accessibility, UI-test, screenshot, and build target. No iPad-specific layout branch, screenshot, build, or automated test is added or refreshed.

Existing SwiftUI behavior on iPad is best effort only. A regression visible only on iPad does not block an iPhone milestone unless the user restores iPad scope through an explicit approved change.

## Phase 3 implication

The Phase 3 Game screen design will implement the approved iPhone portrait order: local life card, pinned counters, opponents, then Out of Game tray. It will not design or validate the approved iPhone-landscape or iPad two-column variations.

## Validation

Each future milestone runs its relevant unit/UI tests and an iPhone simulator build. Evidence reports name the iPhone destination and explicitly state that iPad verification is deferred under CR-002.
