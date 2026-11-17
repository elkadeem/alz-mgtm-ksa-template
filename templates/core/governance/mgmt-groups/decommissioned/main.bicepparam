using './main.bicep'

// General Parameters
// SINGLE-REGION DEPLOYMENT (2026-11-16): only saudiarabiaeast is deployed to.
param parLocations = [
  'saudiarabiaeast'
]
// REGION LIMITATION (2026-11-17): disabled because the AVM module's standard telemetry
// resource (Microsoft.Resources/deployments) is explicitly created with location = parLocations[0],
// and 'saudiarabiaeast' is not yet a supported location for that resource type (confirmed via
// az provider show --namespace Microsoft.Resources, resourceType 'deployments'). This causes a
// LocationNotAvailableForDeployment error on every AVM module call. See
// docs/avm-telemetry-disabled.md. Telemetry is purely anonymous Microsoft usage tracking with
// zero effect on deployed resources - safe to disable.
param parEnableTelemetry = false

param decommissionedConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'decommissioned'
  managementGroupParentId: 'alz'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Decommissioned'
  // TEMP AUDIT-ONLY (2026-11-16): set to DoNotEnforce for the initial Saudi Arabia East
  // rollout. Re-enforce once validated — see docs/policy-audit-only-rollout.md.
  managementGroupDoNotEnforcePolicyAssignments: []
  // TEMP EXCLUDED (2026-11-17): Enforce-ALZ-Decomm uses a system-assigned managed identity,
  // and Microsoft Entra regional resource identity hosting does not support 'saudiarabiaeast'
  // yet, so its creation fails with IdentityServiceUnavailable. It did not exist in Azure prior
  // to this change, so excluding it avoids a future delete/recreate migration once the region
  // is supported — simply remove this entry once Entra confirms regional identity hosting for
  // 'saudiarabiaeast'. See docs/policy-assignment-identity-unavailable-exclusions.md.
  managementGroupExcludedPolicyAssignments: [
    'Enforce-ALZ-Decomm'
  ]
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: []
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 10
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 10
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 10
  waitForConsistencyCounterBeforePolicyAssignments: 40
  waitForConsistencyCounterBeforeRoleAssignments: 40
  waitForConsistencyCounterBeforeSubPlacement: 10
}

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  // Add parameter overrides here if needed for customization
}
