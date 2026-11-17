# Copilot Runbook: Adapt a Fresh ALZ Accelerator Template

## How to use this runbook

Generate a **new Bicep / Azure DevOps / hub-networking** ALZ accelerator configuration using
the official [accelerator workflow](https://azure.github.io/Azure-Landing-Zones/accelerator/).
Do not treat this repository as a replacement for accelerator bootstrap. Select one target
region, `saudiarabiaeast`, and three platform subscriptions where the generator supports
those choices. Defer Security if that option exists; otherwise apply step 6 below.

Work in a private branch/copy. Give Copilot this runbook, the
[implementation guide](saudi-arabia-east-implementation-guide.md), and the sanitized reference
configuration as read-only context. Paste the prompts **one step at a time**. Review each
result before proceeding; do not ask Copilot to execute the entire sequence without gates.
Keep real environment inputs in your approved private configuration process.

These are adaptations of the observed 2026-11-17 baseline, not timeless Azure restrictions.
If the generated layout/module APIs or current service support differ, stop and present the
difference. Prefer supported generator options and existing parameter hooks over code patches.
Do not downgrade newer modules or remove unrelated policy coverage merely to match old counts.

## 0. Establish boundaries

```text
Adapt this freshly generated ALZ accelerator Bicep configuration for a single-region
Saudi Arabia East rollout using the supplied implementation guide as a reference.
Inspect before editing. Preserve unrelated work and use the generated project's naming,
hierarchy, and parameter APIs. Do not copy subscription/tenant IDs or private URLs from
another environment. Do not deploy, move subscriptions, change IAM, create identities,
run remediation, or delete resources without separate explicit approval.
Do not enable out-of-region resources or metadata without approval.
Treat regional availability claims as dated observations, not current facts.
Use placeholders for missing private inputs; report blockers rather than invent values.
After each step list changed files, validation results, and remaining approval gates.
```

**Gate:** Copilot acknowledges file changes only; Azure and Azure DevOps administration are
not authorized. If using a different topology, deployment tool, or IaC language, redesign the
mapping rather than applying these paths literally.

## 1. Inventory and map the new baseline

```text
Read the generated README, parameter files, Bicep entry points, policy JSON libraries,
CI/CD wrappers, and available shared pipeline templates. Do not edit yet.
Record the accelerator version if available, Bicep version, AVM module pins, policy-library
version, and external pipeline repository ref/commit; mark missing versions unknown.
Map the reference paths/settings to this generated layout.
Resolve policy assignment names and identity types from each main.bicep's actual
loadJsonContent references; do not assume every JSON library file is assigned.
Report management-group/subscription placement, topology, locations, service flags,
logging/Sentinel settings, telemetry propagation, cross-MG RBAC lookups, and stack behavior.
Confirm whether root parameters.json is consumed by pipelines and exactly what LOCATION
controls. Identify action-on-unmanage/delete settings and pipeline ordering.
```

**Gate:** a concrete path/setting map and dependency inventory. Obtain the actual external
templates if unavailable; local wrapper YAML alone cannot establish their behavior.

## 2. Revalidate availability and approve the target profile

```text
Prepare a read-only preflight for the approved target subscriptions. Check region access,
provider registration, relevant resource-type/API locations, SKU/zone/capacity restrictions,
and support guidance for VPN Gateway, Firewall, Bastion, DDoS, ExpressRoute gateway,
DNS Private Resolver/endpoints, Log Analytics, DCRs, managed identities, Defender, Sentinel,
Microsoft.Resources/deploymentStacks and Microsoft.Resources/deployments.
Distinguish confirmed failures, provider-metadata evidence, services merely absent from
an availability list, and unknowns. Do not infer gateway support from ExpressRoute circuits.
Do not register providers or make test deployments automatically. If read access is not
authorized, list the evidence needed instead.
Propose which historical workarounds are still necessary and get owner approval before edits.
Explicitly request approval for UAE North stack metadata if retaining that workaround.
```

Optional **read-only**, Azure CLI examples after authorization, in PowerShell:

```powershell
az account list-locations --subscription "<CONNECTIVITY_SUBSCRIPTION_ID>" --query "[?name=='saudiarabiaeast']"
az provider show --subscription "<CONNECTIVITY_SUBSCRIPTION_ID>" --namespace Microsoft.Network --query "resourceTypes[?resourceType=='dnsResolvers' || resourceType=='dnsResolvers/inboundEndpoints' || resourceType=='dnsResolvers/outboundEndpoints'].{type:resourceType,locations:locations}"
az provider show --subscription "<MANAGEMENT_SUBSCRIPTION_ID>" --namespace Microsoft.OperationalInsights --query "resourceTypes[?resourceType=='workspaces'].{type:resourceType,locations:locations}"
az provider show --subscription "<MANAGEMENT_SUBSCRIPTION_ID>" --namespace Microsoft.Resources --query "resourceTypes[?resourceType=='deploymentStacks' || resourceType=='deployments'].{type:resourceType,locations:locations}"
```

**Gate:** approved feature matrix. Those commands are partial metadata checks, not a complete
service/SKU validation or proof that policy identity creation will work.

## 3. Configure private inputs and single-region topology

```text
Apply only the approved single-region configuration. Use saudiarabiaeast for regional
resource placement. Set each relevant parLocations array to one entry; remove second hub
objects, second-region indexes and inter-hub peering settings. Keep deployPeering false.
Retain an inactive Virtual WAN example consistently if this generator includes it, but do
not activate it or replace hub networking. Remove empty secondary-region deployment targets.
Use approved private subscription inputs consistently in root parameters, placement arrays,
and full resource-ID policy overrides; do not assume parameters.json substitutes Bicep values.
Only Management/Connectivity/Identity children should place their respective subscriptions.
Keep generic reference naming only if approved and check all address ranges for conflicts.
If stack LOCATION has the verified metadata-only semantics and the owner approved the
historical workaround, use uaenorth there only; keep resource locations saudiarabiaeast.
Otherwise stop rather than relocating resources or guessing pipeline behavior.
```

**Gate:** one hub, no live second-region references/peering, no duplicate subscription
placement, no unintended cross-region resource relocation. Empty root secondary description
is acceptable; an empty location in a deployable hub is not.

## 4. Gate unavailable networking and apply the DNS mapping fix

```text
For the approved deferred services, use existing flags in the surviving hub:
azureFirewallSettings.deployAzureFirewall=false
bastionHostSettings.deployBastion=false
ddosProtectionPlanSettings.deployDdosProtectionPlan=false
expressRouteGatewaySettings.deployExpressRouteGateway=false
privateDnsSettings.deployDnsPrivateResolver=false
Keep privateDnsSettings.deployPrivateDnsZones=true and VPN enabled only with its approved
SKU/zones/settings. The reference uses VpnGw1AZ, activeActiveBgp, RouteBased, ASN 65515;
do not treat that as proof the target subscription supports it.
Preserve reserved subnets, delegations, names, and settings for future restoration.
Inspect template conditions to ensure disabled services also skip dependent policies,
route tables, IPs, Bastion NSG, and DNS resolver modules/resource groups.
Mirror equivalent flags in the inactive Virtual WAN file if present; leave its S2S/P2S
VPN disabled as in the reference. Do not deploy both network topologies.
Inspect the pinned private-link-private-dns-zones module's region mapping. If it is the
affected 0.7.2 baseline, change only that module to 0.7.4 in both networking templates.
For a newer compatible module that already supports saudiarabiaeast, keep it; do not downgrade.
Verify that an empty privateDnsZones list uses the selected module's intended defaults.
```

**Gate:** five deferred hub services are off; DNS zones and approved VPN remain on;
no dependency refers unconditionally to a disabled service.

## 5. Disable AVM usage telemetry through existing hooks

```text
Set parEnableTelemetry=false in every parameter file exposing that hook and verify it
flows to the called AVM modules. Include governance, cross-MG RBAC, logging, and both
network examples, not just active steps. Do not rewrite vendor modules or disable workload
telemetry to accomplish this. The reference has 18 such files; discover the actual count
in this new baseline and explain differences.
```

**Gate:** every relevant declared telemetry parameter is false, and no new raw telemetry
deployment is introduced in the unsupported location.

## 6. Defer logging, Sentinel, and the optional Security subscription

```text
Set the core-logging CD switch default false while preserving configuration for restoration.
Keep Sentinel onboarding off (no SecurityInsights solution). Preserve the generated
Automation Account choice; the reference has parDeployAutomationAccount=false.
Set the governance-platform-security CD switch default false. Clear Security subscription
placement and the optional root Security ID. Never reuse Management's subscription for it.
Do not remove the whole management-group template or alter unrelated pipeline switches.
Warn that queue-time toggles can override defaults.
```

**Gate:** logging and Security defaults off, Security placement empty, no Sentinel onboarding.
There are no policy assignments referencing missing logging identities **without** an
exclusion; complete the next step before declaring the configuration deployable.

## 7. Build policy exclusions and non-enforcement lists from evidence

```text
For each management group resolve its declared policy assignment JSONs and exact names.
Use existing managementGroupExcludedPolicyAssignments and
managementGroupDoNotEnforcePolicyAssignments hooks, not global policy effect rewrites.

Apply approved logging exclusions where actually assigned:
int-root: Deploy-MDFC-Config-H224, Deploy-AzActivity-Log, Deploy-Diag-LogsCat.
landingzones: Deploy-AzSqlDb-Auditing, Deploy-vmArc-ChangeTrack, Deploy-VM-ChangeTrack,
Deploy-VMSS-ChangeTrack, Deploy-vmHybr-Monitoring, Deploy-VM-Monitoring,
Deploy-VMSS-Monitoring, Deploy-MDFC-DefSQL-AMA.
platform: Deploy-VM-ChangeTrack, Deploy-VM-Monitoring, Deploy-VMSS-ChangeTrack,
Deploy-VMSS-Monitoring, Deploy-vmArc-ChangeTrack, Deploy-vmHybr-Monitoring,
Deploy-MDFC-DefSQL-AMA.

Apply approved Defender-related exclusions where actually assigned:
int-root: Deploy-ASC-Monitoring, Deploy-MCSB2-Monitoring, Deploy-MDEndpoints,
Deploy-MDEndpointsAMA, Deploy-MDFC-OssDb, Deploy-MDFC-SqlAtp.
platform: Deploy-GuestAttest.
landingzones: Deploy-GuestAttest, Deploy-SQL-Threat.

If policy regional identity hosting remains unavailable and deferral was approved, inspect
every remaining assigned JSON's identity.type and exclude all remaining SystemAssigned
assignments. This includes root Deploy-SvcHealth-BuiltIn and Enforce-ACSB; do not add a
uaenorth policy location override. Discover newly introduced identity-bearing assignments
in newer libraries rather than hardcoding only the historical names.
Do not exclude SQL TDE merely because of Defender; it is separately identity-deferred in
the reference. Record every exclusion's reasons; a policy can have multiple blockers.
For new unsupported identity shapes or module APIs, stop and report rather than guess.

Put all remaining declared assignments into DoNotEnforce using exact name matching.
Deduplicate arrays and ensure no name is in both. Preserve policy parameter overrides,
updating private resource IDs consistently even where currently inactive.
Do not change policy JSON identity types or add shared user-assigned policy identities.
Do not add root Deploy-AzSqlDb-Auditing if root does not assign it: the reference's extra
entry is a historical no-op, not a required adaptation.
```

**Gate:** for each group, declared assignments = disjoint union of excluded and DoNotEnforce
assignments. No missing/duplicate names or new enforced assignments. For the **same pinned
reference baseline**, expect 123 occurrences, 30 DoNotEnforce, 93 excluded; compare the
[per-group matrix](saudi-arabia-east-implementation-guide.md#5-final-policy-accounting).
A newer library may legitimately produce different totals; require an explained diff.
This is a reduced-coverage rollout and needs explicit risk acceptance.

## 8. Synchronize cross-management-group RBAC

```text
Trace every existing policy-assignment identity lookup in the separate RBAC deployments.
Exclude a lookup and its role grants when the source assignment is excluded:
Platform RBAC: Connectivity Enable-DDoS-VNET.
Landing Zones RBAC: Platform's seven logging-related assignments plus Connectivity
Enable-DDoS-VNET.
Connectivity RBAC: Corp Deploy-Private-DNS-Zones.
Use parManagementGroupExcludedPolicyAssignments or the generated equivalent.
Inspect actual source groups and any new dependencies; do not copy all policy exclusion
lists blindly into every RBAC module. Keep stages enabled when their guards suffice.
Ensure the external pipeline creates each source assignment before dependent role grants.
```

**Gate:** no unguarded reference to an excluded assignment's principal ID.
Bicep compilation alone cannot verify whether an `existing` assignment exists in Azure.

## 9. Prepare service-connection access for operator approval

```text
Inspect the actual plan/apply service connections and propose least-privilege permissions
for their real operations. Do not grant roles yet.
Resolve managed identity clientId versus principalId/object ID. Show commands using
placeholders, never assume a client ID is valid for --assignee-object-id.
Verify the intended assignment scope actually contains the target subscriptions before
relying on management-group inheritance. Diagnose missing subscriptions/read separately
from authentication failure.
Describe the historical Owner-on-three-subscriptions workaround as context, not a default
recommendation. Require explicit access approval and validation as the actual pipeline
identities; do not use an administrator's successful context switch as proof.
```

**Gate:** approved identities, scopes, plan/apply role split, federation, and verification
procedure. IAM changes and credential provisioning are separate operator-controlled actions.

## 10. Validate without deploying

```text
Parse all generated JSON/JSONC/YAML using their appropriate parsers.
Compile all Bicep and parameter files, including disabled/inactive paths, with the selected
Bicep version and public module restore as needed. Put outputs outside source control.
Report errors and warning categories; do not hide failures or rewrite unrelated code.
Programmatically verify single-region arrays/hub counts, networking flags, pipeline
defaults, telemetry values, unique subscription placement, exact per-group policy
partition/counts, absence of policy location overrides, and RBAC exclusion consistency.
Check documentation links and placeholder handling. Explain which checks are static only.
Run the generated CI workflow after repository/service connections are configured.
Prepare the approved pipeline's What-If/validation stage with skip_what_if=false, but do
not run a deployment implicitly. Review stack action-on-unmanage, deletes, existing policy
locations, and subscription moves with the owner before live execution.
```

Local compilation examples (PowerShell; run from the generated configuration directory):

```powershell
$output = Join-Path ([System.IO.Path]::GetTempPath()) ("alz-check-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $output -ErrorAction Stop | Out-Null
$index = 0
Get-ChildItem -LiteralPath .\templates -Recurse -Filter *.bicep | ForEach-Object {
  $index++
  az bicep build --file $_.FullName --outfile (Join-Path $output "template-$index.json")
  if ($LASTEXITCODE -ne 0) { throw "Bicep build failed: $($_.FullName)" }
}
Get-ChildItem -LiteralPath .\templates -Recurse -Filter *.bicepparam | ForEach-Object {
  $index++
  az bicep build-params --file $_.FullName --outfile (Join-Path $output "params-$index.json")
  if ($LASTEXITCODE -ne 0) { throw "Bicep parameter build failed: $($_.FullName)" }
}
```

Record results and remove only the exact temporary output directory created above after
inspection. These commands do not validate live resources, private subscriptions, identity
hosting, target SKU support, or external pipeline semantics.

**Gate:** no compilation/parser failures, semantic checks passed, warnings disclosed.
For a configured private copy, no subscription sentinels or required-input placeholders
remain in deployable inputs. Documentation may retain explicitly marked examples.

## 11. Execute only after separate approval and capture the outcome

```text
Prepare an operator checklist, not an automatic deployment. Include approved What-If,
stack deletion/unmanage settings, subscription moves, parent-before-child hierarchy order,
source-policy-before-RBAC order, network resources, and rollback limitations.
Keep logging/Security deferred according to the approved profile. After separately approved
execution, verify actual stack/resource results, subscription parents, policy enforcement
modes, excluded assignments, VPN/DNS configuration, and least-privilege role grants.
Do not claim success based only on a green compile or pipeline task.
Create a dated decision record with evidence, affected files, risk owner, and restoration
conditions for each remaining workaround. Record actual generator/module/template versions.
```

**Gate:** deployment evidence and explicit acceptance of missing logging/security/enforcement
capabilities. Production readiness is a separate decision.

## 12. Produce a shareable handover

```text
In a separate shareable copy replace customer subscription/tenant/principal/client IDs,
private project/repository URLs, identity/service-connection names, contacts, and user paths
with a documented consistent placeholder scheme. Scan full resource IDs and historical
docs too. Preserve public policy/role GUIDs and public module constants.
Inspect bundled policy defaults as well: retain their all-zero dummy subscription IDs,
but do not assume every GUID in a library file is public/non-sensitive. If a built-in role
reference contains a real subscription prefix, use the equivalent subscription-neutral
/providers/Microsoft.Authorization/roleDefinitions/<same-built-in-role-guid> form after
verifying it is a built-in role, not a subscription-scoped custom role.
Do not keep a reverse mapping, raw logs, or credential-bearing scanner output in that copy.
Check hidden files, archives, build artifacts, and any Git history separately.
Follow the sharing-and-placeholders guide and run the approved secret scanner.
Deliver architecture/decision documentation plus this step-by-step reproduction workflow,
with validation evidence and unresolved limitations. Do not publish automatically.
```

**Gate:** reviewed, sanitized file set and no deployment claimed for the sanitized inputs.
