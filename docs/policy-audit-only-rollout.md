# Policy Audit-Only Rollout (Initial Saudi Arabia East Deployment)

## Status

**Temporary rollout posture** since 2026-11-16. The original rollout covered 123 declared
assignment occurrences. After restoring the 66 identity-only deferrals with
[selected UAE North identities](policy-assignment-alternate-region.md), the configuration
has **96 DoNotEnforce occurrences and 27 excluded occurrences** (80 unique
assignment names across the 123 declarations). The historical table below describes the
earlier rollout, not the current active count. See the
[final policy matrix](saudi-arabia-east-implementation-guide.md#5-final-policy-accounting).

## Context

For the initial rollout into `saudiarabiaeast` (a newly announced, still-rolling-out Azure
region), it's safer to deploy governance with all policy effects observed but not enforced,
so that any unexpected compliance issues (service/SKU/API availability gaps in the new region,
misconfigured overrides, etc.) show up as compliance findings instead of blocking deployments
or triggering remediation tasks.

## Decision — use `enforcementMode: DoNotEnforce`, not per-policy `effect` overrides

Every management group config in this repo (the shared `alzCoreType`, see
[alzCoreType.bicep](../templates/core/alzCoreType.bicep)) exposes
`managementGroupDoNotEnforcePolicyAssignments`. Per the published source of the
`avm/ptn/alz/empty` module, listing a policy assignment's name there sets that assignment's
`enforcementMode` to `DoNotEnforce`.

Per Microsoft's Azure Policy documentation, `DoNotEnforce` suppresses normal automatic
policy enforcement, while the resource's **compliance state is still evaluated and visible**.
It does not prohibit an operator from explicitly starting supported remediation tasks.
This was chosen over trying to
override each policy's `effect` parameter to `Audit`, because:

- It works uniformly for every effect type (Deny, DeployIfNotExists, Modify, etc.), whereas many
  of the ~190 bundled policy definitions in
  [lib/alz](../templates/core/governance/lib/alz) don't expose an overridable `effect`
  parameter at all (some are hardcoded to a single effect in the policy rule itself).
- It requires maintaining exactly one list per management group, instead of per-policy
  parameter overrides scattered across ~120 assignments.

**There is no wildcard.** The array is checked with a plain `contains()` match against each
assignment's exact `name` (not its display name, despite the inline parameter doc comment) —
every assignment name has to be listed explicitly.

## Changes made

Initially added the full, verified list of policy assignment names to
`managementGroupDoNotEnforcePolicyAssignments` in every management-group parameter file that
assigns its own policies (123 assignments total; counts cross-checked against the
`loadJsonContent(...)` calls in each `main.bicep`):

| File | Assignments set to DoNotEnforce |
|---|---|
| [int-root/main.bicepparam](../templates/core/governance/mgmt-groups/int-root/main.bicepparam) | 17 |
| [landingzones/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main.bicepparam) | 53 |
| [landingzones/landingzones-corp/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/landingzones-corp/main.bicepparam) | 5 |
| [landingzones/landingzones-local/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/landingzones-local/main.bicepparam) | 1 |
| [platform/main.bicepparam](../templates/core/governance/mgmt-groups/platform/main.bicepparam) | 40 |
| [platform/platform-identity/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-identity/main.bicepparam) | 4 |
| [platform/platform-connectivity/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-connectivity/main.bicepparam) | 1 |
| [decommissioned/main.bicepparam](../templates/core/governance/mgmt-groups/decommissioned/main.bicepparam) | 1 |
| [sandbox/main.bicepparam](../templates/core/governance/mgmt-groups/sandbox/main.bicepparam) | 1 |
| **Total** | **123** |

`landingzones/landingzones-online/main.bicepparam`, `platform/platform-management/main.bicepparam`,
and `platform/platform-security/main.bicepparam` were **not** changed — those management groups
assign zero policies of their own (`alzPolicyAssignmentsJson = []` in their `main.bicep`); they
only inherit policy from their parent management groups, which are already covered above.

The audit-only operation itself changed only `enforcementMode`. Later decisions moved
additional assignments to the exclusion lists. The 66 identity-only deferrals are now
restored for evaluation, pending operator deployment; service-related exclusions remain.

## Interaction with the Core-Logging exclusions

This is independent of, and does not replace,
[docs/core-logging-disabled.md](./core-logging-disabled.md). The 19 policy assignments
excluded there (via `managementGroupExcludedPolicyAssignments`) are **not created at all**
while Core-Logging is disabled, so they are not in these DoNotEnforce lists either — there is
nothing to set an enforcement mode on for an assignment that doesn't exist.

## Re-enforcing after initial validation

Once the initial deployment has been validated, review compliance findings and obtain owner
approval before removing selected `managementGroupDoNotEnforcePolicyAssignments` entries.
They then return to normal `Default` enforcement mode. Restore excluded assignments only
after all their service, resource, and identity blockers have been resolved; do not clear
entire lists indiscriminately.
