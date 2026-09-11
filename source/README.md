# source

Hand-authored SVG inputs for every icon pack, one subfolder per pack name.
The folder name *is* the pack name: `scripts/build-icon-pack.ps1 <name>`
reads every `*.svg` in `source/<name>/` and writes `packs/<name>-icons.json`.

**A new folder here is a new icon pack, automatically — no script or
pipeline changes required.** `build-icon-pack.ps1` takes the pack name as a
parameter rather than hardcoding one, and `pipelines/azure-pipelines.yml`
builds every folder under `source/` on each run (it lists the folders at
build time, it doesn't name them). So creating `source/vendor/`, adding SVGs,
and running `./scripts/build-icon-pack.ps1 vendor` is the entire process for
introducing a `vendor` pack — nothing elsewhere in the repo needs to know it
exists in advance.

Currently:

- `application/` — the active application icon pack.

## Adding icons to an existing pack

1. Export the logo/graphic as a single, standalone SVG file.
2. Ensure the root `<svg>` element has a `viewBox` attribute (required —
   the build script rejects SVGs without one).
3. Name the file `<icon-name>.svg` using lowercase, kebab-case. The file name
   (without extension) becomes the icon's name, e.g. `xap.svg` in
   `source/application/` becomes `application:xap` in a diagram.
4. Place the file in `source/<pack-name>/`.
5. Run `./scripts/build-icon-pack.ps1 <pack-name>` from the repository root.
6. Commit the source SVG and the regenerated `packs/<pack-name>-icons.json`.

### Requirements for source SVGs

- Single root `<svg>` element with a `viewBox`.
- No embedded raster images (PNG/JPEG) — vector paths/shapes only.
- No duplicate file names (case-insensitive) within the same pack folder.

## Adding a new pack

1. Create `source/<new-pack-name>/` and add one or more `*.svg` files
   following the requirements above.
2. Run `./scripts/build-icon-pack.ps1 <new-pack-name>`.
3. Commit the source SVGs and the generated
   `packs/<new-pack-name>-icons.json`.

The next `pipelines/azure-pipelines.yml` run will pick up the new folder and
build/validate it along with every other pack, with no pipeline edit needed.
