# Mermaid-Architecture-Icons

Centralised Mermaid CLI icon pack repository containing Azure and
application icon packs, source SVG assets, build automation, and reusable
assets for architecture diagrams.

## Purpose

This repository is the central source of Iconify-compatible icon packs
consumed by [Mermaid CLI](https://github.com/mermaid-js/mermaid-cli)'s
`architecture-beta` diagrams via `--iconPacksNamesAndUrls`. It provides:

- A locally hosted, version-pinned copy of the Azure Architecture Icons pack.
- A build pipeline that turns hand-authored SVG logos into an icon pack per
  application/vendor/integration, etc.
- A structure that lets new icon packs be added without changing any script
  or pipeline code — just a new folder under `source/`.

## Supported Packs

| Pack          | File                            | Source                                                              |
| ------------- | -------------------------------- | -------------------------------------------------------------------- |
| `azure`       | `packs/azure-icons.json`        | Third-party, see [Updating Azure Icons](#updating-azure-icons)      |
| `application` | `packs/application-icons.json`  | `source/application/*.svg`, built by `scripts/build-icon-pack.ps1`  |

## Adding a New Pack

**Adding a new folder under `source/` results in a new icon pack being
built — no script or pipeline changes needed.** The folder name becomes the
pack name:

1. Create `source/<new-pack-name>/` and add one or more SVG files to it
   (see `source/README.md` for the SVG requirements).
2. Run `./scripts/build-icon-pack.ps1 <new-pack-name>` — it takes the pack
   name as a parameter, so it works for any folder under `source/` without
   modification.
3. Commit the source SVGs and the generated
   `packs/<new-pack-name>-icons.json`.

`pipelines/azure-pipelines.yml` builds and validates every folder under
`source/` on each run rather than naming specific packs, so a new pack is
picked up by CI automatically on its next push — see `source/README.md` for
the full mechanism.

## Repository Structure

```
.
├── README.md                      This file.
├── packs/                         Generated/downloaded Iconify JSON files consumed by mmdc.
│   ├── azure-icons.json           Third-party Azure Architecture Icons pack (never hand-edited).
│   └── application-icons.json     Generated from source/application by build-icon-pack.ps1.
├── source/                        Hand-authored SVG inputs, one subfolder per pack (+ README).
│   └── application/               Source SVGs for the application pack.
├── scripts/                       Build and maintenance automation.
│   ├── build-icon-pack.ps1        Builds packs/<name>-icons.json from source/<name>/*.svg.
│   ├── update-azure-pack.ps1      Refreshes packs/azure-icons.json from upstream.
│   ├── validate-icon-packs.ps1    Validates every generated pack under packs/.
│   └── shared/                    PowerShell modules shared by the scripts above.
├── examples/                      A worked Mermaid diagram mixing azure + application icons.
├── azureDevOps/                   Azure DevOps repository hosting notes.
└── pipelines/
    └── azure-pipelines.yml        CI pipeline: build, validate, publish icon packs.
```

## Adding a New Icon

To add an icon to an existing pack (e.g. `application`):

1. Export the logo/graphic as a single SVG file with a `viewBox`.
2. Place it in `source/application/`, named `<icon-name>.svg` in lowercase
   kebab-case.
3. Run:
   ```
   ./scripts/build-icon-pack.ps1 application
   ```
4. Commit the source SVG and the regenerated `packs/application-icons.json`.

See `source/README.md` for the full SVG requirements, and
[Adding a New Pack](#adding-a-new-pack) above for introducing a pack that
doesn't exist yet.

## Mermaid Usage

`--iconPacksNamesAndUrls` takes one or more `prefix#url` pairs as **separate
arguments** (do not comma-join them into a single string — Mermaid CLI splits
each argument on `#` only).

**The URL must be `http(s)`, not a local file path.** Mermaid CLI renders
inside headless Chrome and loads each pack via the browser's `fetch()` API,
which unconditionally rejects the `file:` scheme — a relative path, an
absolute path, and an absolute `file://` URL all fail the same way. Point
`--iconPacksNamesAndUrls` at this repository's hosted copy of `packs/`
instead — GitHub raw content or the Azure Repos items API, per whichever
remote hosts this repository (see `examples/README.md` for both forms).

### Azure icons only

```
npx @mermaid-js/mermaid-cli \
  -i diagram.mmd \
  -o diagram.svg \
  --iconPacksNamesAndUrls "azure#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/azure-icons.json"
```

```
architecture-beta
    service funcapp(azure:function-apps)[Function App]
    service kv(azure:key-vaults)[Key Vault]
```

### Application icons only

```
npx @mermaid-js/mermaid-cli \
  -i diagram.mmd \
  -o diagram.svg \
  --iconPacksNamesAndUrls "application#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/application-icons.json"
```

```
architecture-beta
    service xap(application:xap)[Xap]
```

### Mixed diagram (both packs)

```
npx @mermaid-js/mermaid-cli \
  -i diagram.mmd \
  -o diagram.svg \
  --iconPacksNamesAndUrls "azure#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/azure-icons.json" "application#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/application-icons.json"
```

```
architecture-beta
    service funcapp(azure:function-apps)[Function App]
    service kv(azure:key-vaults)[Key Vault]

    service xap(application:xap)[Xap]
```

See `examples/architecture-example.mmd` for a worked example diagram, and
`examples/README.md` for how to render it (including the Azure Repos and
Azure Blob Storage URL forms).

## Azure DevOps Integration

> `pipelines/azure-pipelines.yml` is an **untested template** — the
> PowerShell it runs has been verified directly, but the pipeline itself has
> not been run against a live Azure DevOps organization. See
> `azureDevOps/README.md` for what to check before relying on it.

`pipelines/azure-pipelines.yml` runs on every push/PR to `main` and:

1. Generates `packs/<name>-icons.json` for every pack folder under `source/`.
2. Verifies `packs/azure-icons.json` is present.
3. Validates all packs under `packs/` (structure + cross-pack name conflicts).
4. Publishes `packs/*.json` as the `icon-packs` build artifact.
5. Publishes a combined log as the `build-summary` build artifact.
6. Optionally (disabled by default), publishes `packs/*.json` to Azure Blob
   Storage — the recommended way to make packs reachable in a
   network-restricted org where the Azure Repos raw item API isn't usable.

See `azureDevOps/README.md` for repository/pipeline hosting setup in Azure
DevOps, including the Blob Storage publishing setup.

## Updating Azure Icons

`packs/azure-icons.json` is a **third-party dependency** sourced from
[NakayamaKento/AzureIcons](https://github.com/NakayamaKento/AzureIcons)
(`azureicons/allicons.json`). It is never modified or hand-edited, and
`build-icon-pack.ps1` never writes to it.

To refresh it:

```
./scripts/update-azure-pack.ps1
```

This downloads the latest pack, validates it is well-formed JSON with an
`icons` collection, backs up the existing file to
`packs/azure-icons.backup.json` (git-ignored), replaces
`packs/azure-icons.json`, and prints the new icon count. Review the diff and
commit `packs/azure-icons.json` if the update looks correct.

## Troubleshooting

**Invalid SVG**
`build-icon-pack.ps1` reports `Invalid SVG structure in '<path>'` when a file
isn't well-formed XML or its root element isn't `<svg>`. Open the file in a
browser or SVG editor to find the malformed markup.

**Missing viewBox**
`Missing viewBox in '<path>'` — every source SVG must declare a `viewBox`
attribute on its root `<svg>` element; add one (e.g. `viewBox="0 0 24 24"`).

**JSON generation failures**
`Empty SVG body` means the SVG has no drawable child elements — check the
file wasn't accidentally exported blank. `Duplicate icon name` means two
source files share a name (case-insensitive); rename one.

**Mermaid icon rendering failures**
If an icon renders blank or as a broken-image glyph, confirm the icon name
used in the diagram (e.g. `application:xap`) matches a key in the pack's
`icons` object exactly, and that the pack was rebuilt after the source SVG
was added.

**Mermaid CLI loading failures**
If a pack fails to load with `Failed to fetch icon` or a browser console
error like `URL scheme "file" is not supported`, the URL passed to
`--iconPacksNamesAndUrls` is a local file path — use the repository's hosted
raw URL instead (see `examples/README.md`). If it fails with a CORS error,
the host isn't sending `Access-Control-Allow-Origin` — GitHub raw content
does by default; an Azure Repos raw URL often won't in a restricted org (see
"Publishing to Azure Blob Storage" in `azureDevOps/README.md` for the
fallback). Also confirm each `prefix#url` pair is a separate CLI argument
rather than comma-joined into one string.
