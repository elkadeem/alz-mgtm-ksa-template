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

param platformConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'platform'
  managementGroupParentId: 'alz'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Platform'
  // TEMP AUDIT-ONLY (2026-11-16): remaining 4 policy assignments in this MG set to
  // DoNotEnforce for the initial Saudi Arabia East rollout (Deny/Modify/DeployIfNotExists
  // effects do not block or auto-remediate, but compliance is still evaluated/visible).
  // Re-enforce once validated — see docs/policy-audit-only-rollout.md.
  managementGroupDoNotEnforcePolicyAssignments: [
    'DenyAction-DeleteUAMIAMA'
    'Enforce-ASR'
    'Enforce-GR-KeyVault'
    'Enforce-Subnet-Private'
  ]
  // TEMP DISABLED (2026-11-16): Core-Logging is off because Log Analytics is not available
  // in Saudi Arabia East yet. These assignments reference the logging workspace, DCRs, or
  // the logging managed identity. Remove these 7 entries once Core-Logging is re-enabled.
  // Also TEMP DISABLED (2026-11-16): Microsoft Defender for Cloud is not available in Saudi
  // Arabia East either. Deploy-GuestAttest exists solely to feed Azure Security Center/
  // Defender for Cloud attestation data, so it is excluded too — see
  // docs/security-service-region-limitations.md.
  // Also TEMP EXCLUDED (2026-11-17): the remaining 28 policy assignments below all use a
  // system-assigned managed identity, and Microsoft Entra regional resource identity hosting
  // does not support 'saudiarabiaeast' yet, so their creation fails with
  // IdentityServiceUnavailable. None of these existed in Azure prior to this change (verified),
  // so excluding them (rather than overriding the identity location to another region) avoids
  // a future delete/recreate migration once the region is supported — simply remove these
  // entries once Entra confirms regional identity hosting for 'saudiarabiaeast'. See
  // docs/policy-assignment-identity-unavailable-exclusions.md.
  managementGroupExcludedPolicyAssignments: [
    'Deploy-VM-ChangeTrack'
    'Deploy-VM-Monitoring'
    'Deploy-VMSS-ChangeTrack'
    'Deploy-VMSS-Monitoring'
    'Deploy-vmArc-ChangeTrack'
    'Deploy-vmHybr-Monitoring'
    'Deploy-MDFC-DefSQL-AMA'
    'Deploy-GuestAttest'
    'Enable-AUM-CheckUpdates'
    'Enforce-Encrypt-CMK0'
    'Enforce-GR-APIM0'
    'Enforce-GR-AppServices0'
    'Enforce-GR-Automation0'
    'Enforce-GR-BotService0'
    'Enforce-GR-CogServ0'
    'Enforce-GR-Compute0'
    'Enforce-GR-ContApps0'
    'Enforce-GR-ContInst0'
    'Enforce-GR-ContReg0'
    'Enforce-GR-CosmosDb0'
    'Enforce-GR-DataExpl0'
    'Enforce-GR-DataFactory0'
    'Enforce-GR-EventGrid0'
    'Enforce-GR-EventHub0'
    'Enforce-GR-KeyVaultSup0'
    'Enforce-GR-Kubernetes0'
    'Enforce-GR-MachLearn0'
    'Enforce-GR-MySQL0'
    'Enforce-GR-Network0'
    'Enforce-GR-OpenAI0'
    'Enforce-GR-PostgreSQL0'
    'Enforce-GR-ServiceBus0'
    'Enforce-GR-SQL0'
    'Enforce-GR-Storage0'
    'Enforce-GR-Synapse0'
    'Enforce-GR-VirtualDesk0'
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
  'Deploy-VM-ChangeTrack': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
      }
      userAssignedIdentityResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-VM-Monitoring': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
      }
      userAssignedIdentityResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-VMSS-ChangeTrack': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
      }
      userAssignedIdentityResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-VMSS-Monitoring': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
      }
      userAssignedIdentityResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-vmHybr-Monitoring': {
    parameters: {
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-MDFC-DefSQL-AMA': {
    parameters: {
      userWorkspaceResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
      dcrResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-mdfcsql-alz-${parLocations[0]}'
      }
      userAssignedIdentityResourceId: {
        value: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
      }
    }
  }
  'DenyAction-DeleteUAMIAMA': {
    parameters: {
      resourceName: {
        value: 'mi-alz-${parLocations[0]}'
      }
    }
  }
}
