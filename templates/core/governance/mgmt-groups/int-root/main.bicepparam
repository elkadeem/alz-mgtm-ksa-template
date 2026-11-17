using './main.bicep'

// General Parameters
// Workload region remains saudiarabiaeast; selected policy identities use uaenorth.
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

param intRootConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'alz'
  managementGroupParentId: ''
  managementGroupDisplayName: 'Azure Landing Zones'
  // TEMP AUDIT-ONLY (2026-11-17): 8 policy assignments in this MG set to
  // DoNotEnforce for the initial Saudi Arabia East rollout (Deny/Modify/DeployIfNotExists
  // effects do not block or auto-remediate, but compliance is still evaluated/visible).
  // Re-enforce once validated — see docs/policy-audit-only-rollout.md.
  managementGroupDoNotEnforcePolicyAssignments: [
    'Audit-ResourceRGLocation'
    'Audit-TrustedLaunch'
    'Audit-UnusedResources'
    'Audit-ZoneResiliency'
    'Deny-Classic-Resources'
    'Deny-UnmanagedDisk'
    'Deploy-SvcHealth-BuiltIn'
    'Enforce-ACSB'
  ]
  // TEMP DISABLED (2026-11-16): Core-Logging is off because Log Analytics is not available
  // in Saudi Arabia East yet. These assignments reference the logging workspace/DCRs and
  // would fail compliance otherwise. Remove these 4 entries once Core-Logging is re-enabled.
  // Also TEMP DISABLED (2026-11-16): Microsoft Defender for Cloud and Microsoft Defender for
  // Endpoint are not available in Saudi Arabia East either, per the confirmed foundational/
  // security services list. These 6 assignments configure or depend on those products and
  // are excluded until they become available — see
  // docs/security-service-region-limitations.md.
  managementGroupExcludedPolicyAssignments: [
    'Deploy-MDFC-Config-H224'
    'Deploy-AzActivity-Log'
    'Deploy-Diag-LogsCat'
    'Deploy-AzSqlDb-Auditing'
    'Deploy-ASC-Monitoring'
    'Deploy-MCSB2-Monitoring'
    'Deploy-MDEndpoints'
    'Deploy-MDEndpointsAMA'
    'Deploy-MDFC-OssDb'
    'Deploy-MDFC-SqlAtp'
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
  // Identity-only location overrides; workload parameters remain in saudiarabiaeast.
  'Enforce-ACSB': {
    location: 'uaenorth'
  }
  'Deploy-MDFC-Config-H224': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
      emailSecurityContact: {
        value: 'security@example.com'
      }
      ascExportResourceGroupName: {
        value: 'rg-alz-asc-${parLocations[0]}'
      }
      ascExportResourceGroupLocation: {
        value: parLocations[0]
      }
    }
  }
  'Deploy-AzActivity-Log': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
      logsEnabled: {
        value: 'True'
      }
    }
  }
  'Deploy-Diag-LogsCat': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-SvcHealth-BuiltIn': {
    location: 'uaenorth'
    parameters: {
      resourceGroupLocation: {
        value: parLocations[0]
      }
      actionGroupResources: {
        value: {
          actionGroupEmail: ['triage@example.com']
          eventHubResourceId: []
          functionResourceId: ''
          functionTriggerUrl: ''
          logicappCallbackUrl: ''
          logicappResourceId: ''
          webhookServiceUri: []
        }
      }
    }
  }
  'Deploy-AzSqlDb-Auditing': {
    parameters: {
      logAnalyticsWorkspaceResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
    }
  }
}
