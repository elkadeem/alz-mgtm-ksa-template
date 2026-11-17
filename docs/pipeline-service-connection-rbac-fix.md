# Pipeline Service Connection RBAC Fix

## Status

**Fixed** on 2026-11-16 — applied directly in Azure (not via files in this repository; see
[Nature of this change](#nature-of-this-change) below).

All environment identifiers and names in this historical incident are placeholders; see the
[placeholder contract](sharing-and-placeholders.md). Live permissions were not rechecked for
this handover. The broad Owner grants below record the historical fix, not an instruction to
grant identical permissions in a new tenant. Approve a least-privilege plan/apply model first.

## Context

The CD pipeline's "Check for First Deployment" step failed with:

```text
Set-AzContext -SubscriptionId 11111111-1111-1111-1111-111111111111 -TenantId 44444444-4444-4444-4444-444444444444
The running command stopped because the preference variable "ErrorActionPreference" or common
parameter is set to Stop: Please provide a valid tenant or a valid subscription.
```

### Root cause

1. The subscription (`11111111-1111-1111-1111-111111111111`, Management) exists, is enabled, and
   is in the correct tenant (`44444444-4444-4444-4444-444444444444`).
2. Both Azure DevOps service connections used by the pipeline — `<APPLY_SERVICE_CONNECTION>` (service
   principal `55555555-5555-5555-5555-555555555555`) and `<PLAN_SERVICE_CONNECTION>` (service principal
   `66666666-6666-6666-6666-666666666666`) — are correctly scoped to that subscription and
   tenant.
3. However, **neither service principal held any role granting subscription-read access**.
   Both only had a role called **"Landing Zone Management Owner"**, assigned at the tenant root
   (`/`) scope. Inspecting that role's actual definition showed it is a confusingly-named
   **built-in role for the unrelated Microsoft Sovereign Landing Zone feature** (not Azure
   Landing Zones), granting only:
   - `Microsoft.Sovereign/landingZoneConfigurations/*`
   - `Microsoft.Sovereign/landingZoneRegistrations/*`
   - `Microsoft.Authorization/*/read`
   - `Microsoft.Resources/deployments/*`

   Critically, it does **not** include `Microsoft.Resources/subscriptions/read`, which
   `Set-AzContext` requires. The identity authenticated fine (`Connect-AzAccount` succeeded),
   but `Set-AzContext` couldn't resolve the subscription via RBAC at all.

### Why subscription-level (not management-group-level) role assignments were needed

The `alz` management group already exists in this tenant, and assigning a role there would
normally be the cleaner, single-assignment fix (inherited down to all child subscriptions).
However, **the bootstrap/previous setup never moved the 3 active platform subscriptions
(Management, Connectivity, Identity) underneath the `alz` management group** — they are all
still directly under the Tenant Root Group (verified via
`az account management-group entities list`). Moving them is itself one of the things this
repository's deployment is supposed to do, via `subscriptionsToPlaceInManagementGroup` in
[int-root/main.bicepparam](../templates/core/governance/mgmt-groups/int-root/main.bicepparam)
and the platform child management groups' own parameter files (chicken-and-egg: the pipeline
needs subscription access *before* it can run the deployment that would move the subscriptions
under `alz`). Because of this, a management-group-scoped role assignment on `alz` would **not**
have fixed the immediate failure — the subscriptions aren't children of it yet, so nothing
would inherit down to them. Direct subscription-scoped role assignments were required instead.

## Decision & fix applied

Granted **Owner** to both service connection service principals, directly at the subscription
scope, on all 3 currently-active platform subscriptions (Security was intentionally excluded —
see [security-subscription-deferred.md](./security-subscription-deferred.md), it doesn't have a
dedicated subscription yet).

### First attempt was ineffective — appId used instead of objectId

The first attempt at this fix used `az role assignment create --assignee-object-id <value>`
with the service principals' **Application (client) ID** (`55555555-5555-5555-5555-555555555555`
for apply, `66666666-6666-6666-6666-666666666666` for plan) — the same IDs recorded in the
service connection's `serviceprincipalid` field. However, `--assignee-object-id` specifically
requires the security principal's **Object ID**, which for these identities (both
**User-Assigned Managed Identities**, not classic App Registrations) is a *different* GUID from
the Application ID:

