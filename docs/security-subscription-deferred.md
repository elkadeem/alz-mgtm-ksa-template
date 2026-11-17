# Security Subscription Deferred

## Status

**Deferred** since 2026-11-16 — not currently deployed. Can be enabled later once a dedicated
Security subscription is provisioned.

## Context

Per the official Azure Landing Zones accelerator planning documentation
([Phase 0 - Planning](https://azure.github.io/Azure-Landing-Zones/accelerator/0_planning/),
"Decision 7 - Choose the platform subscriptions"):

> **Security** (recommended): Used to deploy Sentinel and other security related resources.
> *Can be deferred for SMB scenarios, but will be required as you scale.*

No dedicated Security subscription has been provisioned for this environment yet. Before this
change, [platform/platform-security/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam)
placed the **Management** subscription (`11111111-1111-1111-1111-111111111111`) into the
Security management group — the same subscription already placed in
[platform/platform-management/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-management/main.bicepparam).
A subscription can only belong to one management group at a time, so this was really just a
placeholder value, not a real Security subscription — see the (now resolved) risk noted in
[core-logging-disabled.md](./core-logging-disabled.md).

## Decision

Rather than leave an invalid/conflicting placeholder in place, defer the entire
`platform-security` deployment step until a real Security subscription exists — consistent
with how the accelerator docs describe this as an optional, deferrable scenario, and
consistent with how Core-Logging was already deferred in this environment (see
[core-logging-disabled.md](./core-logging-disabled.md)).

## Changes made

1. **[.pipelines/cd.yaml](../.pipelines/cd.yaml)** — the `governance-platform-security`
   pipeline parameter default was changed from `true` to `false`, skipping the
   platform-security management group deployment entirely (no management group created, no
   policies assigned, no subscription placement attempted).
2. **[templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam)**
   — `subscriptionsToPlaceInManagementGroup` cleared from
   `['11111111-1111-1111-1111-111111111111']` to `[]`, removing the conflicting placeholder so
   that if this step is ever re-enabled without first updating this value, it simply creates an
   empty Security management group rather than re-triggering the subscription conflict.
3. **[parameters.json](../parameters.json)** — `SUBSCRIPTION_ID_SECURITY` cleared from
   `"11111111-1111-1111-1111-111111111111"` to `""`, for consistency with the above. (Note:
   subsequent investigation found this file *is* consumed directly by the external pipeline
   template — see [deployment-stack-location-workaround.md](./deployment-stack-location-workaround.md)
   — though not by any Bicep template in this repository.)

No other files were changed. The management group's policy configuration
(`managementGroupDoNotEnforcePolicyAssignments`, `managementGroupExcludedPolicyAssignments`,
`parPolicyAssignmentParameterOverrides`) was already empty/minimal and was left as-is.

## Enabling the Security subscription later

1. Provision a dedicated Security subscription (per the accelerator docs' recommendation of 4
   platform subscriptions: Management, Connectivity, Identity, Security).
2. In
   [platform/platform-security/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam),
   set `subscriptionsToPlaceInManagementGroup` to the new subscription's ID.
3. Update `SUBSCRIPTION_ID_SECURITY` in [parameters.json](../parameters.json) to match.
4. In [.pipelines/cd.yaml](../.pipelines/cd.yaml), set the `governance-platform-security`
   parameter default back to `true` (or toggle it on at pipeline queue-time).
5. Consider whether Microsoft Sentinel should also be re-enabled at the same time — see
   [security-service-region-limitations.md](./security-service-region-limitations.md) (Sentinel
   is currently off for a separate reason: it isn't available in `saudiarabiaeast` yet).

## Addendum (2026-11-17): same conflict pattern in the bootstrap config

[config/inputs.yaml](../config/inputs.yaml)'s `subscription_ids.security` had the identical
duplicate-of-Management-ID pattern described above (not fixed by the original change, which
predates `config/` being added to this repo). It has now been blanked to `""`, consistent with
this decision. See [accelerator-local-bootstrap.md](accelerator-local-bootstrap.md) for the
full set of `config/inputs.yaml` consistency fixes.
