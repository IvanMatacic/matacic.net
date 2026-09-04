# matacic.net

Personal technical blog and CV of Ivan Matačić — systems administrator working with
virtualization, storage, backup and networking. Built with **Hugo (extended)**, styled by a
small custom theme that lives in this repository (`layouts/`, `assets/`, `static/`), deployed
to **GitHub Pages** by GitHub Actions.

- Design source of truth: `design/matacic-net-mockup.html`
- Tokens, type and components: `assets/css/main.css`
- The only JavaScript: `assets/js/main.js` (theme toggle, mobile menu, code-copy buttons,
  ToC highlight, giscus theme sync) plus a one-line inline snippet in `<head>` that applies
  the saved theme before first paint

## Local development

Requires Hugo **extended** (the version pinned in `.github/workflows/deploy.yml`) — on
Windows `winget install --id Hugo.Hugo.Extended --exact`.

```bash
hugo server -D            # live reload at http://localhost:1313/, drafts included
hugo --gc --minify        # production build into ./public (what CI runs)
hugo --gc --minify --panicOnWarning   # same, but any warning fails the build
```

Analytics, comments and search all stay off in `hugo server` regardless of configuration:
analytics is gated on `hugo.IsProduction`, the other two on their config values.

`scripts/verify.ps1` runs the acceptance checks against `./public` after a production build
(robots/sitemap/llms.txt contents, JSON-LD shape, 13 Credly links, ToC rules, bundle size,
unique titles, no analytics/comments leakage, RSS well-formedness). Note that `hugo server`
renders into `./public` as well, so stop it and rebuild before running the checks.

## Content

### Adding an article

```bash
hugo new writing/my-slug.md
```

Front matter comes from `archetypes/default.md`: `title, date, lastmod, topics, tags, summary,
slug, draft`, plus optional `toc: true` (force the table of contents under 600 words) and
`image:` (a custom Open Graph image under `static/`). Give each article exactly **one topic**
(`topics: ["Homelab"]`) — topics drive `/topics/<topic>/`, the homepage rail and the Homelab
page's post list — and a few lowercase tags. Set `draft: false` to publish. Articles over 600
words get a table of contents (sticky rail on wide screens, collapsible block below 1100px).

### Adding a note

```bash
hugo new notes/my-slug.md
```

Notes use `archetypes/notes.md` (`title, date, tags, summary, slug, draft`). They are short
TIL entries — three to eight sentences, ideally with the one command that matters. Notes have
no topics, no table of contents, no reading time and no comments by design.

### Topic descriptions

The topic archive shows a one-line description when `content/topics/<topic>/_index.md`
exists. Add one per new topic (see `content/topics/homelab/_index.md`).

### Adding a certification

