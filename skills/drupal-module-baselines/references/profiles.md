# The four site profiles

Everything here is *in addition to* the universal baseline in `SKILL.md`.

---

## Profile A — Public hosted site (DB + public traffic)

The default case: real webserver, real database, anonymous visitors, search
engines, spam bots, and an uptime expectation.

### Required

| Module | Why |
|---|---|
| **Metatag** | Meta descriptions, Open Graph, Twitter Cards, canonical URLs, driven by tokens off the entity. Without it, every share looks broken and indexation is guesswork. |
| **Simple XML Sitemap** | Generated sitemap.xml with per-bundle control. Search engines expect it. |
| **Google Tag** (or your analytics equivalent) | Analytics injection with role/path exclusion, so admin traffic doesn't pollute data. |
| **Honeypot** and/or **Antibot** | Spam prevention without a CAPTCHA. Do this before reaching for reCAPTCHA — it's less hostile to users and has no third-party dependency. |
| **Backup and Migrate** *or* host-level backups | You need a restore path. If the host provides one (see Platform note below), use theirs and skip the module. |
| **Seckit** | Security headers — CSP, HSTS, X-Frame-Options, referrer policy. Cheap and it closes a real class of finding in any audit. |
| **Password Policy** + **TFA** | If the site has more than a couple of editor accounts. TFA on every admin-role account should be the default posture, not an upsell. |
| **Klaro** (or equivalent consent manager) | Cookie/tracking consent. A legal requirement for EU-reachable sites (EAA enforceable since June 2025, extraterritorial). Klaro is what Drupal CMS ships; it has superseded EU Cookie Compliance in modern builds. |
| **Editoria11y** | In-context accessibility checker for content authors — catches the fake-headings/"click here"/missing-alt class of problem where most post-launch a11y findings live. |

### Strongly recommended

- **Purge** + **Varnish Purge** / **CloudFlare** — cache invalidation. Without
  this, an external cache serves stale pages and everyone blames Drupal.
- **Search API** + **Search API Solr** (or Database backend for small sites) —
  core search is weak past a few thousand nodes.
- **Focal Point** or **Image Widget Crop** — editors need control over cropping
  in responsive image styles.
- **Easy Breadcrumb** — derives breadcrumbs from the path, which core doesn't.
- **Linkit** — autocomplete internal links in CKEditor as entity references, so
  they survive alias changes.
- **Scheduler** — publish/unpublish at a time. Editors always eventually need it.
- **Environment Indicator** — a coloured bar so nobody edits prod thinking it's
  staging. Sounds trivial, prevents real incidents.
- **ECA** — visual (BPMN) automation. The replacement for Rules. Use it before
  writing a custom module for "when X happens, do Y".
- **Upgrade Status** — run it quarterly, not just at upgrade time.
- **Schema.org Metatag** — JSON-LD structured data on top of Metatag, when rich
  results matter.
- **Blazy** — lazy-loading for image/video-heavy pages (core covers basic
  `loading="lazy"`; Blazy earns its keep on galleries and embeds).
- **SVG Image** — core image fields still don't take SVGs.
- **Diff** + **Entity Usage** — revision comparison and "where is this media/
  paragraph used?", both questions editors ask within the first month.
- **Stage File Proxy** — dev/staging fetches prod files on demand instead of
  syncing a giant files directory. Dev environments only.
- **Devel** — debugging; require with `--dev` and never enable in prod.
- **Username Enumeration Prevention** — cheap hardening on the login/reset forms.

### Performance / caching posture

Enable core page cache + dynamic page cache + BigPipe. Then a reverse proxy
(Varnish/Fastly/Cloudflare) driven by cache tags via Purge. Get cache tags right
in your custom code — see `drupal-standards` → `frontend.md` on render-array
drilling, which is the usual reason invalidation silently stops working.

### If hosted on a platform (Acquia / Pantheon / Platform.sh)

The platform supplies the caching layer, CDN, backups, and often the Solr
instance. **Do not duplicate them.**

- Skip Backup and Migrate — use platform backups, and *test a restore*.
- Use the platform's purge integration (`acquia_purge`, `pantheon_advanced_page_cache`)
  rather than generic Varnish Purge.
- Read-only filesystem in production on some platforms: anything writing outside
  the files directory will fail at deploy, not at review.
- Config split per environment is effectively mandatory; the platform's env vars
  drive it.
- Their PHP version and Composer constraints override your preferences. Check
  before promising a core version.

---

## Profile B — Static generated site (Tome)

Drupal is a build tool here. It runs on the developer's machine or in CI,
generates HTML, and the generated output is what's deployed. There is no
database, no PHP, and no Drupal in production.

**Version warning:** as verified 2026-08-10, Tome's stable release is
**8.x-1.16**, supporting `^10 || ^11` — **no Drupal 12 constraint yet**, and the
project is flagged *minimally maintained / maintenance fixes only* (feature
complete by design, security-team covered). Confirm the current constraint before
planning a Drupal 12 move on a Tome site — this is the most likely thing to block
that upgrade. Docs: tome.fyi.

### Required

- **Tome** (`tome_static`, `tome_sync`) — the static generator and the
  content-to-filesystem sync that replaces the database.
- **Metatag**, **Simple XML Sitemap** — same reasons as Profile A. They run at
  build time and bake into the output.
