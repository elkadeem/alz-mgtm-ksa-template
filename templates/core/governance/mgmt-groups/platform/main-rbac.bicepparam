using './main-rbac.bicep'

param parPlatformManagementGroupName = 'platform'
param parConnectivityManagementGroupName = 'connectivity'
// Keep in sync with platform-connectivity/main.bicepparam: the excluded policy has no identity
// to grant RBAC to. Remove together when regional identity hosting is supported.
param parManagementGroupExcludedPolicyAssignments = [
  'Enable-DDoS-VNET'
]
// REGION LIMITATION (2026-11-17): disabled because the AVM module's standard telemetry
// resource (Microsoft.Resources/deployments) is explicitly created with location = parLocations[0],
// and 'saudiarabiaeast' is not yet a supported location for that resource type (confirmed via
// az provider show --namespace Microsoft.Resources, resourceType 'deployments'). This causes a
// LocationNotAvailableForDeployment error on every AVM module call. See
// docs/avm-telemetry-disabled.md. Telemetry is purely anonymous Microsoft usage tracking with
// zero effect on deployed resources - safe to disable.
param parEnableTelemetry = false
