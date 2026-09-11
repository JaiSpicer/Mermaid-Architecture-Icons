# Azure DevOps Repository Hosting

Notes for teams hosting this repository as an Azure Repos Git repository and
running `pipelines/azure-pipelines.yml` against it.

> **`pipelines/azure-pipelines.yml` is an untested template.** The
> PowerShell it calls (`build-icon-pack.ps1`, `update-azure-pack.ps1`,
> `validate-icon-packs.ps1`) has been run directly and confirmed working;
> the YAML pipeline itself has not been run against a live Azure DevOps
> organization. Confirm the agent image, task versions, and your org's
> policies (approved task list, network egress rules, service connection
> scopes) before relying on it — especially in a network-restricted org,
> where Microsoft-hosted agents or specific tasks may be blocked outright.

## Repository setup

- Import or push this repository into an Azure Repos Git project.
- Set the default branch to `main`.
- Add a branch policy on `main` requiring:
  - At least one reviewer.
  - A successful run of the `Build and Validate Icon Packs` pipeline (see
    `pipelines/azure-pipelines.yml`) before merge.

## Pipeline setup

1. In the Azure DevOps project, go to **Pipelines → New Pipeline**.
2. Point it at this repository and select **Existing Azure Pipelines YAML
   file** → `/pipelines/azure-pipelines.yml`.
3. No custom agent pool or service connection is required — the pipeline uses
   the `ubuntu-latest` Microsoft-hosted agent and only downloads the upstream
   Azure icon JSON over HTTPS (no credentials needed).
4. Save and run. The pipeline builds `packs/<name>-icons.json` for every pack
   under `source/`, verifies `packs/azure-icons.json` is present, validates
   all packs, and publishes `icon-packs` and `build-summary` artifacts.

## Permissions

- Contributors need write access to `source/**` and `packs/**` to add icons
  and commit regenerated packs.
- Only maintainers should run `scripts/update-azure-pack.ps1` and commit the
  refreshed `packs/azure-icons.json`, since it replaces a third-party
  dependency file (see "Updating Azure Icons" in the root `README.md`).

## Consuming this repository from another Azure DevOps project

In principle, reference `packs/*.json` directly via the Azure Repos raw item
URL — see the "From Azure DevOps" section in `examples/README.md` for the
exact URL form. In practice, a typical enterprise/network-restricted Azure
DevOps org will block this: anonymous read on the items API is usually
disabled by org policy, and even with it enabled, Mermaid CLI's icon pack
loader has no way to attach an `Authorization` header, and the raw item
endpoint may not send `Access-Control-Allow-Origin` for headless Chrome's
`fetch()` to accept the response. If either applies to your org, use Azure
Blob Storage instead (below).

## Publishing to Azure Blob Storage

This is the recommended hosting method when the Azure Repos raw item URL
isn't reachable — e.g. a restricted org, or Chrome's `fetch()` being refused
by CORS. `pipelines/azure-pipelines.yml` has an untested, disabled-by-default
`AzureFileCopy@6` step for this; to use it:

1. Create (or reuse) a storage account and a container, e.g. `icon-packs`.
2. On the storage account, add a CORS rule for the Blob service allowing
   `GET` from origin `*`. This isn't optional: Mermaid CLI renders inside
   headless Chrome and loads each pack via `fetch()` from a page with a
   `null`/`file:` origin, so an origin-specific CORS rule won't match —
   only a wildcard origin works.
3. Set the container's public access level to allow anonymous blob read (or
   plan to append a read-only SAS token to each pack's URL if your org
   disallows anonymous containers).
4. Create an ARM service connection in this Azure DevOps project scoped to
   that storage account, with at least the **Storage Blob Data Contributor**
   role.
5. In `pipelines/azure-pipelines.yml`, set `publishToBlobStorage: true` and
   fill in `storageAccountServiceConnection`, `storageAccountName`, and
   `storageContainerName` (all currently placeholders).
6. Reference the resulting blob URLs in `--iconPacksNamesAndUrls`, e.g.
   `azure#https://<account>.blob.core.windows.net/icon-packs/azure-icons.json`.

This step is untested against a live storage account — verify the CORS rule
and service connection permissions actually work for your org before relying
on it in CI.