- **Redirect** — Tome can emit redirects as static files; you still need the
  aliases managed.

### Deliberately omit

Anything that only makes sense with a live PHP request:

- ❌ Caching/purge modules (Purge, Varnish, BigPipe tuning) — nothing to cache.
- ❌ Honeypot, Antibot, CAPTCHA — no server to post to.
- ❌ Backup and Migrate — your git repo *is* the backup, because `tome_sync`
  writes content to JSON files on disk.
- ❌ Session/flood/rate-limit modules.
- ❌ Anything doing runtime cron work.

### What breaks and what to do instead

| Need | Static answer |
|---|---|
| Contact / any form | Third-party endpoint — Netlify Forms, Formspree, a serverless function. **Webform will not work.** Decide this at architecture time, not at launch. |
| Search | Client-side index — Lunr.js, Pagefind, or a hosted service (Algolia). Search API/Solr are out. |
| Comments | Third-party (Giscus, Disqus) or none. |
| Personalisation / logged-in views | Not possible. If the site needs it, it isn't a static site. |
| Anything time-based (scheduled publish) | A scheduled CI rebuild, not Scheduler. |

### Workflow

Content lives in git as `tome_sync` JSON. Editors either run Drupal locally, or
you keep a small authoring instance and treat static as the publish target. Build
in CI on push; deploy the `html/` output to Netlify/Pages/S3. Confirm which of
these the user has before recommending modules — "static Drupal" covers two quite
different setups.

---

## Profile C — Private / internal site

Intranet, extranet, internal tool. No anonymous access. The threat model and the
priorities invert: authentication and audit matter, SEO and spam don't.

### Required

| Module | Why |
|---|---|
| **A real auth integration** — `simplesamlphp_auth`, `openid_connect`, `cas`, or `ldap` | Do not run local Drupal accounts for an internal tool. SSO is the whole security posture. |
| **Seckit** | Headers still matter behind a VPN. |
| **Login Security** or **Flood Control** | Lockout and throttling on whatever local login remains. |
| **Password Policy** | If any local accounts exist at all. |
| **Backup and Migrate** or host backups | Internal data is usually the *least* backed-up and the most irreplaceable. |
| **Content Access** / **Group** / **Permissions by Term** | Real per-department or per-team access control. `Group` when "who can see what" is organisational; `Permissions by Term` when it maps cleanly to an existing taxonomy. |

### Strongly recommended

- **Environment Indicator** — internal sites get cloned constantly.
- **Search API** (database backend is fine at internal scale) — internal sites
  are usually document dumps, and findability is the main complaint.
- **VBO (Views Bulk Operations)** — admin-heavy sites need bulk actions.
- **Masquerade** — support staff need to reproduce "it looks wrong for me".
- **Audit / logging**: keep `dblog` on (unlike a high-traffic public site where
  you'd move to syslog), and consider **Config Log** or **Diff** so config
  changes are traceable.
- **Autologout** — usually a compliance requirement, and cheap to add up front.

### Deliberately omit

- ❌ Metatag, XML Sitemap, analytics tags — no crawler, and analytics on an
  internal tool is often a privacy problem.
- ❌ Honeypot / CAPTCHA — no anonymous posting surface.
- ❌ External CDN. Also: **no external asset requests at all** — no Google Fonts,
  no CDN-hosted JS. Vendor everything locally. This is frequently a hard
  requirement and is much cheaper to do from day one.

### Posture notes

Turn off anonymous access at the permission level *and* at the webserver/VPN
level — don't rely on one. `user.settings` register should be
`admin_only`. Verify error reporting is off and `trusted_host_patterns` is set,
same as a public site; internal doesn't mean unexposed.

---

## Profile D — Built on Drupal CMS 2

Drupal CMS ships with a large amount of this already applied via recipes. The
guidance here is mostly **what not to duplicate**.

### First, find out what you already have

```bash
drush pm:list --status=enabled --no-core --format=table
ls recipes/            # applied recipes, if vendored
```

Drupal CMS's recipes typically already install and configure SEO (Metatag,
Pathauto, Simple XML Sitemap, Redirect), an editorial workflow (Content
Moderation + Workflows), spam protection, an admin UX layer (Gin, Admin
Toolbar), search, and Drupal Canvas as the page-building experience.

### Rules for working on a Drupal CMS site

- **Check before installing anything from Profile A.** Most of it is there. A
  duplicate install with different config is worse than neither.
- **Don't fight the recipes.** If a recipe's config isn't what you want, change
  the config and export it — don't uninstall and rebuild the feature.
- **Recipes are one-shot.** They're not tracked as "installed" and applying one
  twice can duplicate things. After the initial build, your exported config in
  git is the source of truth, not the recipe. Treat recipes as scaffolding.
- **Prefer a new recipe over a new module** when packaging site-specific setup.
- **Canvas is the page builder.** Don't add Paragraphs alongside it on a
  greenfield Drupal CMS site — you'll end up with two competing composition
  models and editors who don't know which to use.
- Layer Profile A's *platform* concerns (purge, backups, security headers,
  environment indicator) on top — Drupal CMS doesn't opine about hosting.

### Still worth adding

- **Seckit** — security headers aren't part of the CMS recipes.
- **Environment Indicator**.
- **Config Split** — the moment you have a second environment.
- **Upgrade Status** — Drupal CMS pins a lot of contrib; know your exposure.
