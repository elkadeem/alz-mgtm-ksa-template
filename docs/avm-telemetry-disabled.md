# AVM Telemetry Disabled (Saudi Arabia East)

## Status

**Disabled** since 2026-11-17, across all 18 `.bicepparam` files in this repository that expose
`parEnableTelemetry`.

## Context

After the [pipeline RBAC fix](./pipeline-service-connection-rbac-fix.md) and the
[Deployment Stack location workaround](./deployment-stack-location-workaround.md), the CD
pipeline progressed to actually creating the `alz-governance-int-root` Deployment Stack, but
failed with:

```text
Error: Code=LocationNotAvailableForDeployment; Message=The provided location 'saudiarabiaeast'
is not available for deployment. List of available regions is '...' [a long list that does not
include saudiarabiaeast at all]
```

### Root cause

This is a different, more fundamental issue than the `deploymentStacks` location problem: it's
about the `Microsoft.Resources/deployments` resource type itself (the core ARM mechanism behind
every Bicep `module` declaration). Verified directly via
`az provider show --namespace Microsoft.Resources --query "resourceTypes[?resourceType=='deployments'].locations"`
— **Saudi Arabia East is genuinely absent** from that list (unlike `deploymentStacks`, which did
include it). This is a confirmed platform limitation, not a stale-cache issue like the previous
one.

Inspecting the public Azure Verified Modules source
([avm/ptn/alz/empty/main.bicep](https://github.com/Azure/bicep-registry-modules/blob/main/avm/ptn/alz/empty/main.bicep),
the module underlying every management-group governance deployment in this repo) found the
cause precisely:

```bicep
#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2025-04-01' = if (enableTelemetry) {
  name: '...'
  location: location   // <- the module's business "location" parameter, NOT deployment().location
  ...
}
```

Every official AVM module (both `avm/ptn/*` pattern modules and `avm/res/*` resource modules)
includes this exact standardized telemetry resource — a raw `Microsoft.Resources/deployments`
resource used purely for anonymous Microsoft usage analytics
(see [aka.ms/avm/TelemetryInfo](https://aka.ms/avm/TelemetryInfo)). Unlike regular Bicep `module`
blocks (which automatically inherit `deployment().location` — i.e., the location we already
successfully overrode to `uaenorth` for the Deployment Stack wrapper — see
[deployment-stack-location-workaround.md](./deployment-stack-location-workaround.md)), this is a
**raw `resource` declaration**, so Bicep does not auto-apply that inheritance. The module author
explicitly set `location: location`, using the same business/region parameter we pass as
`parLocations[0]` (`saudiarabiaeast`) throughout this repository.

This means: whenever `enableTelemetry` is `true` (the AVM default, and what every
`.bicepparam` file here previously set), every single AVM module call creates this telemetry
deployment resource at `location: 'saudiarabiaeast'` — which fails immediately, since that
region isn't supported for `Microsoft.Resources/deployments` at all right now.

## Decision

Disable `enableTelemetry` (`parEnableTelemetry = false`) across every `.bicepparam` file in this
repository. This is purely anonymous Microsoft usage/adoption tracking for the AVM module
ecosystem — it has **zero effect on any actual deployed resource's functionality** — and
disabling it is an explicitly supported, documented AVM configuration option, not a workaround
that fights the module's design.

## Changes made

Set `parEnableTelemetry = false` (from `true`) in all 18 files that declare it:

- `templates/core/logging/main.bicepparam`
- `templates/networking/hubnetworking/main.bicepparam`
- `templates/networking/virtualwan/main.bicepparam`
- `templates/core/governance/mgmt-groups/int-root/main.bicepparam`
- `templates/core/governance/mgmt-groups/decommissioned/main.bicepparam`
- `templates/core/governance/mgmt-groups/sandbox/main.bicepparam`
- `templates/core/governance/mgmt-groups/landingzones/main.bicepparam`
- `templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam`
- `templates/core/governance/mgmt-groups/landingzones/landingzones-corp/main.bicepparam`
- `templates/core/governance/mgmt-groups/landingzones/landingzones-local/main.bicepparam`
- `templates/core/governance/mgmt-groups/landingzones/landingzones-online/main.bicepparam`
- `templates/core/governance/mgmt-groups/platform/main.bicepparam`
- `templates/core/governance/mgmt-groups/platform/main-rbac.bicepparam`
- `templates/core/governance/mgmt-groups/platform/platform-connectivity/main.bicepparam`
- `templates/core/governance/mgmt-groups/platform/platform-connectivity/main-rbac.bicepparam`
- `templates/core/governance/mgmt-groups/platform/platform-identity/main.bicepparam`
- `templates/core/governance/mgmt-groups/platform/platform-management/main.bicepparam`
- `templates/core/governance/mgmt-groups/platform/platform-security/main.bicepparam`

No bicep template logic was changed — `enableTelemetry` was already threaded through as a
parameter everywhere; only its default value in the parameter files changed.

## Re-enabling later

Once `Microsoft.Resources/deployments` supports `saudiarabiaeast` (check with
`az provider show --namespace Microsoft.Resources --query "resourceTypes[?resourceType=='deployments'].locations"`),
set `parEnableTelemetry` back to `true` in the files above if you want to contribute to AVM's
anonymous usage telemetry again. This is purely a courtesy/analytics setting for Microsoft, not
required for this repository's deployments to function correctly either way.
