# Saudi Arabia East Landing Zone: Implementation and Handover

## 1. Purpose, evidence, and boundaries

This guide records how this Azure Landing Zones (ALZ) accelerator-generated Bicep
configuration was adapted for `saudiarabiaeast`. It describes the **files as configured on
2026-11-17**, not a promise of current regional availability or proof of a complete successful
deployment. Regional errors and RBAC changes below were recorded during 2026-11-16/17;
this handover preparation did not query or change the live environment.

The source of truth is the Bicep/parameter/YAML configuration. Existing decision notes record
intermediate investigations; the final matrix in section 5 supersedes older rollout counts.
The precise accelerator generator version, pristine baseline diff, and external pipeline
template commit were not supplied in this directory. Do not invent them. Capture those
versions when reproducing this work.

Before sharing or using this configuration, read the
[placeholder contract](sharing-and-placeholders.md). To apply the decisions to a fresh
accelerator output, use the [Copilot reproduction runbook](copilot-reproduction-runbook.md).

## 2. Intended topology

```text
Tenant Root
  alz
    platform
      management    -> Management subscription
      connectivity  -> Connectivity subscription
      identity      -> Identity subscription
      security      -> deferred; pipeline step off; no subscription placement
    landingzones
      corp
      online
      local
    sandbox
    decommissioned
```

The tree is the desired configuration, not a fresh inventory of deployed management groups.
Application subscription placement is not populated in this example. The root and platform
parent groups do not also place the three subscriptions; each platform child owns its own
placement.

| Area | Effective configuration |
|---|---|
| Deployment technology | Bicep, AVM modules, Azure DevOps YAML delegating to an external template repository |
| Active network topology | `NETWORK_TYPE = hubNetworking`; only `networking-hubnetworking` is exposed in CD |
| Resource region | `saudiarabiaeast`; one entry in every declared `parLocations` array |
| Stack tracking location | `parameters.json` `LOCATION = uaenorth`; distinct from resource placement |
| Secondary region | None; second hubs and their inter-hub peering removed |
| Platform subscriptions | Management, Connectivity, Identity; Security deferred |
| Policy posture | 30 configured assignment occurrences in `DoNotEnforce`; 93 excluded |
| Logging/security | Core-Logging step off, no Sentinel onboarding, related policy exclusions |
| Telemetry | AVM usage telemetry off in all 18 parameter files |

Single-region means **regional workload/resource placement**, not all metadata remaining
within Saudi Arabia. Deployment-stack metadata is deliberately hosted in UAE North; Private
DNS zones and management groups are global resources. This is not a data-residency
certification. Approve metadata placement and external control-plane dependencies explicitly.

## 3. Decision register

| Decision | Implemented change | Reason/evidence recorded | Consequence / restoration gate |
|---|---|---|---|
| Single region | Remove empty secondary region/hub; disable hub peering | Generated two-region configuration included an empty second location | No regional DR. Restore only with approved region, address, peering, and DNS design |
| Defer logging | `core-logging` default `false`; exclude dependent policy assignments and RBAC lookups | Log Analytics unavailable in the recorded target rollout | No central logging deployed by this step. Validate workspace/DCR/identity dependencies before restoration |
| Observe, do not enforce | Explicit exact-name `managementGroupDoNotEnforcePolicyAssignments` lists | Initial rollout needs non-blocking compliance observation | Remaining policies do not provide normal enforcement; explicit approval needed before production |
| Restrict network services | Disable Firewall, Bastion, DDoS plan, ExpressRoute gateway | Not on the supplied confirmed foundational-services list; this is conservative deferral, not universal proof of unsupported service | No managed firewall inspection, Bastion access path, dedicated DDoS plan, or ER gateway from this template |
| Defer DNS Private Resolver | Disable resolver in both networking parameter files; leave Private DNS on | Recorded provider metadata omitted region for resolver and endpoints | No managed hybrid DNS forwarding path |
| Fix DNS module region mapping | Pin `avm/ptn/network/private-link-private-dns-zones:0.7.4` in both network templates | `0.7.2` lacked `saudiarabiaeast`; decision record attributes mapping to `0.7.3` | Keep `0.7.4` for reproduction; assess compatibility before changing a newer baseline |
| Defer Defender policies | Exclude nine assignment occurrences across root, Platform, Landing Zones | Recorded security-service availability decision | No compliance evaluation from excluded benchmark/Defender assignments |
| Defer Security subscription | CD switch off; placement `[]`; root Security ID `""` | No dedicated Security subscription; original Management ID conflicted | Separate organizational decision from Sentinel availability |
| Correct pipeline permissions | Historical direct Azure RBAC change; not encoded here | Service-connection principals could authenticate but lacked subscription read | Resolve principal object IDs; approve least-privilege roles rather than blindly repeating Owner |
| Relocate stack metadata | Root `LOCATION = uaenorth`, resource locations unchanged | `NoRegisteredProviderFound` for deploymentStacks despite provider metadata advertising the region | Stale front-end/cache explanation is a hypothesis; external templates must be inspected before reuse |
| Disable AVM telemetry | `parEnableTelemetry = false` in all 18 parameter files | `LocationNotAvailableForDeployment` for telemetry deployment resources | Does not turn off application monitoring; logging deferral is a separate change |
| Defer identity-bearing policy assignments | Root two plus 64 additional exclusions; synchronize cross-MG RBAC | `IdentityServiceUnavailable` for policy assignment identities | Avoid new off-region policy identity placement, but lose policy coverage until restoration |

