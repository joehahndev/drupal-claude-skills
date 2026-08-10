---
name: drupal-module-baselines
description: Standard contributed-module stacks for Drupal sites by deployment type — public web-hosted sites, static/Tome-generated sites, private or internal sites, and sites built on Drupal CMS 2. Use when starting a new Drupal site, auditing an existing site's module list, deciding whether a contrib module is trustworthy, or answering "what modules should this site have".
---

# Module baselines by site type

Two failure modes this skill exists to prevent: installing a module that's been
in core for three years, and shipping a public site with no Metatag, no Pathauto,
and no backup story.

## Step 1 — establish the site type and version

```bash
drush status
drush pm:list --status=enabled --no-core --format=table
composer show drupal/core-recommended | head -3
```

Then pick a profile:

| If the site… | Profile |
|---|---|
| Serves live traffic from a webserver with a database | **A — Public hosted** |
| Is generated to static HTML (Tome, or similar) and the Drupal install is a build tool | **B — Static** |
| Is intranet/extranet/internal-tool, behind auth or a VPN, no anonymous traffic | **C — Private / internal** |
| Was installed from Drupal CMS 2 or its recipes | **D — Drupal CMS** |

Full lists in `references/profiles.md`. Vetting an unfamiliar module:
`references/evaluating-contrib.md`.

## The universal baseline

These belong on essentially every Drupal site regardless of type:

| Module | Why |
|---|---|
| **Admin Toolbar** | Dropdown admin menu. Saves a click-and-pageload on every admin action. First thing to install, always. |
| **Gin** | Modern admin theme with dark mode and better authoring layouts. Note: targeted to *become* core's admin theme — check `drupal-modern-core` → `version-status.md` before installing it separately on a 12.x site. |
| **Pathauto** (+ Token, Ctools) | Generated URL aliases from token patterns. Manual alias entry is an error source and an SEO liability. |
| **Redirect** | Catches old paths after alias changes. Pairs with Pathauto — installing one without the other creates 404s. |
| **Webform** | The form builder. Core fields don't do multistep, conditional logic, or submission handling. |
| **Paragraphs** *or* **SDC + Canvas** | Structured content composition. On a greenfield build prefer SDC/Canvas; Paragraphs remains right for existing sites and complex nested editorial structures. |
| **Config Split** / **Config Ignore** | Per-environment config. Needed the moment you have more than one environment. |

## Do not install — these are core

`views`, `media`, `media_library`, `jsonapi`, `layout_builder`, `workspaces`,
`sdc`, `navigation`, `content_moderation`, `workflows`, `ckeditor` (core has
CKEditor 5), `settings_tray`, `big_pipe`, `responsive_image`, `datetime_range`,
`migrate`, `announcements_feed`.

Also dead or superseded: **Rules** (use **ECA**), **Features** (use **config
export + recipes**), **EU Cookie Compliance** (use **Klaro**), **Panels** for
most cases (use Layout Builder or Canvas), **Colorbox/Lightbox** by reflex
(check `<dialog>` and core Media first), **AdvAgg** mostly (core aggregation
improvements removed most of its value — verify before adding).

## How to answer "should I add module X?"

1. Is it core already? (list above)
2. Can config do it — a view, a text format, a field, a recipe?
3. Is it security-covered and maintained? (`references/evaluating-contrib.md`)
4. Does it fit the site type? A caching/CDN module is pointless on a Tome site;
   a spam module is pointless behind SSO.

Say which of these you checked. "Install Metatag" without saying why is the kind
of advice that accretes into a 90-module site nobody can upgrade.
