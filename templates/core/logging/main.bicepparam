using 'main.bicep'

// General Parameters
// SINGLE-REGION DEPLOYMENT (2026-11-16): only saudiarabiaeast is deployed to.
param parLocations = [
  'saudiarabiaeast'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
// REGION LIMITATION (2026-11-17): disabled because the AVM module's standard telemetry
// resource (Microsoft.Resources/deployments) is explicitly created with location = parLocations[0],
// and 'saudiarabiaeast' is not yet a supported location for that resource type (confirmed via
// az provider show --namespace Microsoft.Resources, resourceType 'deployments'). This causes a
// LocationNotAvailableForDeployment error on every AVM module call. See
// docs/avm-telemetry-disabled.md. Telemetry is purely anonymous Microsoft usage tracking with
// zero effect on deployed resources - safe to disable.
param parEnableTelemetry = false

// Resource Group Parameters
param parMgmtLoggingResourceGroup = 'rg-alz-logging-${parLocations[0]}'

// Automation Account Parameters
param parAutomationAccountName = 'aa-alz-${parLocations[0]}'
param parAutomationAccountLocation = parLocations[0]
param parDeployAutomationAccount = false
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'law-alz-${parLocations[0]}'
param parLogAnalyticsWorkspaceLocation = parLocations[0]
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceDailyQuotaGb = null
param parLogAnalyticsWorkspaceReplication = null
param parLogAnalyticsWorkspaceFeatures = null
param parLogAnalyticsWorkspaceDataExports = null
param parLogAnalyticsWorkspaceDataSources = null
param parLogAnalyticsWorkspaceSolutions = [
  'ChangeTracking'
]

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-alz-${parLocations[0]}'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-alz-${parLocations[0]}'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-alz-${parLocations[0]}'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-alz-${parLocations[0]}'