| Name | Application (client) ID | Object ID (actual principal) |
|---|---|---|
| `<APPLY_IDENTITY_NAME>` | `55555555-5555-5555-5555-555555555555` | `77777777-7777-7777-7777-777777777777` |
| `<PLAN_IDENTITY_NAME>` | `66666666-6666-6666-6666-666666666666` | `88888888-8888-8888-8888-888888888888` |

Because `--assignee-object-id` bypasses Microsoft Graph validation (by design, to work around
Graph permission issues), Azure silently created role assignments with `principalId` set to the
literal Application ID string — a GUID that doesn't correspond to any real security principal.
These assignments were visible via `az role assignment list` but granted **zero actual access**,
since RBAC evaluation matches a token's `oid` claim (the real Object ID), not the Application ID.
This is why the exact same `Set-AzContext` failure persisted on a later pipeline run (build #6,
finished 20:38 UTC, ~19 minutes after the first "fix" — ruling out propagation delay) even
though the role assignments appeared to exist.

**How this was caught:** after ruling out propagation delay, deny assignments, tenant/
subscription validity, and federated credential misconfiguration (all confirmed fine), comparing
`az ad sp show --id <appId>` output showed the SP's true `id` (Object ID) field differed from
the `appId` used in the original fix.

**Corrected fix:** deleted the 6 incorrect role assignments (by exact resource ID, since
`--assignee <appId>` couldn't resolve/match them for deletion either) and recreated them using
`--assignee-object-id` with the correct Object IDs above. Verified afterward that
`az role assignment list` now resolves `principalName` for each assignment (previously blank),
confirming the principal IDs are genuinely valid this time.

### Final state

| Subscription | <APPLY_SERVICE_CONNECTION> (objectId `7d333c84...`) | <PLAN_SERVICE_CONNECTION> (objectId `efc747ae...`) |
|---|---|---|
| Management (`11111111-1111-1111-1111-111111111111`) | ✅ Owner | ✅ Owner |
| Connectivity (`22222222-2222-2222-2222-222222222222`) | ✅ Owner | ✅ Owner |
| Identity (`33333333-3333-3333-3333-333333333333`) | ✅ Owner | ✅ Owner |

The pre-existing "Landing Zone Management Owner" role assignment at tenant root (`/`) was left
in place — it's unrelated and harmless, just insufficient on its own.

### Lesson for next time

When granting roles to **service connections backed by User-Assigned Managed Identities**
(as opposed to classic App Registrations), always resolve and use the actual **Object ID**
(`az ad sp show --id <appId> --query id`) — never assume the Application ID recorded in the
service connection (`serviceprincipalid`) can be passed directly to
`--assignee-object-id`. Using the simpler `--assignee <appId>` (without `-object-id`) lets
Azure CLI resolve this correctly via Graph automatically, at the cost of requiring Graph read
permissions.

## Nature of this change

Unlike every other change documented under `docs/` in this repository, **this fix is an Azure
RBAC (IAM) change made directly against the tenant via Azure CLI** — it is not represented by
any file in this repository, because Azure RBAC role assignments for service connections are
not managed as code here. This document exists purely as a record of what was changed and why,
for anyone auditing access or troubleshooting similar failures later.

## Re-evaluating later

Once a full deployment succeeds and `int-root` (plus the platform child management groups)
actually place these subscriptions under the `alz` management group hierarchy, consider
whether to:
- Keep the direct subscription-level Owner assignments (simplest, already working), or
- Replace them with a single Owner assignment at the `alz` management group scope (cleaner,
  automatically covers any future subscription added under that hierarchy, including Security
  once it's provisioned — see [security-subscription-deferred.md](./security-subscription-deferred.md)).

Either way, double-check whether `Owner` is broader than necessary long-term — `Contributor` +
`User Access Administrator` (scoped to roles the pipeline actually assigns) may be preferable
once the initial bootstrap is complete, per the principle of least privilege.
