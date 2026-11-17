using './main.bicep'

// General Parameters
// SINGLE-REGION DEPLOYMENT (2026-11-16): only saudiarabiaeast is deployed to. See
// docs/single-region-deployment.md for details and how to re-introduce a 2nd region/hub.
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
param parHubNetworkingResourceGroupNamePrefix = 'rg-alz-conn'
param parDnsResourceGroupNamePrefix = 'rg-alz-dns'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-alz-dnspr'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${parLocations[0]}'
    location: parLocations[0]
    addressPrefixes: [
      '10.0.0.0/22'
    ]
    // No peering: single-region deployment has only one hub, so there is no remote hub to peer to.
    deployPeering: false
    dnsServers: []
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.0.64/26'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.0.128/27'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.0.0/26'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.0.0.192/26'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.0.0.160/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.0.0.176/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
    azureFirewallSettings: {
      // REGION LIMITATION (2026-11-16): Azure Firewall is not on the confirmed Saudi Arabia
      // East foundational-services list. Disabled for now; subnet/naming config kept intact
      // so it can be re-enabled by flipping this flag once the service is available.
      deployAzureFirewall: false
      azureFirewallName: 'afw-alz-${parLocations[0]}'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-alz-${parLocations[0]}'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-alz-${parLocations[0]}'
      }
    }
    bastionHostSettings: {
      // REGION LIMITATION (2026-11-16): Azure Bastion is not on the confirmed Saudi Arabia
      // East foundational-services list. Disabled for now; re-enable once available.
      deployBastion: false
      bastionHostSettingsName: 'bas-alz-${parLocations[0]}'
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
      deployVpnGateway: true
      name: 'vgw-alz-${parLocations[0]}'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      // REGION LIMITATION (2026-11-16): the confirmed Saudi Arabia East foundational-services
      // list includes Azure ExpressRoute (circuits) but does not separately list ExpressRoute
      // Gateway, unlike Azure VPN Gateway which is explicitly listed. Disabled for now;
      // Azure VPN Gateway above is unaffected and stays enabled.
      deployExpressRouteGateway: false
      name: 'ergw-alz-${parLocations[0]}'
    }
    privateDnsSettings: {
      deployPrivateDnsZones: true
      // REGION LIMITATION (2026-11-17): DNS Private Resolver and its endpoints do not
      // advertise Saudi Arabia East support. Keep Private DNS zones enabled independently.
      deployDnsPrivateResolver: false
      privateDnsResolverName: 'dnspr-alz-${parLocations[0]}'
      privateDnsZones: []
    }
    ddosProtectionPlanSettings: {
      // REGION LIMITATION (2026-11-16): Azure DDoS Protection is not on the confirmed Saudi
      // Arabia East foundational-services list. Disabled for now; re-enable once available.
      deployDdosProtectionPlan: false
      name: 'ddos-alz-${parLocations[0]}'
    }
  }
  // SINGLE-REGION DEPLOYMENT (2026-11-16): the 2nd hub (previously at parLocations[1]) was
  // removed along with its peering. See docs/single-region-deployment.md to re-add a 2nd hub.
]