Detailed decision records:
[single region](single-region-deployment.md),
[logging](core-logging-disabled.md),
[policy rollout](policy-audit-only-rollout.md),
[network](network-service-region-limitations.md),
[security services](security-service-region-limitations.md),
[Security subscription](security-subscription-deferred.md),
[pipeline RBAC](pipeline-service-connection-rbac-fix.md),
[stack metadata](deployment-stack-location-workaround.md),
[AVM telemetry](avm-telemetry-disabled.md),
[identity exclusions](policy-assignment-identity-unavailable-exclusions.md).

## 4. File-level implementation

### Global inputs and pipelines

- [parameters.json](../parameters.json): three subscription placeholders, empty Security
  and secondary region, `NETWORK_TYPE = hubNetworking`, `LOCATION_PRIMARY = saudiarabiaeast`,
  metadata `LOCATION = uaenorth`. This file is consumed by the recorded external pipeline;
  it does not automatically populate Bicep parameter files.
- [CD pipeline](../.pipelines/cd.yaml): `core-logging` and `governance-platform-security`
  default `false`; remaining exposed deployment steps default `true`; `skip_what_if`
  defaults `false`. A queue-time override can enable a deferred step, so review run inputs.
- [CI pipeline](../.pipelines/ci.yaml): references the same external repository.
  This wrapper contains no build tasks itself; inspect the external CI implementation and
  trigger behavior rather than assuming it provides complete validation.
- Both wrappers extend `.pipelines/*-template.yaml@templates`. These external files, their
  dependencies/order, service-connection bindings, stack deletion settings, and handling of
  `LOCATION` are **not included**. Review and version them in each new environment.

### Networking

The active [hub parameters](../templates/networking/hubnetworking/main.bicepparam) retain one
`vnet-alz-saudiarabiaeast` hub with `10.0.0.0/22`. Reserved subnets for gateways, Bastion,
Firewall, and DNS resolver remain; resolver delegations remain as well. Reserved subnets do
not mean their services are deployed.

| Setting on the surviving hub | Value |
|---|---|
| `deployPeering` | `false` |
| `azureFirewallSettings.deployAzureFirewall` | `false` |
| `bastionHostSettings.deployBastion` | `false` |
| `ddosProtectionPlanSettings.deployDdosProtectionPlan` | `false` |
| `expressRouteGatewaySettings.deployExpressRouteGateway` | `false` |
| `privateDnsSettings.deployDnsPrivateResolver` | `false` |
| `privateDnsSettings.deployPrivateDnsZones` | `true` |
| `vpnGatewaySettings.deployVpnGateway` | `true` |

VPN configuration remains `VpnGw1AZ`, `activeActiveBgp`, `RouteBased`, ASN `65515`.
An enabled service flag is not proof of regional SKU/zone/capacity support; validate the
specific configuration before deployment.

The [hub template](../templates/networking/hubnetworking/main.bicep) already conditions
Firewall policy, route tables, public IP dependencies, and Bastion NSG on their service flags.
DNS resolver modules/resource groups are separately conditional. The Private DNS pattern
uses `0.7.4`; `privateDnsZones: []` retains the pinned module's default zone-list behavior,
not an instruction to create zero zones. Inspect resolved module defaults when upgrading.

