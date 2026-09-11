# examples

`architecture-example.mmd` is a Mermaid `architecture-beta` diagram that mixes
the `azure` and `application` icon packs. There is no pre-rendered `.svg`
committed here — render it from the pushed repository as described below.

## Rendering it

Requires Node.js, and this repository pushed to a Git host so `packs/*.json`
is reachable over `https`.

**`--iconPacksNamesAndUrls` cannot load a local file path.** Mermaid CLI
renders inside headless Chrome and loads each icon pack with the browser's
`fetch()` API, which unconditionally refuses the `file:` scheme — this fails
the same way whether you pass a relative path, an absolute path, or an
absolute `file://` URL. Point it at the pack's hosted raw URL instead.

`--iconPacksNamesAndUrls` accepts one or more `prefix#url` pairs as
**separate command-line arguments** — joining multiple pairs into a single
comma-separated string does not work either; Mermaid CLI splits each
argument on `#` only, so a comma-joined string is parsed as one malformed URL.

### From GitHub

```
npx @mermaid-js/mermaid-cli \
  -i examples/architecture-example.mmd \
  -o examples/architecture-example.svg \
  --iconPacksNamesAndUrls "azure#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/azure-icons.json" "application#https://raw.githubusercontent.com/JaiSpicer/Mermaid-Architecture-Icons/main/packs/application-icons.json"
```

`raw.githubusercontent.com` sends `Access-Control-Allow-Origin: *`, so this
works as-is once the repo is pushed and public (or the URL is otherwise
reachable, e.g. with a token query param for a private repo).

### From Azure DevOps (Azure Repos)

```
npx @mermaid-js/mermaid-cli \
  -i examples/architecture-example.mmd \
  -o examples/architecture-example.svg \
  --iconPacksNamesAndUrls "azure#https://dev.azure.com/<org>/<project>/_apis/git/repositories/<repo>/items?path=/packs/azure-icons.json&api-version=7.1&%24format=octetStream" "application#https://dev.azure.com/<org>/<project>/_apis/git/repositories/<repo>/items?path=/packs/application-icons.json&api-version=7.1&%24format=octetStream"
```

Replace `<org>`, `<project>`, and `<repo>` with your Azure DevOps values.
Two things to check if this fails, neither of which apply to the GitHub form:

- The repository (or at least anonymous read on this path) must be
  accessible without an `Authorization` header — Mermaid CLI's icon pack
  loader has no way to attach credentials to the request.
- Azure Repos' raw item endpoint may not send
  `Access-Control-Allow-Origin`, which headless Chrome's `fetch()` requires
  for a cross-origin request from the page's `null`/`file:` origin.

In a typical enterprise/network-restricted Azure DevOps org, expect one or
both of these to block this form entirely (anonymous item access is usually
disabled by policy) — use Azure Blob Storage instead.

### From Azure Blob Storage

```
npx @mermaid-js/mermaid-cli \
  -i examples/architecture-example.mmd \
  -o examples/architecture-example.svg \
  --iconPacksNamesAndUrls "azure#https://<account>.blob.core.windows.net/<container>/azure-icons.json" "application#https://<account>.blob.core.windows.net/<container>/application-icons.json"
```

Replace `<account>` and `<container>` with your storage account and
container name. This is the recommended path for a network-restricted org —
see "Publishing to Azure Blob Storage" in `azureDevOps/README.md` for the
one-time storage account/CORS/service-connection setup and the (untested,
disabled-by-default) pipeline step that publishes to it automatically. The
storage account's CORS rule must allow `GET` from origin `*` for the same
reason as above — there's no way to scope it to Mermaid CLI's actual
`null`/`file:` origin.
