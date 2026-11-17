# Sharing and Placeholder Guide

## Scope and limitations

This copy was sanitized on 2026-11-17 before preparing the handover documentation.
Subscription, tenant, service-connection identity identifiers, private Azure DevOps references,
and identity names were replaced in configuration **and** historical incident examples.
The examples no longer identify the original Azure environment.

Only the files in this directory are covered. The external pipeline-template repository,
Azure DevOps settings, live Azure resources, pipeline logs/artifacts, local editor/chat history,
backups, and any separately held Git history are not sanitized by these edits. No Git metadata
was found in this directory or its parents. Share a reviewed file-only copy, not an entire
development machine or session export. This is not a guarantee that every possible secret
format has been detected; run your organization's approved secret scanner before publication.
If a real credential is ever found in a previously shared copy, revoke/rotate it as well as
removing it.

## Placeholder contract

Repeated-digit GUIDs are intentionally fake, syntactically GUID-shaped placeholders.
They preserve JSON/Bicep string shapes; successful compilation does **not** make them usable
Azure identifiers. Never deploy with them.

| Placeholder | Meaning | Where a recipient must configure it |
|---|---|---|
| `11111111-1111-1111-1111-111111111111` | Management subscription ID | Root parameters, Management subscription placement, logging/DCR/managed-identity resource ID overrides |
| `22222222-2222-2222-2222-222222222222` | Connectivity subscription ID | Root parameters, Connectivity placement, DDoS and Corp Private DNS resource ID overrides |
| `33333333-3333-3333-3333-333333333333` | Identity subscription ID | Root parameters and Identity placement |
| `44444444-4444-4444-4444-444444444444` | Tenant ID | Historical RBAC example only; configure the real tenant in private service connections |
| `55555555-5555-5555-5555-555555555555` | Apply identity client/application ID | Historical RBAC example only |
| `66666666-6666-6666-6666-666666666666` | Plan identity client/application ID | Historical RBAC example only |
| `77777777-7777-7777-7777-777777777777` | Apply identity object/principal ID | Historical RBAC example only; never confuse with the client ID |
| `88888888-8888-8888-8888-888888888888` | Plan identity object/principal ID | Historical RBAC example only |
| `00000000-0000-0000-0000-000000000000` | Upstream ALZ library's existing dummy subscription | Bundled assignment defaults; preserve as a library placeholder, not a deployable ID |
| `<AZURE_DEVOPS_ORGANIZATION>` | Azure DevOps organization | Documentation URL example |
| `<AZURE_DEVOPS_PROJECT>` | Project containing the pipeline templates | Both pipeline YAML repository resources |
| `<PIPELINE_TEMPLATE_REPOSITORY>` | Shared pipeline repository name | Both pipeline YAML repository resources |
| `<APPLY_SERVICE_CONNECTION>`, `<PLAN_SERVICE_CONNECTION>` | Deployment and planning connections | Historical examples; actual bindings are in the external templates/settings |
| `<APPLY_IDENTITY_NAME>`, `<PLAN_IDENTITY_NAME>` | Managed identity resource names | Historical examples only |
| `security@example.com`, `triage@example.com` | Security and Service Health contacts | Intermediate-root policy parameter overrides |

`SUBSCRIPTION_ID_SECURITY = ""`, empty Security placement, and `LOCATION_SECONDARY = ""`
are intentional **deferrals**, not instructions to invent IDs or create a secondary region.
If adding Security, supply a new, dedicated subscription; never reuse Management's ID.

## Values deliberately retained

- `alz`, `platform`, `connectivity`, `identity`, `management`, `landingzones`, `corp`,
  `online`, `local`, `sandbox`, and `decommissioned` are generic hierarchy identifiers.
- `rg-alz-*`, `law-alz-*`, `dcr-*-alz-*`, `mi-alz-*`, and the networking names are generic
  naming patterns. Change them consistently if your naming standard differs.
- The private address ranges, BGP ASN, resource SKUs, and tags are technical template
  configuration, not account identifiers. The hub uses `10.0.0.0/22`; the inactive Virtual WAN
  example includes `10.0.4.0/22` and `172.16.0.0/24`. Review for address conflicts before use.
- Azure built-in policy/role GUIDs, custom ALZ library definition GUIDs, provider resource
  paths, public Microsoft endpoints, and upstream version numbers are functional constants.
  Do not replace every GUID or domain indiscriminately.
- One bundled `Deploy-Custom-Route-Table` policy contained a subscription-prefixed built-in
  Network Contributor role reference. Its subscription prefix was removed, leaving the
  subscription-neutral `/providers/Microsoft.Authorization/roleDefinitions/` reference
  and the original built-in role GUID. No role permissions were changed. Review this
  normalization again if regenerating/updating the library.
- `contoso.com` and `fabrikam.com` email examples inside bundled ALZ policy descriptions are
  upstream fictitious examples, not customer contacts.

## Preparing a private deployment copy

1. Keep this sanitized reference unchanged for sharing. Generate a fresh accelerator
   configuration or copy it to a private workspace.
2. Obtain approved subscription IDs, tenant, contacts, naming/IP plan, and service-connection
   details through your organization's private configuration process, not a public issue/chat.
3. Replace each subscription sentinel consistently across the private configuration,
   including full resource IDs in disabled policy overrides. Root
   [parameters.json](../parameters.json) is not a substitution engine for `.bicepparam` files.
4. Configure both YAML repository resources and check permissions on the actual external
   template repository. Verify the service connections referenced by those templates.
5. Keep Security empty/disabled unless a distinct subscription has been approved. Confirm
   Management, Connectivity, and Identity each occur in only their intended placement array.
6. Replace contact examples before restoring the associated policies. Revalidate availability
   and follow the [Copilot runbook](copilot-reproduction-runbook.md) before any deployment.

## Pre-sharing acceptance checklist

- [ ] Inspect hidden directories as well as visible files.
- [ ] No original subscription/tenant/client/principal IDs or truncated ID fragments remain.
- [ ] No private organization/repository URLs, identity names, user paths, or contact addresses
      remain; review tags and resource names too.
- [ ] Review all `/subscriptions/` and tenant-scoped IDs, not just root parameters.
- [ ] Review credentials, certificates, VPN keys, SAS tokens, webhook URLs, and connection
      strings with approved scanning tools; do not publish scanner output containing secrets.
- [ ] Validate JSON/YAML, compile templates/parameter files, and check relative doc links.
- [ ] Exclude local logs, build outputs, session data, backups, and unreviewed archive contents.
- [ ] Sanitize external templates and any histories separately if they will also be shared.
- [ ] Keep completed deployment inputs private; do not commit real credentials.
