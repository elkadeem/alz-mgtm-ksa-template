# Policy Assignment Identities in UAE North

## Status

Configured on 2026-11-17 for operator testing; **not deployed or verified in Azure**.
This supersedes the [identity-only exclusions](policy-assignment-identity-unavailable-exclusions.md).

The 66 assignment occurrences previously deferred specifically for identity availability
are restored as `DoNotEnforce`, with a per-assignment `location: 'uaenorth'` override.
They retain `SystemAssigned` identities; no shared user-assigned identity is introduced.

| Management-group folder | Restored occurrences |
|---|---:|
| int-root | 2 |
| landingzones | 32 |
| landingzones-corp | 1 |
| platform | 28 |
| platform-connectivity | 1 |
| platform-identity | 1 |
| decommissioned | 1 |
| **Total** | **66** |

## Location semantics

Microsoft documents that the managed identity's location
[does not affect its operation with Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources).
Assignment scope, policy conditions, exclusions, and resource selectors determine which
resources are evaluated, not the assignment's identity-hosting region.

- `parLocations = ['saudiarabiaeast']` remains unchanged.
- Only the selected assignment locations are overridden through the existing
  `parPolicyAssignmentParameterOverrides` hook. Other assignments retain their locations.
- Policy parameters, resource IDs, and remediation target locations are unchanged.
  Remediation placement is determined by the policy definition/template and its parameters.
- Deployment Stack metadata location is a separate existing workaround.
- This is an explicit off-region identity placement exception, not a second workload/DR region.
  Obtain any required data-residency and identity-placement approval before deployment.

The [assignment location cannot be changed in place](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/assignment-structure#identity).
The earlier broad override failed with `InvalidLocationUpdate`; do not repeat it for all
assignments. Keeping these selected assignments in UAE North is possible long-term.
Moving them back to Saudi Arabia East later is optional and requires a planned
delete/recreate operation, new system-assigned principal IDs, and updated RBAC.

## Preserved limitations and RBAC

Logging/security exclusions remain intact: the configuration now has **96 DoNotEnforce
and 27 excluded declared occurrences** out of 123. Root retains one extra, undeclared
`Deploy-AzSqlDb-Auditing` exclusion (a historical no-op), so there are 28 textual exclusions.

The separate RBAC parameters now permit Connectivity's `Enable-DDoS-VNET` identity in
Platform and Landing Zones, and Corp's `Deploy-Private-DNS-Zones` identity in Connectivity.
Landing Zones still excludes the seven Platform logging-policy identity lookups.
Deploy each source assignment before its dependent cross-management-group RBAC stage.
Automatic same-scope role grants continue through the existing SystemAssigned module path.

`Enable-DDoS-VNET` is restored for evaluation in both groups, but the referenced DDoS plan
is still disabled/absent. Expect dependency-related noncompliance; do not enforce it or start
remediation until an approved plan exists and its resource ID is configured.
Likewise, assess each restored policy's actual service/resource dependencies before enforcement.

`DoNotEnforce` suppresses normal automatic effects, but still evaluates compliance and
**does not block manually initiated remediation tasks**. Do not start remediation during
the initial identity/location test.

## Operator test procedure

Local validation passed: all 10 changed parameter files compiled with Bicep `0.49.2`
and `--no-restore`; static assertions confirmed the counts above, exact override scope,
unchanged existing workload parameters, Saudi-only `parLocations`, and RBAC exclusions.
Compilation reported 30 warnings (module/API recency and nullable access); no Azure
deployment or compliance evaluation was performed.

1. Replace shared placeholders in a private deployment copy and confirm permission to use
   `uaenorth`. Confirm the external pipeline orders source assignments before RBAC.
2. Inventory existing assignments at all seven source management groups, especially root.
   For example, in PowerShell:

   ```powershell
   $scope = '/providers/Microsoft.Management/managementGroups/alz'
   az policy assignment list --scope $scope --query "[].{name:name,location:location,identity:identity.type,enforcementMode:enforcementMode,principalId:identity.principalId}" --output table
   ```

   Confirm the actual assignment scope when reviewing inherited results. For an exact lookup,
   use `az policy assignment show --name <assignment-name> --scope <source-management-group-scope>`.
   Existing selected assignments must already use `uaenorth`, or require an explicitly
   approved migration. Do not automatically delete a conflicting assignment. Review stack
   ownership, deny settings, action-on-unmanage, exemptions, and RBAC before migration.
3. Run the existing pipeline plan/What-If and check that only the intended assignment,
   enforcement-mode, and dependent RBAC changes appear. Workload resources must not relocate.
   A successful compile/What-If does not prove regional identity creation works.
4. Deploy the governance source assignments, then dependent RBAC, using the existing pipeline.
5. Verify all 66 selected occurrences have `location = uaenorth`,
   `identity.type = SystemAssigned`, a nonempty `principalId`, and
   `enforcementMode = DoNotEnforce`. Confirm there is no `IdentityServiceUnavailable` or
   `InvalidLocationUpdate`. Check required role grants, including cross-MG grants.
6. Wait for policy evaluation or request an evaluation scan in the target subscriptions.
   Confirm compliance results appear for restored assignments. Investigate missing
   dependencies separately; noncompliance is not necessarily a failure of this workaround.
7. Leave enforcement disabled until policy owners approve each assignment's dependencies
   and observed behavior.

## Rollback

Do not treat reverting parameters as a harmless rollback after deployment: returning an
assignment to exclusions can remove it or detach it according to stack settings and can
remove compliance coverage. Review live state and stack lifecycle first. Never remove the
location overrides from already-created assignments without a planned migration, because
the default would attempt to change their immutable location to `saudiarabiaeast`.
