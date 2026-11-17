# Network Service Region Limitations (Saudi Arabia East)

## Status

**Temporarily disabled** since 2026-11-16.

DNS Private Resolver also disabled on 2026-11-17 after checking live Azure provider metadata.

## Context

A confirmed list of foundational Azure services available in `saudiarabiaeast` was provided.
Comparing it against what [hubnetworking/main.bicepparam](../templates/networking/hubnetworking/main.bicepparam)
(the active networking template — see [single-region-deployment.md](./single-region-deployment.md))
was configured to deploy, four services are **not** on the confirmed list:

- **Azure Firewall**
- **Azure Bastion**
- **Azure DDoS Protection**
- **ExpressRoute Gateway** — the confirmed list includes "Azure ExpressRoute" (circuits), but
  unlike "Azure VPN Gateway" (which is explicitly listed), there is no separate line item for
  the ExpressRoute Gateway resource used to terminate ExpressRoute circuits in a VNet.

**Azure VPN Gateway** is explicitly on the confirmed list and was left enabled.

On 2026-11-17, live `Microsoft.Network` provider metadata for the connectivity subscription
did not advertise `saudiarabiaeast` for `dnsResolvers`, `dnsResolvers/inboundEndpoints`, or
`dnsResolvers/outboundEndpoints`. DNS Private Resolver is therefore disabled in both
networking parameter files. Private DNS zones and their VNet links remain enabled as global
resources; linked VNets can resolve those zones through Azure-provided DNS without a resolver.
Hybrid DNS forwarding through the managed resolver is not provisioned.

## Decision

Keep the four previously disabled services and DNS Private Resolver disabled in both networking templates, while keeping their
subnets (`AzureBastionSubnet`, `AzureFirewallSubnet`, `AzureFirewallManagementSubnet`,
`GatewaySubnet`), naming, and settings intact — so each can be re-enabled later by flipping a
single boolean, with no subnet/IP re-planning needed. The resolver's reserved subnets and
delegations are retained.

## Changes made

1. **[templates/networking/hubnetworking/main.bicepparam](../templates/networking/hubnetworking/main.bicepparam)**
   (active template) — on the single remaining hub:
   - `azureFirewallSettings.deployAzureFirewall`: `true` → `false`
   - `bastionHostSettings.deployBastion`: `true` → `false`
   - `ddosProtectionPlanSettings.deployDdosProtectionPlan`: `true` → `false`
   - `expressRouteGatewaySettings.deployExpressRouteGateway`: `true` → `false`
   - `vpnGatewaySettings.deployVpnGateway` left `true` (VPN Gateway is confirmed available)
   - `privateDnsSettings.deployDnsPrivateResolver`: `true` -> `false` on 2026-11-17;
     `deployPrivateDnsZones` remains `true`
2. **[templates/networking/virtualwan/main.bicepparam](../templates/networking/virtualwan/main.bicepparam)**
   — the same four flags disabled on the single remaining vwan hub, for consistency. This
   template is not currently wired into the deployment pipeline (see
   [single-region-deployment.md](./single-region-deployment.md) /
   [README.md](../README.md) — only `networking-hubnetworking` is a pipeline step), so this
   change has no deployment effect today but keeps the file accurate if it's ever activated.
   - `dnsSettings.deployDnsPrivateResolver`: `true` -> `false` on 2026-11-17;
     `deployPrivateDnsZones` remains `true`

Because disabling Azure Firewall automatically skips its dependent resources in
[hubnetworking/main.bicep](../templates/networking/hubnetworking/main.bicep) (the Firewall
Policy, both route tables, and the Firewall's public IPs are all already conditioned on
`deployAzureFirewall`), and disabling Bastion automatically skips its NSG, no further bicep
changes were needed. The resolver resource group and resolver module (including inbound and
outbound endpoints) are already conditional on `deployDnsPrivateResolver`, so disabling the
resolver also requires only parameter changes.

The separate Private DNS AVM module `0.7.2` region-code mapping issue for `saudiarabiaeast`
(the module's `azureRegionGeoCodeShortNameAsKey` lookup had no entry for `saudiarabiaeast`,
so it failed deploying the private DNS zones with `InvalidTemplate` for any non-empty zone
list) was resolved on 2026-11-17 by bumping `avm/ptn/network/private-link-private-dns-zones`
to `0.7.4` in both
[hubnetworking/main.bicep](../templates/networking/hubnetworking/main.bicep) and
[virtualwan/main.bicep](../templates/networking/virtualwan/main.bicep) — version `0.7.3` added
the missing `saudiarabiaeast` (`sae`) geo-code mapping, with no breaking changes between `0.7.2`
and `0.7.4`.

## Dependent policy configuration

The `Enable-DDoS-VNET` policy assignment (in
[landingzones/main.bicepparam](../templates/core/governance/mgmt-groups/landingzones/main.bicepparam)
and
[platform/platform-connectivity/main.bicepparam](../templates/core/governance/mgmt-groups/platform/platform-connectivity/main.bicepparam))
still has a parameter override pointing at the planned DDoS protection plan resource ID.
It is now restored in **DoNotEnforce in both groups**, with selected `uaenorth` assignment
locations and dependent cross-MG RBAC restored, pending operator testing. The planned DDoS
plan is still absent, so dependency-related noncompliance is expected. Do not enforce the
policy or run remediation until an approved DDoS plan exists and the resource ID is updated.
See [alternate-region policy identities](policy-assignment-alternate-region.md).

## Re-enabling a service

Once a given service becomes available in `saudiarabiaeast`, flip its `deploy*` flag back to
`true` only after validating the exact SKU/API, dependency conditions, routing/DNS behavior,
and monitoring requirements in the target subscription. Restore any associated policies
and RBAC separately after all their blockers are resolved. Preserved subnet/naming
configuration reduces re-planning but is not proof of successful deployment.
