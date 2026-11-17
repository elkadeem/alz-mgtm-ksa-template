# Historical Policy Assignment Identity-Unavailable Exclusions (Saudi Arabia East)

## Status

**Superseded on 2026-11-17:** all 66 identity-only deferrals are now restored as
`DoNotEnforce` with selected `uaenorth` assignment-location overrides, pending operator testing.
See [the current configuration and test procedure](policy-assignment-alternate-region.md).
Logging/security exclusions remain. Everything below records the earlier decision, not
the current configuration or restoration instructions.

**Historical state — excluded** since 2026-11-17, applied to 64 policy assignments across 6
management groups: `landingzones` (32), `landingzones-corp` (1), `platform` (28),
`platform-connectivity` (1), `platform-identity` (1), `decommissioned` (1).

The final configuration also excludes root's `Deploy-SvcHealth-BuiltIn` and `Enforce-ACSB`,
making **66 assignment occurrences deferred specifically for identity availability**.
There is no active `uaenorth` policy-location override. This does not change the separate
Deployment Stack metadata location workaround.

## Context

After reverting the broad identity-location workaround (which incorrectly applied
`location: 'uaenorth'` to every policy assignment, including ones without a managed identity,
causing `InvalidLocationUpdate` failures),
the `alz-governance-landingzones` deployment failed again with:

```json
{
  "code": "IdentityServiceUnavailable",
  "message": "The requested operation on resource '.../policyAssignments/Deploy-SvcHealth-BuiltIn'
  failed since identity is unavailable for location 'saudiarabiaeast'. ..."
}
```

This is the same failure recorded for `int-root`: **regional resource identity creation was
unavailable in `saudiarabiaeast` during the observed rollout**, affecting every policy
assignment whose definition uses a system-assigned managed identity (required for
`DeployIfNotExists`/`Modify` effects).
Recheck support in the target environment; these observations are not a current global
service-availability guarantee.

### Scope confirmed

- `landingzones`: 32 of 42 identity-bearing assignments were failing. The other 10 were already
  excluded for unrelated Core-Logging/Defender-for-Cloud region-limitation reasons (see
  [core-logging-disabled.md](./core-logging-disabled.md) and
  [security-service-region-limitations.md](./security-service-region-limitations.md)), so the 32
  failures represent **all** remaining identity-bearing assignments in this management group —
  confirmed by cross-referencing every `.alz_policy_assignment.json` file in
  [lib/alz/landingzones](../templates/core/governance/lib/alz/landingzones) for
  `"type": "SystemAssigned"`.
- `landingzones-corp`: 1 identity-bearing assignment (`Deploy-Private-DNS-Zones`) has the same
  latent issue. It hadn't failed yet only because the pipeline stops at the earlier
  `landingzones` stage; it would fail identically once reached.
- A follow-up audit of the remaining governance management groups (`landingzones-online`,
  `landingzones-local`, `platform`, `platform-connectivity`, `platform-identity`,
  `platform-management`, `platform-security`, `decommissioned`, `sandbox`) found 31 more
  identity-bearing assignments not already excluded for other reasons, none of which had failed
  yet only because the pipeline hadn't reached them: 28 in `platform` (the same `Enforce-GR-*`
  guardrail pattern as `landingzones`, plus `Enable-AUM-CheckUpdates` and `Enforce-Encrypt-CMK0`),
  1 in `platform-connectivity` (`Enable-DDoS-VNET`), 1 in `platform-identity`
  (`Deploy-VM-Backup`), and 1 in `decommissioned` (`Enforce-ALZ-Decomm`).
  `landingzones-online`, `landingzones-local`, `platform-management`, `platform-security`, and
  `sandbox` have no identity-bearing assignments and needed no changes.
- Verified via `az policy assignment show` that **none of these 64 assignments exist in Azure
  yet** (all returned `PolicyAssignmentNotFound`) — these are clean creation failures, not
  conflicts with already-deployed resources.

## Decision — exclude, don't override identity location

Two options were considered (same two options from the `int-root` precedent):

1. **Override `location` to `uaenorth` for these assignments** (an earlier approach for root's
   `Deploy-SvcHealth-BuiltIn` and `Enforce-ACSB`, now also excluded).
   Rejected for this batch: since these 64 assignments did not exist yet, choosing to create them
   now at `uaenorth` guarantees a **future delete/recreate migration** once `saudiarabiaeast`
   supports identity hosting (Azure rejects in-place `location` changes on existing assignments —
   this is exactly the `InvalidLocationUpdate` failure that forced the revert in the first
   place). That would mean a planned enforcement/compliance gap for every one of these 64
   assignments, twice (once now, once at the future re-enablement).
