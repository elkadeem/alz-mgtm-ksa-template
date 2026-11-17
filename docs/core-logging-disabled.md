# Core-Logging Temporarily Disabled (Saudi Arabia East)

## Status

**Temporarily disabled** since 2026-11-16.

## Context

The primary deployment region for this environment is `saudiarabiaeast` (see
[parameters.json](../parameters.json)). Saudi Arabia East is a newly announced Azure region
that is still rolling out, and `Microsoft.OperationalInsights/workspaces` (Log Analytics) is
not yet available there. Since the Core-Logging module
([templates/core/logging/main.bicep](../templates/core/logging/main.bicep)) deploys the Log
Analytics workspace, Automation Account, and Azure Monitor Agent / Data Collection Rule
resources into `saudiarabiaeast`, deployments of that step fail.

## Decision

Disable the Core-Logging deployment step until Log Analytics is available in the region,
while keeping all logging configuration intact so it can be re-enabled later with minimal
effort. Governance policy assignments that reference the logging workspace, its Data
Collection Rules, or its managed identity were excluded at the same time — otherwise their
`DeployIfNotExists` remediation would fail or report non-compliant against resources that no
longer exist.

## Changes made

1. **[.pipelines/cd.yaml](../.pipelines/cd.yaml)** — the `core-logging` pipeline parameter
   default was changed from `true` to `false`, skipping the Core-Logging deployment step.
2. **[templates/core/governance/mgmt-groups/int-root/main.bicepparam](../templates/core/governance/mgmt-groups/int-root/main.bicepparam)**
   — added 4 policy assignment names to `managementGroupExcludedPolicyAssignments`:
   - `Deploy-MDFC-Config-H224`
   - `Deploy-AzActivity-Log`
   - `Deploy-Diag-LogsCat`
   - `Deploy-AzSqlDb-Auditing`
3. **[templates/core/governance/mgmt-groups/landingzones/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main.bicepparam)**
   — added 8 policy assignment names to `managementGroupExcludedPolicyAssignments`:
   - `Deploy-AzSqlDb-Auditing`
   - `Deploy-vmArc-ChangeTrack`
   - `Deploy-VM-ChangeTrack`
   - `Deploy-VMSS-ChangeTrack`
   - `Deploy-vmHybr-Monitoring`
   - `Deploy-VM-Monitoring`
   - `Deploy-VMSS-Monitoring`
   - `Deploy-MDFC-DefSQL-AMA`
4. **[templates/core/governance/mgmt-groups/platform/main.bicepparam](../templates/core/governance/mgmt-groups/platform/main.bicepparam)**
   — added 7 policy assignment names to `managementGroupExcludedPolicyAssignments` (found during
   a follow-up governance review on 2026-11-16 — this file was missed in the initial pass):
   - `Deploy-VM-ChangeTrack`
   - `Deploy-VM-Monitoring`
   - `Deploy-VMSS-ChangeTrack`
   - `Deploy-VMSS-Monitoring`
   - `Deploy-vmArc-ChangeTrack`
   - `Deploy-vmHybr-Monitoring`
   - `Deploy-MDFC-DefSQL-AMA`
5. **[templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam)**
   — added the same 7 names to `parManagementGroupExcludedPolicyAssignments` (also found during
   the follow-up review). This cross-MG RBAC module
   ([main-rbac.bicep](../templates/core/governance/mgmt-groups/landingzones/main-rbac.bicep))
   looks up those 7 policy assignments as `existing` resources in the **Platform** management
   group to copy their managed-identity RBAC into the Landing Zones management group. Since
   change #4 above stops those assignments from being created in Platform, this module's own
   exclusion list must stay in sync or its `existing` resource lookups fail with
   resource-not-found errors.

No other files were modified. The `parPolicyAssignmentParameterOverrides` blocks, the Log
Analytics workspace configuration, and the Data Collection Rule settings were left untouched
— they are simply unused while the step/assignments stay disabled.

## Alternative considered

Instead of disabling logging outright, the Log Analytics workspace (and Automation Account)
location could be pointed at a different, already-supported region via
`parLogAnalyticsWorkspaceLocation` / `parAutomationAccountLocation` in
[templates/core/logging/main.bicepparam](../templates/core/logging/main.bicepparam), while
keeping everything else in `saudiarabiaeast`. This was not chosen here because the goal was to
fully disable logging for now, not relocate it.

## Re-enabling Core-Logging

The steps below reverse this decision's changes only. The final configuration also has
Defender and policy-identity exclusions. Restore an assignment/RBAC lookup only after all
its blockers have been resolved, deploy referenced resources first, and use DoNotEnforce
for an approved validation period. Do not clear the final exclusion lists wholesale.
The preserved logging parameters also keep `parDeployAutomationAccount = false`;
enabling this pipeline step does not automatically enable that resource or Sentinel.

Once Log Analytics (and Data Collection Rules) become available in `saudiarabiaeast`, reverse
the changes above:

1. In [.pipelines/cd.yaml](../.pipelines/cd.yaml), set the `core-logging` parameter default
   back to `true` (or toggle it on at pipeline queue-time).
2. In
   [templates/core/governance/mgmt-groups/int-root/main.bicepparam](../templates/core/governance/mgmt-groups/int-root/main.bicepparam),
   remove the 4 entries listed above from `managementGroupExcludedPolicyAssignments`.
3. In
   [templates/core/governance/mgmt-groups/landingzones/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main.bicepparam),
   remove the 8 entries listed above from `managementGroupExcludedPolicyAssignments`.
4. In
   [templates/core/governance/mgmt-groups/platform/main.bicepparam](../templates/core/governance/mgmt-groups/platform/main.bicepparam),
   remove the 7 entries listed above from `managementGroupExcludedPolicyAssignments`.
5. In
   [templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam),
   remove the same 7 entries from `parManagementGroupExcludedPolicyAssignments`.
6. Run a What-If/validation pass before merging to confirm the Log Analytics workspace and
   dependent policy assignments deploy successfully.

## Previously known governance risk — now resolved

Unrelated to Core-Logging, an earlier review found that subscription
`11111111-1111-1111-1111-111111111111` was listed in **both**
[platform/platform-management/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-management/main.bicepparam)
and
[platform/platform-security/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam)'s
`subscriptionsToPlaceInManagementGroup`, which would have caused the subscription to bounce
between management groups depending on pipeline step order. This has since been resolved by
deferring the Security subscription entirely — see
[docs/security-subscription-deferred.md](./security-subscription-deferred.md).
