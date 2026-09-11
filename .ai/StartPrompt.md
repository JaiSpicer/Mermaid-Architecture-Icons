## Objective

Provide a reusable, extensible repository for Mermaid CLI (mmdc) architecture diagram icon packs.

The solution must support:

- Azure Architecture Icons
- Custom Icons
- Future icon packs (vendor, application, integration, etc.)
- Local SVG source files
- Automated icon pack generation
- Azure DevOps repository hosting
- Azure DevOps pipeline integration

The repository will be consumed by Mermaid CLI using:

npx mmdc ^
-i diagram.mmd ^
-o diagram.svg ^
--iconPacksNamesAndUrls "azure#./packs/azure-icons.json,custom#./packs/custom-icons.json"

Example Mermaid usage:

service funcapp(azure:function-apps)[Function App]
service kv(azure:key-vaults)[Key Vault]

service xap(custom:xap)[Xap]
service sendgrid(custom:sendgrid)[SendGrid]

## Repository Structure

Mermaid-Icon-Packs/
│
├── README.md
│
├── packs/
│ ├── azure-icons.json
│ └── custom-icons.json
│
├── source/
│ ├── custom/
│ │ ├── xap.svg
│ │ ├── sendgrid.svg
│ │ ├── genesys.svg
│ │ ├── surveymonkey.svg
│ │ ├── successfactors.svg
│ │ ├── care-for-kids.svg
│ │ └── README.md
│ │
│ ├── vendor/
│ │ └── README.md
│ │
│ ├── application/
│ │ └── README.md
│ │
│ └── integration/
│ └── README.md
│
├── scripts/
│ ├── build-icon-pack.ps1
│ ├── update-azure-pack.ps1
│ └── shared/
│
├── examples/
│ ├── architecture-example.mmd
│ ├── architecture-example.svg
│ └── README.md
│
├── azure/
│ └── README.md
│
└── pipelines/
└── azure-pipelines.yml

## Azure Icon Pack Requirements

The repository will include a local copy of the Azure icon pack sourced from:

https://github.com/NakayamaKento/AzureIcons

Specifically:

https://github.com/NakayamaKento/AzureIcons/blob/main/azureicons/allicons.json

Requirements:

- Store locally as packs/azure-icons.json
- Treat as a third-party dependency
- Never modify during custom pack builds
- Document source and update process
- Provide update-azure-pack.ps1 script

update-azure-pack.ps1 should:

1. Download the latest Azure pack
2. Validate JSON format
3. Backup existing pack
4. Replace packs/azure-icons.json
5. Output icon count summary

## Custom Icon Pack Requirements

Create build-icon-pack.ps1.

Purpose:

Generate packs/custom-icons.json from SVG files stored in source/custom.

Requirements:

1. Scan source/custom for SVG files.
2. Use file name without extension as icon name.
3. Parse SVG structure.
4. Extract:
   - viewBox
   - width
   - height
   - body content
5. Generate a Mermaid/Iconify compatible icon pack.
6. Save to:
   packs/custom-icons.json
7. Sort icons alphabetically.
8. Overwrite previous output.
9. Preserve source files.
10. Support future pack generation.

Generated output format:

{
"prefix": "custom",
"icons": {
"sendgrid": {
"body": "<path ... />",
"width": 24,
"height": 24
}
}
}

## Future Pack Support

Design build-icon-pack.ps1 so it supports:

build-icon-pack.ps1 -PackName custom
build-icon-pack.ps1 -PackName vendor
build-icon-pack.ps1 -PackName application
build-icon-pack.ps1 -PackName integration

Expected future outputs:

packs/custom-icons.json
packs/vendor-icons.json
packs/application-icons.json
packs/integration-icons.json

The solution must be extensible without code changes.

## Validation Requirements

Validate:

- Duplicate icon names within a pack
- Missing SVG files
- Invalid SVG structure
- Missing viewBox
- Empty SVG body
- Invalid JSON output

Additionally:

Load azure-icons.json and validate that no icon names conflict when using the same prefix.

Produce validation output:

[INFO] Azure Icons: 1300
[INFO] Custom Icons: 6
[INFO] Duplicate Names: 0
[INFO] Validation Successful

## Build Output

Produce verbose logging:

[INFO] Mermaid Icon Pack Build
[INFO] Pack Name: custom
[INFO] Source Folder: source/custom
[INFO] Found 6 SVG files

[INFO] Processing xap.svg
[INFO] Processing sendgrid.svg
[INFO] Processing genesys.svg
[INFO] Processing surveymonkey.svg
[INFO] Processing successfactors.svg
[INFO] Processing care-for-kids.svg

[INFO] Generated packs/custom-icons.json

[INFO] Icons Generated: 6
[INFO] Duration: 3.2 seconds
[INFO] Validation Successful

## Command Wrapper

Create:

scripts/build-icon-pack.ps1

Usage:

build-icon-pack.ps1 custom

## Mermaid CLI Examples

Document usage:

npx mmdc ^
-i diagram.mmd ^
-o diagram.svg ^
--iconPacksNamesAndUrls "azure#./packs/azure-icons.json,custom#./packs/custom-icons.json"

Example Mermaid:

architecture-beta

service funcapp(azure:function-apps)[Function App]
service kv(azure:key-vaults)[Key Vault]

service xap(custom:xap)[Xap]
service sendgrid(custom:sendgrid)[SendGrid]

## Azure DevOps Pipeline

Create:

pipelines/azure-pipelines.yml

Pipeline must:

1. Validate all icon packs.
2. Generate custom-icons.json.
3. Verify azure-icons.json.
4. Publish:

   packs/custom-icons.json
   packs/azure-icons.json

5. Publish build summary.

## README Requirements

Include:

### Purpose

Repository overview.

### Supported Packs

- Azure
- Custom

### Future Packs

- Vendor
- Application
- Integration

### Repository Structure

Fully document all folders.

### Adding a New Icon

1. Export logo as SVG.
2. Place SVG in source/custom.
3. Run build-icon-pack.ps1.
4. Commit generated icon pack.

### Mermaid Usage

Examples for:

- Azure icons
- Custom icons
- Mixed diagrams

### Azure DevOps Integration

Example CI usage.

### Updating Azure Icons

How to refresh the Azure icon pack.

### Troubleshooting

Common issues:

- Invalid SVG
- Missing viewBox
- JSON generation failures
- Mermaid icon rendering failures
- Mermaid CLI loading failures

## Solution Quality Requirements

Generate production-quality code.

Use:

- PowerShell 7+
- Comment-based help
- Parameter validation
- Error handling
- Logging functions
- Pipeline-friendly exit codes

Assume the repository will become the central enterprise repository for Mermaid icon packs and should be maintainable, extensible, and well documented.