2. **Exclude via `managementGroupExcludedPolicyAssignments`** (chosen). Since nothing is created
   now, re-enabling later is a normal first-time creation directly at `saudiarabiaeast` — no
   location migration, no delete/recreate step, no enforcement gap beyond the deferral itself.

The early root decision was different because two assignments had already existed at
`uaenorth`. The final root parameters nevertheless exclude both. For any already-managed
assignment, review live state and the stack's action-on-unmanage before deploying that change;
the file exclusion alone does not establish whether an existing assignment was removed.

## Changes made

### `landingzones/main.bicepparam`

- Removed all 32 affected assignment names from `managementGroupDoNotEnforcePolicyAssignments`
  (43 → 11 entries).
- Added the same 32 names to `managementGroupExcludedPolicyAssignments` (10 → 42 entries),
  alongside the existing Core-Logging/Defender exclusions.

### `landingzones/landingzones-corp/main.bicepparam`

- Removed `Deploy-Private-DNS-Zones` from `managementGroupDoNotEnforcePolicyAssignments`
  (5 → 4 entries).
- Added `Deploy-Private-DNS-Zones` to `managementGroupExcludedPolicyAssignments` (0 → 1 entry).

### `platform/main.bicepparam`

- Removed 28 affected assignment names from `managementGroupDoNotEnforcePolicyAssignments`
  (32 → 4 entries).
- Added the same 28 names to `managementGroupExcludedPolicyAssignments` (8 → 36 entries),
  alongside the existing Core-Logging/Defender exclusions.

### `platform/platform-connectivity/main.bicepparam`

- Removed `Enable-DDoS-VNET` from `managementGroupDoNotEnforcePolicyAssignments` (1 → 0 entries).
- Added `Enable-DDoS-VNET` to `managementGroupExcludedPolicyAssignments` (0 → 1 entry).

### `platform/platform-identity/main.bicepparam`

- Removed `Deploy-VM-Backup` from `managementGroupDoNotEnforcePolicyAssignments`
  (4 → 3 entries).
- Added `Deploy-VM-Backup` to `managementGroupExcludedPolicyAssignments` (0 → 1 entry).

### `decommissioned/main.bicepparam`

- Removed `Enforce-ALZ-Decomm` from `managementGroupDoNotEnforcePolicyAssignments`
  (1 → 0 entries).
- Added `Enforce-ALZ-Decomm` to `managementGroupExcludedPolicyAssignments` (0 → 1 entry).

No `.bicep` template changes were needed — `managementGroupExcludedPolicyAssignments` is an
existing parameter already wired through to the `avm/ptn/alz/empty` module, which skips creating
listed assignments entirely (same mechanism already used for the Core-Logging/Defender
exclusions in these same files).

### Dependent cross-management-group RBAC

The separate RBAC deployments must also exclude policies that are not created. Otherwise,
reading the excluded assignment's managed identity fails with `PolicyAssignmentNotFound`;
successful template validation does not check whether that assignment exists.

- [platform/main-rbac.bicepparam](../templates/core/governance/mgmt-groups/platform/main-rbac.bicepparam):
  added `Enable-DDoS-VNET`, matching its source assignment exclusion in Connectivity.
- [landingzones/main-rbac.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam):
  added `Enable-DDoS-VNET`, preserving the seven existing Platform policy exclusions.
- [platform/platform-connectivity/main-rbac.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-connectivity/main-rbac.bicepparam):
  added `Deploy-Private-DNS-Zones`, matching its source assignment exclusion in Corp.

These parameters use the templates' existing exclusion guards to skip both the policy
identity lookup and its dependent role assignments. No pipeline stages need to be disabled.

## Historical re-enablement plan (superseded)

Once regional policy identity creation is verified in the target environment, review the
64 entries above plus root's two. Restore assignments only after all their service/resource
dependencies are available, adding restored assignments to DoNotEnforce for validation.
Remove corresponding RBAC exclusions in sync, and deploy source assignments before
dependent RBAC. Previously absent assignments can be created in-region; already-existing
root assignments need a separate location/lifecycle check. Do not clear exclusions solely
because one error or one availability constraint has been resolved.
