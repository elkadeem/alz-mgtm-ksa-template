using './main.bicep'

// General Parameters
// SINGLE-REGION DEPLOYMENT (2026-11-16): only saudiarabiaeast is deployed to. See
// docs/single-region-deployment.md for details and how to re-introduce a 2nd region/hub.
param parLocations = [
  'saudiarabiaeast'
]
param parTags = {}
// REGION LIMITATION (2026-11-17): disabled because the AVM module's standard telemetry
// resource (Microsoft.Resources/deployments) is explicitly created with location = parLocations[0],
// and 'saudiarabiaeast' is not yet a supported location for that resource type (confirmed via
// az provider show --namespace Microsoft.Resources, resourceType 'deployments'). This causes a
// LocationNotAvailableForDeployment error on every AVM module call. See
// docs/avm-telemetry-disabled.md. Telemetry is purely anonymous Microsoft usage tracking with
// zero effect on deployed resources - safe to disable.
param parEnableTelemetry = false
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}

// Resource Group Parameters
param parVirtualWanResourceGroupNamePrefix = 'rg-alz-conn'
param parDnsResourceGroupNamePrefix = 'rg-alz-dns'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-alz-dnspr'

// Virtual WAN Parameters
param vwan = {
  name: 'vwan-alz-${parLocations[0]}'
  location: parLocations[0]
  type: 'Standard'
  allowBranchToBranchTraffic: true
  lock: {
    kind: 'None'
    name: 'vwan-lock'
    notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
  }
}

// Virtual WAN Hub Parameters
param vwanHubs = [
  {
    hubName: 'vhub-alz-${parLocations[0]}'
    location: parLocations[0]
    addressPrefix: '10.0.0.0/22'
    allowBranchToBranchTraffic: true
    preferredRoutingGateway: 'ExpressRoute'
    azureFirewallSettings: {
      // REGION LIMITATION (2026-11-16): Azure Firewall is not on the confirmed Saudi Arabia
      // East foundational-services list. Disabled for now; re-enable once available. (This
      // Virtual WAN template is not currently wired into the deployment pipeline — hub
      // networking is the active topology — but kept consistent for when/if it is used.)
      deployAzureFirewall: false
      name: 'afw-alz-${parLocations[0]}'
    }
    expressRouteGatewaySettings: {
      // REGION LIMITATION (2026-11-16): the confirmed Saudi Arabia East foundational-services
      // list includes Azure ExpressRoute (circuits) but does not separately list ExpressRoute
      // Gateway, unlike Azure VPN Gateway which is explicitly listed. Disabled for now.
      deployExpressRouteGateway: false
      name: 'ergw-alz-${parLocations[0]}'
      minScaleUnits: 1
      maxScaleUnits: 1
      allowNonVirtualWanTraffic: false
    }
    s2sVpnGatewaySettings: {
      deployS2sVpnGateway: false
      name: 's2s-alz-${parLocations[0]}'
      scaleUnit: 1
    }
    p2sVpnGatewaySettings: {
      deployP2sVpnGateway: false
      name: 'p2s-alz-${parLocations[0]}'
      scaleUnit: 1
      vpnServerConfiguration: {
        vpnAuthenticationTypes: ['AAD']
      }
      vpnClientAddressPool: {
        addressPrefixes: ['172.16.0.0/24']
      }
    }
    ddosProtectionPlanSettings: {
      // REGION LIMITATION (2026-11-16): Azure DDoS Protection is not on the confirmed Saudi
      // Arabia East foundational-services list. Disabled for now; re-enable once available.
      deployDdosProtectionPlan: false
      name: 'ddos-alz-${parLocations[0]}'
      tags: {}
    }
    dnsSettings: {
      deployPrivateDnsZones: true
      // REGION LIMITATION (2026-11-17): DNS Private Resolver and its endpoints do not
      // advertise Saudi Arabia East support. Keep Private DNS zones enabled independently.
      deployDnsPrivateResolver: false
      privateDnsResolverName: 'dnspr-alz-${parLocations[0]}'
    }
    bastionSettings: {
      // REGION LIMITATION (2026-11-16): Azure Bastion is not on the confirmed Saudi Arabia
      // East foundational-services list. Disabled for now; re-enable once available.
      deployBastion: false
      name: 'bas-alz-${parLocations[0]}'
      sku: 'Standard'
    }
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[0]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '10.0.4.0/22'
      ]
    }
  }
  // SINGLE-REGION DEPLOYMENT (2026-11-16): the 2nd vwan hub (previously at parLocations[1])
  // was removed. See docs/single-region-deployment.md to re-add a 2nd hub.
]


