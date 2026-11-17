# Deployment Stack Location Workaround (Saudi Arabia East)

## Status

**Temporary workaround** applied 2026-11-17. Revert once Saudi Arabia East is confirmed stable
for the `Microsoft.Resources/deploymentStacks` resource type across Azure's ARM front-ends.

## Context

After the [pipeline service connection RBAC fix](./pipeline-service-connection-rbac-fix.md),
the CD pipeline progressed to actually creating its first Deployment Stack
(`alz-governance-int-root`), but failed with:

```text
Error: Code=NoRegisteredProviderFound; Message=No registered resource provider found for
location 'saudiarabiaeast' and API version '2025-07-01' for type 'deploymentStacks'. The
supported api-versions are '2025-07-01, 2024-03-01, 2022-08-01-preview'. The supported
locations are '...' [a list that cuts off just before Spain Central, Sweden Central, Taiwan
North, UAE North, and Saudi Arabia East]
```

### Investigation and likely cause

Investigating the external pipeline template
(repository URL pattern:
`https://dev.azure.com/<AZURE_DEVOPS_ORGANIZATION>/<AZURE_DEVOPS_PROJECT>/_git/<PIPELINE_TEMPLATE_REPOSITORY>`,
specifically `.pipelines/helpers/bicep-variables.yaml` and `.pipelines/cd-template.yaml`)
revealed that **this repository's root [parameters.json](../parameters.json) file is read
directly by the pipeline** — `bicep-variables.yaml` loads it and sets every top-level key as a
pipeline variable via `##vso[task.setvariable ...]`. Every deployment step in `cd-template.yaml`
then passes `location: '$(LOCATION)'` to `bicep-deploy.yaml`, which uses it as the `-Location`
parameter on `New-AzManagementGroupDeploymentStack` / `New-AzSubscriptionDeploymentStack` / etc.

This `-Location` parameter is purely **ARM deployment/stack tracking metadata** — it is
unrelated to where the actual resources defined in the Bicep templates get created. That is
governed entirely separately, by each `.bicepparam` file's own `parLocations` array (which
remains `saudiarabiaeast` throughout this repository — see
[single-region-deployment.md](./single-region-deployment.md)).

Querying the `Microsoft.Resources` provider directly (`az provider show --namespace
Microsoft.Resources`, both generally and scoped to the Management subscription) showed
`registrationState: Registered` and **"Saudi Arabia East" present** in the supported locations
list for `deploymentStacks` — confirming the region genuinely is supported for this resource
type. The pipeline's error, however, showed a list that stopped just short of the newest-looking
entries (Spain Central, Sweden Central, Taiwan North, UAE North, Saudi Arabia East). This points
to a **possible stale ARM front-end cache** for this resource type/region combination.
That explanation was inferred from conflicting responses, not confirmed by an Azure support
root-cause analysis. Revalidate the actual target environment rather than treating it as
an established platform defect.

## Decision

Rather than wait an indeterminate amount of time for ARM cache propagation, temporarily point
the Deployment Stack's metadata-only `-Location` parameter at a nearby, long-established,
definitely-supported region — **UAE North** — while every actual Azure resource this repository
deploys continues to be created in `saudiarabiaeast`, unaffected by this change.

## Change made

**[parameters.json](../parameters.json)** — `LOCATION` changed from `"saudiarabiaeast"` to
`"uaenorth"`. `LOCATION_PRIMARY` (`"saudiarabiaeast"`) and `LOCATION_SECONDARY` (`""`) were left
unchanged — they are not referenced anywhere in the external pipeline template's YAML (verified
via search), so they remain purely descriptive of the actual target deployment region used
throughout this repository's `.bicepparam` files.

## Re-evaluating later

Once Saudi Arabia East is confirmed stable for `deploymentStacks` (e.g., a pipeline run
succeeds after changing `LOCATION` back, or enough time has passed since the region's rollout),
revert `LOCATION` in [parameters.json](../parameters.json) back to `"saudiarabiaeast"` so that
deployment-stack metadata is also stored in-region, matching `LOCATION_PRIMARY` and every
`.bicepparam` file's `parLocations`.

Elapsed time alone is not validation. Review the existing stack's location lifecycle and
the external template's behavior before changing it; an in-place metadata relocation is
not guaranteed. UAE North metadata placement requires explicit residency approval even
though regional resources remain in Saudi Arabia East. The external templates are not
included in this shareable directory and must be reviewed independently on reproduction.