Edit `data/certifications.yaml`. Each item needs `name`, `year` and the Credly badge `id`
(the UUID in the badge's public URL); the About page renders the group, the count chips and
the "Verify ↗" link to `https://www.credly.com/badges/<id>/public_url`. To show a real badge
image, drop the PNG in `static/badges/` and set `image: "badges/<file>.png"` on the item —
see `static/badges/README.md`. The same file feeds the `Person` JSON-LD on `/about/`
(`hasCredential`).

### Homelab and About

- `content/homelab.md` — the hardware table (`hardware:` rows: host · role · specs · notes)
  and the "what runs where" list live in front matter; the intro is the body. Posts with the
  `Homelab` topic are listed automatically.
- `content/about.md` — bio (body), `focus:` list and `experience:` entries (front matter).
  Contact details come from `[params]` in `hugo.toml`.

## Features that are prepared but off

### Search (Pagefind) — three steps

1. In `.github/workflows/deploy.yml`, uncomment the two steps **Setup Node** and
   **Build search index (Pagefind)**.
2. In `hugo.toml`, set `features.search = true` under `[params]`.
3. Push.

The `/search/` page then loads Pagefind's UI from `/pagefind/`, appears in the sitemap and
drops its `noindex` meta. Content is already annotated: `data-pagefind-body` on article and
note bodies, `data-pagefind-ignore` on navigation, footer, table of contents and comments.
Pagefind also ships a newer "Component UI" (`pagefind-component-ui.js`); `layouts/search.html`
uses the classic `PagefindUI` and can be switched later.

### Comments (giscus)

1. Install the [giscus GitHub App](https://github.com/apps/giscus) on the repository.
2. Enable **Discussions** in the repository settings and create a category (e.g.
   *Announcements*).
3. Open <https://giscus.app>, enter the repository, pick the category and `pathname` mapping,
   and copy the four values into `hugo.toml` → `[params.giscus]`: `repo`, `repoId`,
   `category`, `categoryId`.

Comments then appear at the bottom of articles only (not notes). The giscus theme follows the
site theme, including live toggles.

### Analytics

**Cloudflare Web Analytics (recommended).** Free, cookieless, no consent banner, works on
GitHub Pages without moving DNS to Cloudflare. In the Cloudflare dashboard open *Web
Analytics → Add a site*, choose the JS snippet option and copy the token into
`params.cloudflareAnalyticsToken`. The beacon is emitted only in production builds.

**GA4 (optional).** Set `services.googleAnalytics.ID` (a `G-…` ID). GA4 sets cookies, which in
the EU implies a consent banner — this site has none, so prefer the Cloudflare option.

Both values are empty in the committed config; nothing is emitted until one is set.

## Crawlers, sitemap, llms.txt

- `robots.txt` (from `layouts/robots.txt`) allows everything, including AI crawlers
  (GPTBot, ClaudeBot, PerplexityBot, Google-Extended) **on purpose** — the site exists for
  reach, not ad revenue. To opt out later, change `Allow` to `Disallow` for those agents.
  It also points at the absolute sitemap URL.
- `sitemap.xml` is generated by `layouts/sitemap.xml` and lists every page except the
  `/search/` placeholder while search is off.
- `llms.txt` is a Hugo output format (`layouts/home.llms.txt`) regenerated on every build:
  a Markdown index of all articles, notes and the two static pages with absolute URLs. Honest
  footnote: llms.txt is a *proposed* convention with no confirmed vendor consumption and no
  demonstrated traffic benefit. It is included because it is free and self-maintaining;
  crawler control lives in `robots.txt`.
- After launch, submit `https://matacic.net/sitemap.xml` in Google Search Console
  (URL-prefix property, verify by DNS TXT record or HTML meta tag).

## Open Graph images

`static/og-default.png` (1200×630) is the site-wide card. It was generated once by
`scripts/make-og.ps1` (Windows PowerShell + System.Drawing, uses
`assets/fonts/IBMPlexMono-Medium.ttf` and `static/icon-server.png`) and is committed — it is
**not** rebuilt on every deploy. Re-run the script only if the wordmark or role line changes.

Articles get their own card at build time: Hugo's `images.Text` draws the title over
`assets/og-base.png` (see `layouts/_partials/seo.html`). An article can override this with
`image:` in its front matter.

## Deployment

The workflow in `.github/workflows/deploy.yml` runs on every push to `main` (and manually
via *Run workflow*): installs the pinned Hugo extended release, builds with
`hugo --gc --minify --panicOnWarning --baseURL "https://matacic.net/"`, uploads `public/`
and deploys it with `actions/deploy-pages`.

One-time repository setup:

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. **Settings → Pages → Custom domain:** `matacic.net`, then enable **Enforce HTTPS** once
   the certificate is issued (can take up to 24 h). With Actions-based deploys GitHub reads
   the domain from this setting; `static/CNAME` is kept for reference only.

### DNS for the apex domain

> Verify the current GitHub Pages IPs against GitHub's docs before relying on them:
> <https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site>

| Type  | Name  | Value |
|-------|-------|-------|
| A     | `@`   | `185.199.108.153` |
| A     | `@`   | `185.199.109.153` |
| A     | `@`   | `185.199.110.153` |
| A     | `@`   | `185.199.111.153` |
| AAAA  | `@`   | `2606:50c0:8000::153` |
| AAAA  | `@`   | `2606:50c0:8001::153` |
| AAAA  | `@`   | `2606:50c0:8002::153` |
| AAAA  | `@`   | `2606:50c0:8003::153` |
| CNAME | `www` | `<username>.github.io.` |

If DNS is hosted on Cloudflare, keep these records **DNS only** (grey cloud) so GitHub can
issue the certificate.

### Email via Cloudflare Email Routing (free)

GitHub Pages provides no mailbox, so `mailto:` links are dead until a mail host exists.
Add `matacic.net` to Cloudflare as a DNS zone (DNS can live on Cloudflare while hosting
stays on GitHub Pages), open **Email → Email Routing**, create a custom address that forwards
to a personal inbox, and let Cloudflare add the MX and SPF records.

## Old domain (mata.com.hr)

Keep it registered for one to two more years, put it behind Cloudflare and create **301
Redirect Rules** from the old URLs to their new equivalents on `matacic.net`, then use
**Search Console → Change of Address**. Otherwise the new domain starts from zero in Google.
