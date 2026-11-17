# Saudi Arabia East Azure Landing Zone

Shareable adaptation of an Azure Landing Zones accelerator Bicep configuration for
`saudiarabiaeast`. This is a reduced-capability rollout baseline, **not a production-ready
or compliance-certified landing zone**. Regional availability observations date from
2026-11-16/17 and must be revalidated for each target environment.

## Start Here

1. [Sharing and placeholder guide](docs/sharing-and-placeholders.md) - environment identifiers
   have been replaced throughout configuration and documentation. Replace placeholders in a
   private deployment copy; do not run the pipelines unchanged.
2. [Comprehensive implementation guide](docs/saudi-arabia-east-implementation-guide.md) -
   architecture, decisions, final policy counts, trade-offs, deployment sequence, and recovery.
3. [Step-by-step Copilot reproduction runbook](docs/copilot-reproduction-runbook.md) -
   copyable prompts and acceptance checks for a newly generated accelerator template.

The shared pipeline-template repository is **not included**. Both pipeline YAML files use
`<AZURE_DEVOPS_PROJECT>/<PIPELINE_TEMPLATE_REPOSITORY>` until configured by the recipient.
No live Azure deployment was performed as part of preparing this shareable copy.

## Advanced: Local Bootstrap via `Deploy-Accelerator`

- [Advanced Option: Local Bootstrap via Deploy-Accelerator](docs/accelerator-local-bootstrap.md) -
  step-by-step for the manual/advanced ALZ Accelerator bootstrap path (`config/inputs.yaml` and
  `config/platform-landing-zone.yaml`, PAT environment variables, `Deploy-Accelerator`), as an
  alternative to the interactive wizard. `config/inputs.yaml` was unified with this repo's
  established conventions (correct Azure DevOps bootstrap schema, Security subscription
  deferred, no committed PATs) but still has **real** subscription IDs and Azure DevOps
  org/project values — see that doc's warning before running anything; it is `.gitignore`d
  pending a decision on sanitizing it for the public template vs. keeping it for real use.

## Open Discussion Items (Not Implemented)

- [User-Assigned Managed Identity for Policy Assignments](docs/policy-assignment-user-assigned-identity-option.md) —
  a candidate alternative to the selected off-region system-assigned identities below.
  Needs team discussion on identity placement and RBAC role-assignment design, plus test
  validation, before any assignment is converted.

## Known Temporary Changes

- [Core-Logging Temporarily Disabled (Saudi Arabia East)](docs/core-logging-disabled.md) —
  Log Analytics is not yet available in `saudiarabiaeast`, so the Core-Logging pipeline step
  and dependent governance policy assignments are disabled until the region supports it.

## Architecture Decisions

- [Single-Region Deployment (Saudi Arabia East)](docs/single-region-deployment.md) — this
  workload resources remain in `saudiarabiaeast`; selected policy identities use `uaenorth`.
  The leftover second-region/second-hub configuration was removed.
- [Policy Audit-Only Rollout](docs/policy-audit-only-rollout.md) — of 123 declared assignment
  occurrences, 96 are configured as `DoNotEnforce` and 27 are excluded after the regional
  workarounds. Excluded assignments provide no compliance evaluation.
- [Network Service Region Limitations](docs/network-service-region-limitations.md) — Azure
  Firewall, Azure Bastion, Azure DDoS Protection, and ExpressRoute Gateway are disabled in the
  networking templates because they are not on the confirmed Saudi Arabia East
  foundational-services list. DNS Private Resolver is also disabled; Private DNS zones and
  Azure VPN Gateway remain enabled. The Private DNS AVM pattern is pinned to `0.7.4`.
- [Security Service Region Limitations](docs/security-service-region-limitations.md) — Microsoft
  Defender for Cloud and Microsoft Sentinel are not available in Saudi Arabia East; 9 related
  policy assignments are excluded, and Sentinel onboarding was already off.
- [Security Subscription Deferred](docs/security-subscription-deferred.md) — the Security
  platform subscription is optional per the ALZ accelerator docs and hasn't been provisioned
  yet, so the `platform-security` deployment step is skipped for now.

## Pipeline / CI-CD Infrastructure Notes

- [Policy Assignment Identities in UAE North](docs/policy-assignment-alternate-region.md) -
  66 identity-deferred occurrences across 7 management groups, including root's
  `Deploy-SvcHealth-BuiltIn` and `Enforce-ACSB`, are restored as `DoNotEnforce` using
  selected `uaenorth` assignment locations. Workload locations and logging/security
  exclusions are unchanged. **Pending operator deployment/testing.** Inventory existing
  locations first: assignment locations are immutable. See the linked test and rollback
  procedure; the earlier broad override must not be repeated.
- [Pipeline Service Connection RBAC Fix](docs/pipeline-service-connection-rbac-fix.md) — the CD
  pipeline's service connections lacked subscription-read access due to a misassigned built-in
  role; Owner was granted directly on the 3 active platform subscriptions since they aren't yet
  moved under the `alz` management group. This is an Azure RBAC change, not a file in this repo.
- [Deployment Stack Location Workaround](docs/deployment-stack-location-workaround.md) —
  `parameters.json`'s `LOCATION` value (which the external pipeline uses only for Deployment
  Stack tracking metadata, not actual resource placement) is temporarily set to `uaenorth` due
  to an apparent stale ARM cache for `saudiarabiaeast` on the `deploymentStacks` resource type.
- [AVM Telemetry Disabled](docs/avm-telemetry-disabled.md) — `saudiarabiaeast` is genuinely not
  supported for the `Microsoft.Resources/deployments` resource type, and every AVM module's
  standard telemetry resource explicitly uses that region for its own deployment metadata.
  `parEnableTelemetry` is set to `false` across all 18 parameter files to avoid this.