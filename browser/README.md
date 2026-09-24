# IMPACT code browser

A static, dependency-free browser of `codelist/master_codelist.csv`. It includes multiple-selection filters, code/description search, exact code matching, sorting, pagination, shareable filter URLs and CSV downloads. Authors, citation, DOI and acknowledgements are included in the page.

## Preview locally

From the repository root, using Python 3.10 or later:

```sh
python buildfile.py --target browser
python -m http.server 8765 --bind 127.0.0.1 --directory browser
```

Open http://127.0.0.1:8765. Use an HTTP server rather than opening `index.html` directly. The browser target needs only Python's standard library; R, pandas and Node are not required to build or serve it. The existing package targets retain their dependencies. A normal `--target all` build also generates browser resources; `--resources-only` retains its existing R/Python scope.

Use a current Chrome, Edge, Firefox or Safari supporting module workers and `DecompressionStream`. Assets are served locally with no third-party scripts, fonts, analytics or runtime CDN dependencies.

## Deploy to GitHub Pages

1. Review and commit `buildfile.py`, `browser/`, `tests/test_browser.py`, `.gitignore`, the README changes and `.github/workflows/pages.yml`. Generated `browser/data/` files are intentionally ignored; GitHub Actions rebuilds them from the committed master CSV.
2. Push the reviewed changes to `main` yourself. If your default branch has a different name, change `branches: [main]` in the workflow first.
3. In the repository, open **Settings → Pages**. Under **Build and deployment**, select **GitHub Actions** as the source. You need permission to change repository settings, and Actions must be enabled.
4. Open **Actions → Build and deploy code browser → Run workflow**, select `main` and run it. This is useful if the initial push ran before Pages was enabled.
5. Once the build and deployment succeed, follow the URL in the deployment or **Settings → Pages**. For `jonathanbatty/impact`, the expected URL is https://jonathanbatty.github.io/impact/.

Subsequent pushes to `main` that change the browser, master CSV, builder, tests or workflow regenerate and redeploy the site. Other package-only changes do not trigger deployment. The workflow deploys only the `browser` folder, and paths work under a repository subdirectory. It requires no personal access token; it uses GitHub's built-in token with Pages permissions scoped to the deployment job. No deployment occurs merely by running the local builder.

If deployment is awaiting approval, inspect the repository's `github-pages` environment rules. If a file returns 404, check that the build step ran and the artifact contains `data/manifest.json`. If Pages is already hosting another site from this repository, this workflow will replace that site's content when deployed.

GitHub reference: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages

## Data and performance

The builder creates a small manifest plus one gzip-compressed JSON partition per phenotype. Arrays avoid repeating column names. Every source field remains a string; duplicates, blank fields, whitespace and source row order are preserved. Each row includes an internal ordinal, omitted from exports. Inconsistent phenotype metadata is rejected so partition pruning cannot hide rows.

The initial page loads only the manifest and interface. Filters select relevant partitions using catalogue metadata, with at most six concurrent downloads. Gzip is decoded explicitly, so hosting does not need to set `Content-Encoding`. Completed partitions are cached for the session. A web worker handles filtering, sorting and export generation, while the table renders only the current page. Changing a search cancels obsolete downloads and ignores obsolete results.

For the current 194,409-row source, the manifest is 54,119 bytes, all compressed partitions together are 3,161,493 bytes, and the largest partition is 433,900 bytes. These are generated file sizes, not network timing benchmarks.

An unrestricted search or “Browse all codes” downloads all partitions the first time. Once loaded, subsequent searches use the cache. This trades some memory for responsiveness. There is no promise of constant-time full-text search: each query scans the relevant cached rows. The current source produces 116 partitions; reassess partition sizing if the codelist grows substantially.

Content-addressed filenames prevent cached partitions from being mistaken for newer data. The manifest is revalidated on page load, includes the source SHA-256, and is replaced only after all files have been written. Old partitions are retained on local rebuilds to support already-open pages; CI builds start clean. Reload an old page if its data becomes unavailable after deployment.

Filters use OR within a field and AND across fields. Sex applicability filters match source labels literally: “female only” does not include “either”. Text search matches a literal, case-insensitive substring in code or description; exact mode searches the whole code only. Sorting codes is lexical to preserve their string semantics.

CSV export includes all matching rows and all original columns in their original order. Distinct-code export requires exactly one coding system and includes just the unique matching code strings. CSV quoting preserves commas, quotation marks, newlines and Unicode. Spreadsheet applications can infer numeric or formula types despite CSV quoting; use text import to retain identifiers faithfully. The browser does not alter source values to impose spreadsheet-specific formatting.

The citation is the project's software citation from the repository README. The displayed source hash and export filenames separately identify the exact CSV used. When updating authorship, version or citation, update `index.html` alongside the project README.

## Verification

```sh
python -m unittest discover -s tests -p 'test_browser.py'
python buildfile.py --target browser
node browser/query.test.mjs
```

Python tests round-trip every source row, check deterministic generation, reject conflicting metadata, and cover duplicates, leading zeroes, long identifiers, blank values, Unicode, quotes and newlines. Node 22+ tests run the actual worker against generated partitions and check filtering, exact matching, full-result export, pagination, caching and stale result suppression. No npm installation is needed.
