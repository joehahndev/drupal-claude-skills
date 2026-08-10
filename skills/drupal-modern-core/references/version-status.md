# Drupal release landscape

**Verified 2026-08-10 against drupal.org** (release schedule page + releases page).
This is the only file here with a shelf life. If today is more than ~2 months
past that date and a version fact matters to the answer, re-check
`drupal.org/project/drupal/releases` and
`drupal.org/about/core/policies/core-release-cycles/schedule` before asserting.

## Core

| Branch | Latest as verified | Status |
|---|---|---|
| **12.0** | **not released** | Target: **week of 2026-12-07** (betas Sep–Nov 2026). An earlier Aug 2026 window was missed. Planned: Symfony 8, PHP 8.5 minimum, PHPUnit 12+. |
| **11.4** | 11.4.5 (2026-08-06) | Current stable, current recommended for new builds. |
| **10.6** | 10.6.15 | Final Drupal 10 minor. **EOL 2026-12-09** — same week Drupal 12 ships. |
| 10.5 and earlier | — | Security support ended June 2026. |
| 7 | — | EOL 2025-01-05. Paid extended support exists (HeroDevs, Tag1, Dropsolid). |

**Practical reading:** Drupal 11.4 is the safe answer today. A site on 10.x has a
hard **December 9, 2026** deadline — a dated conversation to have now, not
someday. A 10 → 11/12 move is a normal upgrade (deprecation cleanup via
Rector), *not* the D7→D8-class rebuild people remember. When D12 lands, expect a
wave of easily-creditable D12-compatibility contrib work.

## What's in / changing in Drupal 12

Planned, not shipped — confirm any single item before relying on it:

- **Symfony 8**, **PHP 8.5 minimum**, PHPUnit 12 (13 eventually).
- **Toolbar module removed** — Navigation module is stable and in the standard
  profile. Custom code hooking Toolbar needs porting.
- **Gin replacing Claro** as admin theme — was listed as a critical item still
  needing work; verify it landed.
- Test files excluded from core release packages; pre-11.3.0 upgrade paths and
  migration dumps removed (D7 migrations must route through an intermediate
  version); import maps API for JS; ESLint 9.
- **Procedural hooks:** deprecated in favor of `#[Hook]`. Sources conflict on
  whether removal is D12 or D13 — the disruptive-deprecations policy points to
  **13.0.0** for the disruptive removals. Either way: write no new procedural
  hooks, and keep `#[LegacyHook]` shims only while supporting pre-11.1 cores.

## Testing / tooling direction (core)

- Core's own PHPStan config runs **level 1** (level 2 is a stated goal, with a
  large PHP-format baseline at `core/.phpstan-baseline.php`). Custom-code
  projects can and should run higher — see the tooling reference.
- **Nightwatch → Playwright** is an active core proposal (#3467492), motivated by
  Nightwatch flakiness. Treat Playwright as direction, not a completed switch;
  don't invest heavily in new Nightwatch suites.
- **Patches are dead**: DrupalCI and all patch testing were turned off
  **2024-07-01**. Only merge requests get CI. (Full workflow in
  `drupal-standards` → `references/contribution.md`.)
- **DDEV** is the de facto local environment; `drupal/core-dev` is the dev
  meta-package; `core/scripts/dev/commit-code-check.sh` is core's local
  pre-commit runner.

## Drupal CMS

Separate product on top of core ("core = framework, Drupal CMS = product").
**1.0 launched 2025-01-15**; **2.0 shipped Jan 2026** with Drupal Canvas and the
first site templates. Ships **Gin** as admin theme and applies a curated recipe
set (SEO, a11y tooling incl. Editoria11y, privacy/consent via Klaro, Honeypot…)
— see the `drupal-module-baselines` skill, Profile D, before adding modules to a
Drupal CMS site.

Use it when the client needs a strong out-of-the-box editorial experience and a
site builder will own the site. Use plain core for highly custom builds where
pre-applied opinions get in the way.

## Drupal Canvas (formerly Experience Builder)

Renamed from Experience Builder; the `experience_builder` project page is
historic. Default editing experience in Drupal CMS 2 — drag-and-drop, live
preview, built on SDC. Check the Canvas project page for release maturity before
committing production plans to it.

## Modules that got absorbed into core

Don't install these as contrib; they're core now: **Views**, **Media**, **Media
Library**, **JSON:API**, **Layout Builder**, **Workspaces**, **SDC**,
**Navigation**, **Content Moderation**, **Workflows**, **CKEditor 5**,
**Settings Tray**, **BigPipe**, **Responsive Image**, **Datetime Range**,
**Migrate**, **Announcements**. Recommending `drupal/media` or `drupal/jsonapi`
is an immediate tell that advice is stale.

## Community context (why the platform looks like it does)

- **Origins:** Dries Buytaert's dorm message board → open-sourced 2001-01-15
  ("drop.org" was a typo for "dorp.org"). D7 (2011) was the procedural
  generation's peak; **D8 (2015)** was the Symfony/OOP rewrite that broke
  backward compatibility and required rebuilds, not upgrades.
- That rewrite cost the hobbyist/SMB market: overall CMS share fell from ~5.5%
  (2014) to ~1% (2026) while WordPress consolidated ~60% of the CMS market. But
  it **won the enterprise**: ~5.8% of the top 100k sites, ~4.7% of the top 5k
  enterprise domains — Pfizer, Cisco, Lufthansa, the UN, GovCMS, universities.
- Since D8, **semver + continuous innovation**: minors every ~6 months adding
  features behind deprecations; majors every ~2 years dropping deprecations and
  bumping Symfony/PHP. That's why 9→10→11→12 upgrades are routine.
- **Governance:** Dries as project lead + core committers + subsystem
  maintainers; the independent **Drupal Association** owns drupal.org and runs
  DrupalCon. A **Coding Standards Committee** ratifies standards changes through
  a documented policy-issue process — standards are versioned community law, not
  one person's preference.
- **Starshot → Drupal CMS + Recipes + Canvas + Project Browser + Automatic
  Updates** is the deliberate play to win back site builders without giving up
  the enterprise architecture.

Practical consequence: Drupal's answer to "make this easy" is *configuration and
recipes*; its answer to "make this scale/secure/audited" is *typed OOP services
with tests*. WordPress-style shortcuts read as not understanding the platform.
