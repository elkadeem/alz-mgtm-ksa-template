# Future Option: User-Assigned Managed Identity for Policy Assignments (Discussion)

## Status

**Discussion item only — not implemented.** Raised 2026-11-17 while fixing
[policy-assignment-identity-unavailable-exclusions.md](./policy-assignment-identity-unavailable-exclusions.md).
No code changes have been made for this option; it needs team discussion and testing before
any assignment is converted.

## Context

The current configuration restores root's 2 assignments plus 64 additional occurrences
using [selected UAE North system-assigned identities](policy-assignment-alternate-region.md),
pending operator testing. Logging/security exclusions remain. The earlier broad override
was reverted; the current approach overrides only these 66 identity-bearing occurrences.
Existing assignment locations require inventory and lifecycle review before deployment.

The exclusions address the recorded constraint: **`identity.type: SystemAssigned`
requires Entra to host a brand-new regional identity at the assignment's `location`**, and that
creation failed in `saudiarabiaeast` during the observed rollout. Availability must be
revalidated before applying either the exclusions or this proposed alternative elsewhere.

## The option: switch affected assignments to `identity.type: UserAssigned`

A user-assigned managed identity (`Microsoft.ManagedIdentity/userAssignedIdentities`) is a
standalone resource you create yourself, in any region you choose (e.g. `uaenorth`), ahead of
time. A policy assignment that references an existing user-assigned identity doesn't ask Entra
to host a *new* identity at the assignment's own location — only `SystemAssigned` does that. In
principle this could let affected assignments be created directly at `saudiarabiaeast` (matching
every other assignment) while sourcing their identity from a region that already supports it,
with **no future delete/recreate migration** and **no loss of compliance coverage** — avoiding
the compliance-coverage loss caused by exclusions.

### What's already in place for this (verified, not assumed)

Checked the cached AVM module source
(`avm/ptn/alz/empty:0.3.6`, `policyAssignment` child resource) and this repo's wrapper
(e.g. [landingzones/main.bicep](../templates/core/governance/mgmt-groups/landingzones/main.bicep)):

- The module already supports `UserAssigned`: it builds the ARM `identity` object as
  `{ type: 'UserAssigned', userAssignedIdentities: { '<resourceId>': {} } }` when its `identity`
  parameter is `'UserAssigned'` and a `userAssignedIdentityId` parameter is supplied.
- This repo's wrapper already reads `identity: policyAssignment.identity.?type ?? 'None'` and
  `userAssignedIdentityId: policyAssignment.properties.?userAssignedIdentityId` from each
  assignment's JSON file, so converting an assignment's library JSON to:
  ```json
  "identity": { "type": "UserAssigned" },
  "properties": {
    ...
    "userAssignedIdentityId": "<resourceId-of-a-pre-created-UAMI>"
  }
  ```
  would flow through to the module without any `.bicep` changes.

### Gap that needs a decision (not yet solved)

The AVM module's automatic RBAC role-assignment logic
(`managementGroupRoleAssignments`, which grants each assignment's `roleDefinitionIds` —
the same roles already hardcoded per-policy in each `main.bicep`'s
`alzPolicyAssignmentRoleDefinitions` variable) is explicitly conditioned on
`identity == 'SystemAssigned'` and is **skipped entirely for `UserAssigned`**. Converting any
assignment to `UserAssigned` would mean its required roles are **not** granted automatically —
a separate mechanism (e.g. pre-granting roles to the UAMI once at creation time, or adding new
role-assignment resources to each `main.bicep`) would need to be designed before this is safe to
use for `DeployIfNotExists`/`Modify` assignments that currently rely on the automatic grant.

### Other open questions for the team

- **Where to create the UAMI(s)** — one shared identity per management group, one per
  subscription, or a single centralized identity reused everywhere? This affects blast radius if
  compromised, and how cleanly permissions can be scoped per policy.
- **Confirm the location restriction truly doesn't apply to `UserAssigned`** — the ARM resource
  still has its own `location` property set unconditionally (always `parLocations[0]`,
  i.e. `saudiarabiaeast`) regardless of identity type in the module source. Microsoft's
  documentation states the regional restriction is about hosting a *new* identity, which
  shouldn't apply when referencing an existing `UserAssigned` identity — but this is based on
  reading the module source and Microsoft Learn documentation, not a successful test deployment
  with `saudiarabiaeast` + `UserAssigned`. This needs to be validated in a test deployment before
  relying on it.
- **Identity lifecycle/ownership** — who creates, rotates, and manages the UAMI(s) going
  forward, and where does that Bicep/pipeline step live?
- **Migration path for the 66 off-region occurrences** - if this option is adopted, assess
  identity conversion, immutable assignment locations, required RBAC, and which remaining
  service/logging exclusions must stay. Do not assume switching identity type moves an
  existing assignment back in-region without recreation.

## Recommendation

Treat this as a candidate fix to evaluate and test (not retrofit into the existing workarounds)
once the team has decided on identity placement and the RBAC role-assignment approach for
`UserAssigned`.
