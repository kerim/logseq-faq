# logseq-faq

This is the operating manual for publishing the "Unofficial Logseq FAQ" site.
It covers the everyday routine, first-time setup, how to change the site's
look and behavior, hosting, local preview, and troubleshooting.

## 1. What this is

Kerim writes in Logseq, in a database ("DB") graph. Logseq's **File → Export
public pages** feature dumps the pages marked public as static HTML into this
repo's `export/` folder. The **builder** — a Git submodule pointing at branch
`kerim-theme` of [kerim/garden](https://github.com/kerim/garden) (Kerim's
personal fork of [Arney1/garden](https://github.com/Arney1/garden)) — turns
that export into a finished website (`dist/`). A GitHub Actions workflow
builds the site and deploys it to **GitHub Pages**, publishing it at
<https://kerim.github.io/logseq-faq/>.

In short: **Logseq → export/ → builder → GitHub Actions → GitHub Pages →
kerim.github.io/logseq-faq/.**

## 2. Publishing a change (the everyday routine)

1. Edit and mark pages public as usual in Logseq.
2. In Logseq: **File → Export public pages**, and point it at
   `~/Code/logseq-faq/export` (replacing what's there).
3. Wait about 1–2 minutes.

That's it in the normal case, because the **watcher** — a background job
(`launchd` job `net.oxus.logseq-faq-publish`, when installed — see section
3) — notices the change to `export/`, builds the site, and commits and
pushes it automatically. You don't have to run anything yourself.

To check that it worked:

- Log file: `~/Library/Logs/logseq-faq-publish.log` — records the watcher's
  own actions (triggered, debounced, published, or failed).
- GitHub Actions: the repo's Actions tab shows whether the deploy to GitHub
  Pages succeeded.

**Manual alternative.** If you don't want to wait for the watcher, or it
isn't installed, run `./publish.sh` yourself from `~/Code/logseq-faq`. It
builds locally first, so a broken export fails on your machine instead of
reaching the live site.

**If the browser still shows the old page:** hard-reload it (e.g.
`Cmd+Shift+R` in most browsers) — this is ordinary browser caching, not a
publish failure.

**Logseq export gotcha:** if the export fails with a `copyfile ENOENT`
error, it's a stale Logseq temp file (only purged after the app has been
running for several days). Quit and relaunch Logseq, then export again.

## 3. First-time setup on a new Mac / for a collaborator

Requirements: `git`, `python3` 3.10 or newer, and `node`.

Clone with submodules, since the builder is a submodule and won't come along
otherwise:

```sh
git clone --recurse-submodules <this repo's URL>
cd logseq-faq
```

Point Logseq's "Export public pages" at `<clone>/export` (i.e. the `export/`
folder inside wherever you cloned this repo).

Then either:

- Run `./publish.sh` by hand each time you export, or
- Install the watcher so it happens automatically:

  ```sh
  launchctl bootstrap gui/$(id -u) ~/Code/logseq-faq/watch/net.oxus.logseq-faq-publish.plist
  ```

  If your clone is **not** at `~/Code/logseq-faq`, first edit the paths in
  `watch/net.oxus.logseq-faq-publish.plist` (the `ProgramArguments` and
  `WatchPaths` entries) and `watch/logseq-faq-publish` (the `REPO_DIR`
  variable) to match your clone's location.

  To remove the watcher later:

  ```sh
  launchctl bootout gui/$(id -u) ~/Code/logseq-faq/watch/net.oxus.logseq-faq-publish.plist
  ```

A collaborator needs **write access to the GitHub repo** (so `publish.sh`
can push). No secrets are needed — deployment happens automatically from
GitHub Actions using GitHub Pages' own built-in `id-token`/`pages`
permissions; there is nothing to store or rotate.

## 4. Changing how the site looks or behaves

Most changes are **configuration**, edited in this repo's `site.json`; a
smaller set are **code**, changed in the builder fork.

### Configuration: `site.json`

| Key | What it controls |
| --- | --- |
| `title` | The site's title. |
| `home_page` | Which page is the homepage. |
| `description` | Site description (meta tags, etc). |
| `url` | The canonical site URL. |
| `base_path` | The path prefix the site is served under (`/logseq-faq` for GitHub Pages project sites). |
| `language` | Site language code. |
| `navigation` | The list of top-level section pages shown in the sidebar/menu (empty here — see below). |
| `navigation_page` | The page whose links define the navigation entries when `navigation` is empty. |
| `navigation_label` | Optional label override for a navigation entry. |
| `url_style` | `"sections"` groups page URLs under whichever navigation entry links to them (e.g. `/topic/page/`); the default `"uuid"` gives every page a flat `/page/<slug>--<uuid>/` URL. |
| `embed_titles` | Whether embedded pages/blocks show a title link above them (only matters when `embed_style` is `"boxed"`). |
| `embed_style` | `"boxed"` (default) draws a box with a title around embedded pages/blocks; `"inline"` renders them as plain sub-blocks with no box, title, or bullet. |
| `author` | Shown in the sidebar license note. |
| `license` | License name shown in the footer/sidebar; known names like `"CC BY 4.0"` are auto-linked. |
| `theme_css` | The CSS file (in this repo) used to skin the site — `theme.css` here, a Sanctum-inspired reskin. |
| `exclude_pages` | Pages to omit from the build even though they're present in the export. |

Edit `site.json` directly in this repo, commit, and push (or let the next
`publish.sh` run pick it up) — no submodule update needed.

### Code: the builder fork

Anything beyond what `site.json` can control — new rendering behavior, CSS,
new features — is a change to the generator itself, made in `~/Code/garden`
(Kerim's fork, on branch `kerim-theme`), not in this repo.

Once a change lands upstream in `kerim-theme`, pull it into this repo's
`builder/` submodule and record the new pointer:

```sh
cd builder
git pull origin kerim-theme
cd ..
git add builder
git commit -m "Update builder submodule"
git push
```

### The theme: `theme.css`

`theme.css` is a from-scratch port of Sanctum's palette and typography
(warm off-white background, serif type, a muted terracotta accent, a light
sidebar instead of a dark panel, and a matching dark variant) onto the exact
set of selectors the builder's HTML requires. It keeps every selector from
the builder's own default `theme.css` working; only colors and fonts change.

## 5. Hosting

The site is served by **GitHub Pages**, using the Actions deployment source
(not the classic branch-based source). Deployment is handled by
`.github/workflows/deploy.yml`, which runs on every push to `main` (or
manually via `workflow_dispatch`): it builds the site and uploads `dist/`
via `actions/upload-pages-artifact` and `actions/deploy-pages`.

No secrets are required. Pages must be switched to the "GitHub Actions"
build type once, either in the repo's **Settings → Pages** UI, or via:

```sh
gh api -X POST repos/kerim/logseq-faq/pages -f build_type=workflow
```

## 6. Local preview

From this repo:

```sh
./build.sh
./preview.sh
```

Then open <http://localhost:8002/logseq-faq/> in a browser. The site uses
`base_path: "/logseq-faq"`, matching how GitHub Pages serves a project site
under `https://kerim.github.io/logseq-faq/` — so plain
`python3 -m http.server --directory dist` won't resolve the site's absolute
links correctly. `preview.sh` instead serves a temporary directory
containing a `logseq-faq` symlink to `dist`, so every `/logseq-faq/...` link
resolves exactly as it will in production. Pass a port as the first
argument (default `8002`) if that port is busy.

## 7. Troubleshooting

**The watcher didn't fire.**
Check the log first:

```sh
tail -50 ~/Library/Logs/logseq-faq-publish.log
```

Then check whether the job is actually loaded:

```sh
launchctl print gui/$(id -u)/net.oxus.logseq-faq-publish
```

If it's not loaded, install it (see section 3). If it's loaded but silent,
re-export from Logseq to re-trigger it, or just run `./publish.sh` manually.

**Build warnings.**
After a build, check `dist-report.json` (next to `dist/`, not deployed with
the site) — it records page/attachment counts, sizes, and any warnings from
the build.

**A GitHub Actions run failed.**
From this repo, with the `gh` CLI:

```sh
gh run list
gh run view --log-failed
```

**Pages shows a 404 or the old build.**
Confirm the repo's **Settings → Pages** source is set to "GitHub Actions"
(not "Deploy from a branch"), and check the latest run in the Actions tab
succeeded. GitHub Pages can also take a minute or two to propagate after a
successful deploy.