The inactive [Virtual WAN parameters](../templates/networking/virtualwan/main.bicepparam)
also retain one hub and the same deferred-service posture. Unlike the active hub, their
S2S/P2S VPN flags remain `false`. Do not deploy both topologies together or imply that Virtual
WAN service support was verified. Its
[template](../templates/networking/virtualwan/main.bicep) has the same Private DNS pattern pin.

### Logging and security

[Logging parameters](../templates/core/logging/main.bicepparam) are preserved for later use.
They specify `parDeployAutomationAccount = false`, a Log Analytics workspace, DCR names,
and `parLogAnalyticsWorkspaceSolutions = ['ChangeTracking']`; `SecurityInsights` is absent.
The entire step is disabled. Re-enabling the pipeline step alone does not enable the
Automation Account or Sentinel.

Policy parameter overrides still contain intended workspace, DCR, managed identity, DNS,
and DDoS resource IDs, now with placeholder subscription IDs. Keep those names consistent
with resource templates. An override for an excluded assignment is inactive, not proof the
referenced resource exists.

### Governance and identity

The [shared core type](../templates/core/alzCoreType.bicep) and governance wrappers already
support exclusion and DoNotEnforce lists. Existing hooks were used rather than rewriting the
policy library's effects. Exact assignment **names**, not display names, are required.

For sharing, the bundled `Deploy-Custom-Route-Table` definition's Network Contributor
role reference was made subscription-neutral by removing a hardcoded subscription prefix.
The built-in role GUID and permissions were preserved; no policy effect was changed.

The root `Deploy-SvcHealth-BuiltIn` and `Enforce-ACSB` are now excluded. An earlier broad
`uaenorth` policy-location override was reverted after `InvalidLocationUpdate`; there is
**no active policy-assignment location override** in the final parameter configuration.
Existing off-region assignments, if any, need live inventory and stack action-on-unmanage
review before removal. A file exclusion alone does not prove Azure deleted a resource.

Additional identity exclusions: Landing Zones 32, Corp 1, Platform 28, Connectivity 1,
Identity 1, Decommissioned 1 = **64**. Together with root's two these are **66 deferrals
specifically added for identity availability**. Logging/security exclusions also include
identity-bearing policies; these reason categories overlap and must not be blindly summed
as unique policy names.

Cross-management-group RBAC must not resolve identities for excluded source policies:

| RBAC parameter file | Source assignment dependency to skip |
|---|---|
| [Platform RBAC](../templates/core/governance/mgmt-groups/platform/main-rbac.bicepparam) | Connectivity `Enable-DDoS-VNET` |
| [Landing Zones RBAC](../templates/core/governance/mgmt-groups/landingzones/main-rbac.bicepparam) | Platform's seven logging-related assignments; Connectivity `Enable-DDoS-VNET` |
| [Connectivity RBAC](../templates/core/governance/mgmt-groups/platform/platform-connectivity/main-rbac.bicepparam) | Corp `Deploy-Private-DNS-Zones` |

The seven Platform names are `Deploy-VM-ChangeTrack`, `Deploy-VM-Monitoring`,
`Deploy-VMSS-ChangeTrack`, `Deploy-VMSS-Monitoring`, `Deploy-vmArc-ChangeTrack`,
`Deploy-vmHybr-Monitoring`, and `Deploy-MDFC-DefSQL-AMA`. These lists skip both existing
identity lookups and their dependent role grants. Restore source assignments before RBAC.

## 5. Final policy accounting

Counts are assignment **occurrences per management group**, resolved from the
`loadJsonContent(...alz_policy_assignment.json)` references in each governance `main.bicep`.
There are **123 declared occurrences / 80 unique names**, not 123 active assignments.

| Management-group folder | Declared | DoNotEnforce | Excluded (declared only) |
|---|---:|---:|---:|
| int-root | 17 | 6 | 11 |
| landingzones | 53 | 11 | 42 |
| landingzones-corp | 5 | 4 | 1 |
| landingzones-local | 1 | 1 | 0 |
| landingzones-online | 0 | 0 | 0 |
| platform | 40 | 4 | 36 |
| platform-connectivity | 1 | 0 | 1 |
| platform-identity | 4 | 3 | 1 |
| platform-management | 0 | 0 | 0 |
| platform-security | 0 | 0 | 0 |
| decommissioned | 1 | 0 | 1 |
| sandbox | 1 | 1 | 0 |
| **Total** | **123** | **30** | **93** |

