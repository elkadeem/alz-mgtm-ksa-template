# Security Service Region Limitations (Saudi Arabia East) — Defender & Sentinel

## Status

**Temporarily disabled** since 2026-11-16.

Availability statements below record the decision evidence from that rollout, not a fresh
service-availability assessment. Revalidate each product in the target environment.

## Context

Microsoft Defender for Cloud and Microsoft Sentinel are not available in `saudiarabiaeast`.

**Microsoft Sentinel** required no new action: Core-Logging (which owns the Log Analytics
workspace) is already fully disabled —
see [core-logging-disabled.md](./core-logging-disabled.md) — and even before that,
[core/logging/main.bicepparam](../templates/core/logging/main.bicepparam) already set
`parLogAnalyticsWorkspaceSolutions = ['ChangeTracking']`, which does **not** include
`'SecurityInsights'`. Since
`onboardWorkspaceToSentinel: contains(parLogAnalyticsWorkspaceSolutions, 'SecurityInsights')`
in [core/logging/main.bicep](../templates/core/logging/main.bicep), Sentinel onboarding was
already off. No file changes were needed for Sentinel.

**Microsoft Defender for Cloud / Microsoft Defender for Endpoint** required excluding 9
additional policy assignments (on top of the ones already excluded for Core-Logging reasons)
that configure or depend on those products. These were identified by searching every policy
assignment's `displayName`/`description` in
[lib/alz](../templates/core/governance/lib/alz) for Defender/Sentinel/Security Center/MCSB/
Advanced Threat Protection references, then cross-checking which management groups actually
assign them:

| Assignment | What it does | Management group(s) |
|---|---|---|
| `Deploy-ASC-Monitoring` | Assigns the Microsoft Cloud Security Benchmark (v1) initiative | int-root |
| `Deploy-MCSB2-Monitoring` | Assigns the Microsoft Cloud Security Benchmark v2 initiative | int-root |
| `Deploy-MDEndpoints` | Deploys the Microsoft Defender for Endpoint agent | int-root |
| `Deploy-MDEndpointsAMA` | Configures Defender for Endpoint ↔ Defender for Cloud integration | int-root |
| `Deploy-MDFC-OssDb` | Enables Advanced Threat Protection on open-source DBs | int-root |
| `Deploy-MDFC-SqlAtp` | Enables Defender for SQL Servers/Managed Instances | int-root |
| `Deploy-GuestAttest` | Installs Guest Attestation so Defender for Cloud can monitor VM boot integrity | platform, landingzones |
| `Deploy-SQL-Threat` | Enables Defender for SQL threat detection | landingzones |

(`Deploy-MDFC-Config-H224` and `Deploy-MDFC-DefSQL-AMA` are also Defender-related, but were
already excluded for Core-Logging reasons — see
[core-logging-disabled.md](./core-logging-disabled.md).)

## Decision

Move these 9 assignments from `managementGroupDoNotEnforcePolicyAssignments` (audit-only, per
[policy-audit-only-rollout.md](./policy-audit-only-rollout.md)) to
`managementGroupExcludedPolicyAssignments` (not created at all) — the same treatment given to
the Core-Logging-dependent assignments, since the underlying product (Defender for Cloud /
Defender for Endpoint) doesn't exist in this region at all, not merely unenforced.

`Enforce-ACSB` (Azure Compute Security Baseline) and `Deploy-SQL-TDE` (Transparent Data
Encryption) were **not excluded by this security-service decision**; neither is equivalent
to Defender/Sentinel. Both are now restored as DoNotEnforce with selected `uaenorth`
assignment locations under the separate
[policy identity decision](policy-assignment-alternate-region.md), pending operator testing.

## Changes made

1. **[templates/core/governance/mgmt-groups/int-root/main.bicepparam](../templates/core/governance/mgmt-groups/int-root/main.bicepparam)**
   — moved 6 assignments (`Deploy-ASC-Monitoring`, `Deploy-MCSB2-Monitoring`,
   `Deploy-MDEndpoints`, `Deploy-MDEndpointsAMA`, `Deploy-MDFC-OssDb`, `Deploy-MDFC-SqlAtp`)
   from `managementGroupDoNotEnforcePolicyAssignments` to `managementGroupExcludedPolicyAssignments`.
2. **[templates/core/governance/mgmt-groups/platform/main.bicepparam](../templates/core/governance/mgmt-groups/platform/main.bicepparam)**
   — moved `Deploy-GuestAttest` the same way.
3. **[templates/core/governance/mgmt-groups/landingzones/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main.bicepparam)**
   — moved `Deploy-GuestAttest` and `Deploy-SQL-Threat` the same way.

While making these changes, a **pre-existing inconsistency** from stacking earlier commits was
also found and cleaned up in all three files above: several assignments already excluded for
Core-Logging reasons (e.g. `Deploy-MDFC-Config-H224`, `Deploy-VM-ChangeTrack`,
`Deploy-vmArc-ChangeTrack`, etc.) were *also* still listed in
`managementGroupDoNotEnforcePolicyAssignments` from the audit-only rollout commit — harmless
(an excluded assignment doesn't exist, so a stray DoNotEnforce entry for it is a no-op) but
redundant. These duplicate entries were removed so each assignment now appears in exactly one
list. Every management group's assignment set was verified programmatically to form a perfect
partition between `managementGroupDoNotEnforcePolicyAssignments` and
`managementGroupExcludedPolicyAssignments` (every assignment in exactly one list, no overlaps,
no omissions).

One unrelated pre-existing item was noted but **not** changed: `int-root`'s
`managementGroupExcludedPolicyAssignments` has included `'Deploy-AzSqlDb-Auditing'` since the
very first Core-Logging commit, but that assignment is not actually assigned at the int-root
management group (no matching `loadJsonContent(...)` call in
[int-root/main.bicep](../templates/core/governance/mgmt-groups/int-root/main.bicep)) — it's a
harmless stale/no-op entry, out of scope for this change.

## Re-enabling

Once Microsoft Defender for Cloud and Microsoft Defender for Endpoint become available in
`saudiarabiaeast`, remove the 9 assignment names above from each file's
`managementGroupExcludedPolicyAssignments` (and decide whether to re-add them to
`managementGroupDoNotEnforcePolicyAssignments` for a validation period, or leave them fully
enforced) **only after resolving their logging/resource and policy identity dependencies too**.
Microsoft Sentinel can be re-enabled independently of this change by adding
`'SecurityInsights'` back to `parLogAnalyticsWorkspaceSolutions` once Core-Logging itself is
re-enabled (see [core-logging-disabled.md](./core-logging-disabled.md)).
