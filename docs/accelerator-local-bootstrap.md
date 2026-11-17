# Advanced Option: Local Bootstrap via `Deploy-Accelerator`

## Status

Documented 2026-11-17. **Not executed as part of this change.** This records the manual/
"advanced" ALZ Accelerator bootstrap path as an alternative to the interactive wizard, using
this repository's own [config/inputs.yaml](../config/inputs.yaml) and
[config/platform-landing-zone.yaml](../config/platform-landing-zone.yaml) (now unified with the
rest of this repo's decisions — see [Config Unification](#config-files-already-unified-in-this-repo)
below). It does not replace the [Copilot reproduction runbook](copilot-reproduction-runbook.md),
which targets regenerating/adapting a Bicep configuration, not re-running the bootstrap itself.

## When to use this instead of the interactive wizard

Per the official
[Advanced Bootstrap guide](https://azure.github.io/Azure-Landing-Zones/accelerator/2_bootstrap/advanced/),
use the manual/advanced path when you already know your configuration and want to review/edit
the YAML files directly in an editor, rather than answering the `Deploy-Accelerator` wizard's
interactive prompts. This repository's `config/` files are already filled in, so this is the
natural path here — you mainly need to review them, then run the deploy command.

## ⚠️ Read before running anything — this is a live environment, not just a template

This repository's own git remote is a **public GitHub template**
(`https://github.com/elkadeem/alz-mgtm-ksa-template.git`) — the sanitized/shareable copy
described in [README.md](../README.md) and [sharing-and-placeholders.md](sharing-and-placeholders.md).
`config/` is currently **untracked** (`git status` shows `?? config/`; verified it has never been
committed or pushed), but it contains **real, non-placeholder values**: real subscription IDs
and the real Azure DevOps organization/project name (`welkadimdemos03` / `alz-sa`). A
[.gitignore](../.gitignore) entry for `config/inputs.yaml` was added alongside this doc so a
future `git add -A` doesn't push these real identifiers to the public template repo. If you
intend `config/inputs.yaml` to ship as part of the public template, replace its real values with
this repo's placeholder convention (see [sharing-and-placeholders.md](sharing-and-placeholders.md))
and remove that `.gitignore` entry instead.

Separately — and more importantly for *running* this bootstrap — one directory above this repo
(`D:\workarea\Source\alz\alz-devops`) there is already a **live, previously-bootstrapped
environment** for that same real organization/project:

- `D:\workarea\Source\alz\alz-devops\alz-lmgtm\` is a **git clone of the real Azure DevOps
  repository** created by that earlier bootstrap (`git remote -v` →
  `https://welkadimdemos03@dev.azure.com/welkadimdemos03/alz-sa/_git/alz-lmgtm`), including its
  own [docs/destroy-landing-zone.azcli](../../alz-lmgtm/docs/destroy-landing-zone.azcli) manual
  teardown runbook — likely what "delete all landing zone previous deployment" refers to.
- `D:\workarea\Source\alz\alz-devops\output\bootstrap\v7.3.2\alz\azuredevops\terraform.tfstate`
  (plus `.terraform`, `tfplan`, provider caches) is the **real Terraform state** for that
  bootstrap, and `D:\workarea\Source\alz\alz-devops\config\inputs.yaml` /
  `platform-landing-zone.yaml` is the (pre-fix) config used to create it — byte-for-byte the
  same real values this repo's `config/inputs.yaml` had before the fixes below, consistent with
  it being the original source this repo's copy was made from.

**You must decide which of these two you're targeting before setting `$targetFolderPath`:**

- **Update the same existing live environment/state** (same Azure DevOps org/project, same
  Terraform state, e.g. to apply the `apply_approvers`/Decision 11 fixes below to the bootstrap
  that already produced `alz-lmgtm`): use the **parent folder**,
  `$targetFolderPath = "D:\workarea\Source\alz\alz-devops"`, so `Deploy-Accelerator` finds the
  existing state and plans an *update*, not a fresh resource creation. In that case, apply this
  doc's config fixes to `D:\workarea\Source\alz\alz-devops\config\inputs.yaml` (the parent copy)
  as well, not only this repo's copy.
- **Bootstrap a separate environment** (new state, potentially still the same Azure DevOps
  org/project name unless you also change `azure_devops_project_name`/`service_name`/
  `environment_name`): use this repository's own folder,
  `$targetFolderPath = "D:\workarea\Source\alz\alz-devops\alz-mgtm-sa"`, so a new,
  independent Terraform state is created under `alz-mgtm-sa/output`. Reusing the same
  `azure_devops_organization_name`/`azure_devops_project_name` with a *new, unlinked* state can
  conflict with the already-existing project/resources from the first bootstrap — change those
  names too if you want a truly separate environment.

Either way, before running `Deploy-Accelerator` for real:

1. If this run is meant to follow deletion of the previous Landing Zone deployment (per
   `alz-lmgtm`'s own teardown runbook), confirm that deletion — and any corresponding
   Terraform/stack state cleanup — is complete first. Don't assume this bootstrap run will
   reconcile stale `output/`/`alz-lmgtm` state for you.
2. Back up or branch whichever repository you're updating before running the bootstrap, in case
   it regenerates files you've already hand-customized (service-connection RBAC, pipeline YAML
   repository resources, etc. — see the [implementation guide](saudi-arabia-east-implementation-guide.md)).

## Config files already unified in this repo

[config/inputs.yaml](../config/inputs.yaml) previously mixed fields from two incompatible
upstream examples: it set `bootstrap_module_name: "alz_azuredevops"` but still carried the
**Local-bootstrap-only** fields `create_bootstrap_resources_in_azure`,
`grant_permissions_to_current_user`, and `target_directory` (these belong to the `alz_local`
module only, confirmed against the upstream
[`inputs-local.yaml`](https://github.com/Azure/alz-bicep-accelerator/blob/main/examples/bootstrap/inputs-local.yaml)
vs.
[`inputs-azure-devops.yaml`](https://github.com/Azure/alz-bicep-accelerator/blob/main/examples/bootstrap/inputs-azure-devops.yaml)
examples), while **omitting** the Azure DevOps-required `apply_approvers` field entirely. It also
duplicated the Management subscription ID into `subscription_ids.security`, the same
invalid-duplicate pattern already flagged and fixed elsewhere in this repo (see
[Security Subscription Deferred](security-subscription-deferred.md)).

This was corrected to match the official `alz_azuredevops` schema (Decisions 4/6–11):

- Removed the three Local-only fields.
- Added `apply_approvers: ["<email-address>"]` with a `TODO` — **you must replace this
  placeholder** with real approver email(s) before bootstrapping; there is no safe default.
- `subscription_ids.security` is now `""` (blank), consistent with this repo's existing
  Security-deferral decision, instead of duplicating Management's ID.
- Documented that `azure_devops_personal_access_token` /
  `azure_devops_agents_personal_access_token` are deliberately **not** stored in the file —
  supply them via the `TF_VAR_*` environment variables in the steps below instead.
- Fixed the `.../bootstrap/local/variables` and `.../bootstrap/local/resourcenames` doc-comment
  links to point at the `azuredevops` variants, and reordered the file to match the upstream
  Decision 4/6/7/8/9/10/11 → Basic Inputs structure.
- Left `bootstrap_location` (`swedencentral`), `bootstrap_subscription_id` (Connectivity's ID),
  and `move_subscriptions_to_target_management_group: false` as-is, with comments added
  explaining each deviates from (or relates to) a default/recommendation, since these reflect
  real environment choices, not bugs. Decision 4's region is independent of the Platform landing
  zone's workload region(s) in `platform-landing-zone.yaml` (`starter_locations`) — see the
  [Advanced Bootstrap guide, Decision 4](https://azure.github.io/Azure-Landing-Zones/accelerator/0_planning/#decision-4---choose-a-region-for-the-bootstrap-resources);
  bootstrap resources (resource groups, managed identities, role assignments, and — for
  Terraform — state storage) don't have to share a region with the Platform landing zone's own
  resources, the same reasoning already applied to the separate
  [Deployment Stack location workaround](deployment-stack-location-workaround.md).
- [config/platform-landing-zone.yaml](../config/platform-landing-zone.yaml) was already
  consistent with the rest of this repo (`starter_locations: ["saudiarabiaeast"]`, matching
  `parLocations` everywhere else; resource group prefixes matching the `.bicepparam` files;
  `network_type: "hubNetworking"` matching `parameters.json`'s `NETWORK_TYPE`) — no changes
  were needed there.

## Step-by-step

1. **Install or update the ALZ PowerShell module:**

   ```powershell
   $alzModule = Get-InstalledPSResource -Name ALZ 2>$null
   if (-not $alzModule) {
       Install-PSResource -Name ALZ
   } else {
       Update-PSResource -Name ALZ
   }
   ```

2. **Decide your target folder first** (see the warning above), then review the config files
   before running anything. The folder structure/config already exist in both candidate
   locations, so you can skip `New-AcceleratorFolderStructure` — open and check whichever
   `config/inputs.yaml` matches your chosen `$targetFolderPath`:
   - Fill in the `apply_approvers` `TODO` (there is no safe default).
   - Confirm `subscription_ids`, `bootstrap_subscription_id`, and `bootstrap_location` are
     still what you want.
   - If you're targeting the parent folder's existing environment, apply the same schema fixes
     described above (remove the Local-only fields, add `apply_approvers`, blank out
     `subscription_ids.security`) to `D:\workarea\Source\alz\alz-devops\config\inputs.yaml` too —
     they were only made in this repo's copy.
   - [config/platform-landing-zone.yaml](../config/platform-landing-zone.yaml) — confirm
     `starter_locations` and the management-group/resource-group naming still match your
     target environment.

3. **Sign in to Azure CLI, targeting the bootstrap subscription:**

   ```powershell
   az login --tenant "<tenant-id>" --use-device-code
   az account set --subscription "<bootstrap-subscription-id>"
   ```

   Use the real tenant ID and the subscription configured as `bootstrap_subscription_id` in
   `config/inputs.yaml` (or omit `az account set` to use the CLI's current subscription, matching
   that field's `""` default behavior).

4. **Supply the Azure DevOps PATs via environment variables** (avoids committing them to
   `config/inputs.yaml`; needs `token-1` and, since `use_self_hosted_agents: true`, `token-2` —
   see the
   [Azure DevOps prerequisites](https://azure.github.io/Azure-Landing-Zones/accelerator/1_prerequisites/azuredevops/)
   for how to create each PAT and its required scopes):

   ```powershell
   $env:TF_VAR_azure_devops_personal_access_token = Read-Host `
       -Prompt 'Azure DevOps bootstrap PAT' -MaskInput

   $env:TF_VAR_azure_devops_agents_personal_access_token = Read-Host `
       -Prompt 'Azure DevOps agent registration PAT' -MaskInput
   ```

5. **Set the bootstrap variables, with `$targetFolderPath` matching the decision you made above**
   (do not default to copy-pasting the parent-folder path without deciding first):

   ```powershell
   $iacType = "bicep"              # Must be one of: "bicep" or "terraform"
   $versionControl = "azure-devops" # Must be one of: "azure-devops", "github", "local"
   $scenarioNumber = 1               # Terraform only; ignored for Bicep

   # Updating the existing live environment/state (same Azure DevOps org/project as before):
   $targetFolderPath = "D:\workarea\Source\alz\alz-devops"

   # OR bootstrapping a separate environment with its own state (change
   # azure_devops_project_name/service_name/environment_name in config/inputs.yaml too if you
   # want it fully independent from the existing project):
   # $targetFolderPath = "D:\workarea\Source\alz\alz-devops\alz-mgtm-sa"
   ```

6. **Run the bootstrap.** `-skip_alz_module_version_requirements_check` skips the module's
   built-in check that your installed ALZ module version satisfies the bootstrap/starter
   modules' declared minimum version — only pass it if you've deliberately confirmed your
   installed module version is compatible (e.g. testing against a pinned/older module version);
   otherwise omit it so the check runs:

   ```powershell
   Deploy-Accelerator -skip_alz_module_version_requirements_check `
       -inputs "$targetFolderPath/config/inputs.yaml", "$targetFolderPath/config/platform-landing-zone.yaml" `
       -output "$targetFolderPath/output"
   ```

7. **Review the generated Terraform plan carefully** before accepting. Confirm it's creating
   (not modifying/destroying) the resources you expect — especially important here, since a
   stale `-output` path or mismatched project name could cause it to target already-existing
   bootstrap resources. Press Enter only once you've confirmed the plan, to deploy.

8. **For Bicep (this repo's `iac_type`):** once bootstrap completes, it creates/updates an Azure
   DevOps repository containing the generated `platform_landing_zone` starter files and
   `.pipelines/*` YAML. Clone or pull that repository, reconcile it against this repo's existing
   hand-customizations (all the decisions under [README.md](../README.md)'s
   "Architecture Decisions" and "Pipeline / CI-CD Infrastructure Notes" sections must be
   reapplied if the bootstrap regenerated any of those files), then commit and push.

## References

- [Advanced Bootstrap (official)](https://azure.github.io/Azure-Landing-Zones/accelerator/2_bootstrap/advanced/)
- [Phase 0 - Planning, Bootstrap Decisions](https://azure.github.io/Azure-Landing-Zones/accelerator/0_planning/#3---bootstrap-decisions)
- [Azure DevOps prerequisites / PAT setup](https://azure.github.io/Azure-Landing-Zones/accelerator/1_prerequisites/azuredevops/)
- [Configuration Files reference](https://azure.github.io/Azure-Landing-Zones/accelerator/configuration-files/)