Every declared assignment is in exactly one of the two lists; no declared assignment is left
enforced by default in this configuration. Root has **12 exclusion entries**, of which
`Deploy-AzSqlDb-Auditing` is a historical no-op: root does not load that assignment. Thus
there are 94 textual exclusion entries but only 93 excluded declared occurrences.
Keep this distinction when reproducing/checking counts; do not add no-op entries to a fresh
template just to match a number.

`DoNotEnforce` retains evaluation without normal automatic policy enforcement; it is not the
same as `effect: Disabled` or converting every policy to `Audit`. It also does not prevent an
operator from explicitly launching supported remediation tasks. Exclusion creates no new
assignment and provides **no compliance evaluation** for it. Inherited policies and policies
managed outside this repository must be reviewed separately.

## 6. Historical pipeline RBAC incident

The recorded `Set-AzContext` failure was caused by insufficient subscription-read permission,
not necessarily an invalid subscription/tenant. A similarly named Sovereign Landing Zone
role did not provide the permissions the ALZ pipeline required.

Both pipeline identities were user-assigned managed identities. Their client/application IDs
were initially passed as `--assignee-object-id`, producing ineffective role assignments.
Resolve the actual principal Object ID (`principalId` / service principal `id`) before grants.
For managed identities, `az identity show` can provide `clientId` and `principalId`;
`az ad sp show --id <client-id> --query id` is another read-only resolution path when Graph
permissions allow it.

The historical fix granted Owner directly on three platform subscriptions to both principals
before subscription placement under the ALZ hierarchy. That is a record, **not the recommended
default permission model for every recipient**. Separate plan and apply permissions, inspect
the actual pipeline operations, scope role grants, and obtain access approval. A grant on
`alz` cannot be inherited by subscriptions still outside that hierarchy. Validate access
under the actual federated pipeline identity, not only an administrator's session.

## 7. Deployment and acceptance sequence

1. Generate a new accelerator baseline and record generator/module/library/external-template
   versions. Work on a private branch/copy, preserving unrelated changes.
2. Configure approved inputs using the [placeholder guide](sharing-and-placeholders.md).
   Verify region access, provider registration, API versions, service SKUs, zones, and capacity
   in the actual subscriptions. Provider metadata alone is not sufficient proof of deployability.
3. Inspect the external pipelines: confirm `LOCATION` semantics, dependency ordering,
   service-connection identities, What-If behavior, approvals, and stack action-on-unmanage.
   Never assume exclusion is a harmless change to an already-managed resource.
4. Parse configuration and compile **all** templates and parameter files, including deferred
   logging, Security, RBAC, and inactive Virtual WAN. Compilation checks syntax/types, not
   live region/identity support or existence of referenced resources.
5. Run the generated CI workflow. Use external CD What-If/validation without skipping it.
   Review proposed creates, deletes, management-group moves, policy removals, and role changes.
   Where stack tooling cannot provide a full preview, explicitly document the limitation.
6. Obtain approval before live changes. Deploy hierarchy parents before children, source
   policy assignments before dependent RBAC, and resources before restoring policies that
   reference them. Ensure the actual pipeline handles any cross-branch ordering (e.g. Corp
   policy before Connectivity RBAC). Keep logging/Security deferred for this baseline.
7. Verify stack/resource provisioning results, subscription parent groups, network/VPN/zone
   resources, policy `enforcementMode`, exclusions, and RBAC with the actual deployment identity.
   If fresh region behavior differs, stop and update the decision evidence rather than
   widening permissions or moving resources out of region automatically.
8. Record outcomes, unresolved compliance gaps, owners, and restoration review dates in a
   private operational record. A green build/pipeline alone is not production acceptance.

No commands in this guide authorize live deployment or IAM changes. Use your generated
pipeline and approved operational procedure.

## 8. Restoration and alternatives

Restore one capability at a time, supported by current evidence and approved What-If:

1. **Network service:** verify exact resource/SKU/API support; enable its flag; review routes,
   DNS dependencies, and monitoring. Reserved subnets reduce re-planning but do not guarantee
   successful provisioning.
