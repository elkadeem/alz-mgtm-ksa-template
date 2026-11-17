# Single-Region Deployment (Saudi Arabia East)

## Status

**Enforced single-region** as of 2026-11-16. This environment deploys to `saudiarabiaeast`
only — no secondary/DR region.

## Context

Several parameter files were originally authored for a 2-region topology: `parLocations`
arrays had two entries (`'saudiarabiaeast'` and an empty placeholder string for a secondary
region that was never specified), and the networking parameter files
([hubnetworking](../templates/networking/hubnetworking/main.bicepparam) and
[virtualwan](../templates/networking/virtualwan/main.bicepparam)) each defined a **second hub**
located at that empty placeholder. An empty string is not a valid Azure region, so the second
hub/VWAN hub in each file would have failed to deploy, and the first hub's VNet peering
pointed at a VNet name that would never exist (`vnet-alz-` with no region suffix).

Since this deployment is intended for `saudiarabiaeast` only, the fix was to remove the second
region/hub entirely rather than patch it with a placeholder value.

## Decision

Deploy to a single region (`saudiarabiaeast`) everywhere in this repository. Remove the second
hub/VWAN hub and VNet peering, and trim every `parLocations` array down to one entry.

## Changes made

1. **[templates/networking/hubnetworking/main.bicepparam](../templates/networking/hubnetworking/main.bicepparam)**
   - `parLocations` trimmed to a single entry.
   - The second hub object (previously at `parLocations[1]`) was removed — no second VNet,
     Firewall, Bastion, VPN/ExpressRoute Gateway, or DNS Private Resolver.
   - On the remaining hub, `deployPeering` was set to `false` and the `peeringSettings` block
     (which pointed at the now-removed second hub) was removed.
2. **[templates/networking/virtualwan/main.bicepparam](../templates/networking/virtualwan/main.bicepparam)**
   - `parLocations` trimmed to a single entry.
   - The second Virtual WAN hub object (previously at `parLocations[1]`) was removed.
3. **All other `main.bicepparam` files** under
   [templates/core/logging](../templates/core/logging/main.bicepparam) and
   [templates/core/governance/mgmt-groups](../templates/core/governance/mgmt-groups) — trimmed
   `parLocations` from a 2-element array (with an unused empty second entry) down to a single
   element. These files never actually referenced `parLocations[1]`, so this is a clarity/
   consistency cleanup with no functional effect on their own, but it removes the inconsistency
   with the networking files and makes the single-region intent explicit everywhere.

## Private DNS zone coverage — no functionality lost

The removed second hub's `privateDnsSettings.privateDnsZones` (and the removed second VWAN
hub's `dnsSettings.privateDnsZones`) listed only 5 specific zones (Container Apps, Kusto, AKS,
Managed Prometheus, Backup). The remaining (surviving) hub leaves `privateDnsZones` empty,
which — per the `private-link-private-dns-zones` AVM pattern module used by
[hubnetworking/main.bicep](../templates/networking/hubnetworking/main.bicep) and
[virtualwan/main.bicep](../templates/networking/virtualwan/main.bicep) — causes the module to
deploy its **full built-in default list** of private DNS zones (a superset that already
includes those 5). So no private DNS zone coverage was lost by removing the second hub.

## How to re-introduce a second region later

1. Add the secondary region back to the relevant `parLocations` arrays (e.g.
   `['saudiarabiaeast', '<secondary-region>']`).
2. In [hubnetworking/main.bicepparam](../templates/networking/hubnetworking/main.bicepparam)
   and/or [virtualwan/main.bicepparam](../templates/networking/virtualwan/main.bicepparam),
   re-add a second hub object following the pattern of the first, using `parLocations[1]` for
   its location/naming.
3. Re-add `peeringSettings` (hub networking) pointing each hub at the other's VNet name, and
   set `deployPeering: true` on both.
4. Decide whether the new hub needs its own DDoS protection plan, or should share the primary
   hub's plan (see the `ddosProtectionPlanSettings` fallback logic in
   [hubnetworking/main.bicep](../templates/networking/hubnetworking/main.bicep)).
