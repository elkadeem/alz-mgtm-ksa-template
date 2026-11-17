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

param landingZonesOnlineConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'online'
  managementGroupParentId: 'landingzones'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Online'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
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

// Currently no policy assignments for online landing zones
// When policies are added, specify parameter overrides here
param parPolicyAssignmentParameterOverrides = {
  // No policy assignments in landing zones - online currently
}