2. **Logging:** verify workspace, DCR, identity, and any chosen Automation requirements;
   deploy resources first, update resource-ID overrides, then restore dependent assignments
   and RBAC lookups only after *all* blocking reasons are resolved.
3. **Policy identities:** test a representative assignment in-region with approval; inventory
   pre-existing assignments and locations. Restore exclusions gradually with DoNotEnforce
   first, then restore dependent cross-MG role grants. Do not reset whole lists indiscriminately.
4. **Defender / Sentinel:** validate each product independently. Defender policies also need
   their logging/identity dependencies; Sentinel needs an enabled workspace and explicit
   `SecurityInsights` onboarding. Adding Security alone enables neither product.
5. **Security subscription:** provision a distinct subscription, populate both root input and
   placement array, approve bootstrap permissions, then enable its management-group step.
6. **Enforcement:** review compliance findings and remediation plans, get owner approval, and
   remove selected DoNotEnforce entries. Do not launch remediation as an accidental side effect.
7. **Stack metadata / telemetry:** retest `saudiarabiaeast` for each affected resource type.
   Plan stack metadata relocation with the actual tool's supported lifecycle; editing a location
   string is not proof of an in-place migration. AVM usage telemetry is optional even afterward.
8. **Second region:** treat as an architecture change requiring data-residency, DR, routing,
   address, and policy review, not merely filling `LOCATION_SECONDARY`.

[User-assigned policy identities](policy-assignment-user-assigned-identity-option.md) remain
an **unimplemented experiment**. The wrapper can pass identity settings, but automatic
SystemAssigned role grants do not automatically carry over. Location behavior, RBAC,
identity placement, blast radius, lifecycle, and existing-assignment migration must be tested
and approved before adoption.

For rollback, revert only your intended configuration changes in version control and review
the resulting stack behavior; do not delete/recreate stacks, policies, identities, or role
assignments blindly. A template rollback does not automatically reverse external IAM changes,
subscription moves, or data loss from a previous deployment.

## 9. Upstream references

- [ALZ accelerator planning](https://azure.github.io/Azure-Landing-Zones/accelerator/0_planning/)
- [Azure Policy enforcement mode](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/assignment-structure#enforcement-mode)
- [Policy managed identities and remediation](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources)
- [Deployment stacks](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks)
- [AVM telemetry](https://aka.ms/avm/TelemetryInfo)
- [Private DNS pattern 0.7.4 source](https://github.com/Azure/bicep-registry-modules/tree/avm/ptn/network/private-link-private-dns-zones/0.7.4/avm/ptn/network/private-link-private-dns-zones)

Upstream pages and service availability evolve; use pinned source and target-subscription
evidence when reproducing the recorded configuration.

## 10. Shareable-copy validation evidence

Local validation on 2026-11-17 used Azure CLI `2.93.0`, Bicep CLI `0.49.2`,
Python `3.14.7`, and an isolated PyYAML `6.0.3` parser:

- All **19 Bicep templates and 18 parameter files compiled successfully**. The root
  governance template and parameters were recompiled after normalizing the bundled
  built-in role reference.
- **323 strict JSON files, one JSONC Bicep configuration, and two YAML files** parsed.
- Static checks verified the policy matrix/partition, no active SystemAssigned policy
  assignments, the three cross-MG RBAC exclusion sets/guards, subscription placeholder
  placement, pipeline defaults, single-region arrays/hubs, network flags, telemetry,
  and Private DNS module versions.
- **144 relative documentation file/anchor links** were checked.
- Bounded scans found no remaining known original environment IDs/fragments or non-placeholder
  subscription references. The upstream library's all-zero defaults and fictitious
  example contacts were intentionally retained. This is not a substitute for an approved
  secret scanner or a review of external repositories/history.
- The initial full compilation emitted **121 warnings**: 75 `use-recent-module-versions`,
  20 `use-recent-api-versions`, 20 `BCP318` nullable-access warnings, and 6 `no-unused-types`.
  Compilation success is not a warning-free or runtime-safety certification; review these
  diagnostics against the recipient's baseline without broad unrelated upgrades.

No Azure deployment, availability recheck, IAM mutation, subscription move, pipeline
execution, or external-template validation was performed for this shareable handover.
The placeholder-bearing copy must not be deployed unchanged.
