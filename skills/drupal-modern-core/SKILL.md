---
name: drupal-modern-core
description: Current Drupal core version status and the modern way to implement things — OOP hooks with #[Hook], attribute plugins, autowired services, Single Directory Components, recipes, Drupal CMS, Drupal Canvas, config actions. Use when deciding how to build a feature in Drupal, when reviewing whether an approach is outdated, when planning a core version upgrade, or when the user asks what's new in Drupal.
---

# Modern Drupal: build it the current way

The point of this skill is to stop Drupal work from defaulting to 2019 patterns.
Drupal's APIs have turned over substantially since Drupal 9, and a lot of
still-working code is deprecated or actively discouraged.

## First: check the version

Read `references/version-status.md` for the release landscape as last verified.
That file is dated — **if it's more than ~2 months stale and the answer matters,
verify against drupal.org before asserting a version fact.** Everything else in
this skill is stable.

Then check what the project actually runs:

```bash
composer show drupal/core-recommended | head -5
drush status --field=drupal-version
```

Don't recommend a Drupal 12 API to a site on 10.6.

## The old-way / new-way table

| Don't write | Write instead | Since |
|---|---|---|
| Procedural hooks in `.module` | `#[Hook]` attribute on a class method | 11.1 |
| Procedural `MYTHEME_preprocess_node()` | OOP preprocess / `#[Hook('preprocess_node')]` | 11.1+ |
| Annotation plugins (`@Block`, `@FieldType`) | PHP attributes (`#[Block]`, `#[FieldType]`) | 10.2+ |
| `\Drupal::service('foo')` in a class | Constructor injection, `autowire: true` | always, enforced now |
| Hand-written `services.yml` with snake ids | FQCN service id + `autowire: true` | 10.3+ |
| Loose template + preprocess + library entry | Single Directory Component | 10.3 stable |
| Install profile for a reusable feature | **Recipe** | 11.1 stable |
| `hook_install()` doing config CRUD | Config actions in a recipe / `config/install` | 11.x |
| Custom "page builder" module | Drupal Canvas (formerly Experience Builder) | see version file |
| `jQuery.once()` | `core/once` | 9.2 |
| jQuery for DOM work | Vanilla JS in a `Drupal.behaviors` | ongoing |
| `drupal_set_message()` | `$this->messenger()->addStatus()` | 8.x, removed |
| `db_query()`, `entity_load()` | Injected `database` / `entity_type.manager` | 8.x, removed |
| Toolbar module assumptions | Navigation module | 11.2+ |

## OOP hooks — the pattern to use

`src/Hook/ExampleHooks.php`:

```php
<?php

declare(strict_types=1);

namespace Drupal\example\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\Core\StringTranslation\StringTranslationTrait;
use Drupal\node\NodeInterface;

/**
 * Hook implementations for the Example module.
 */
final class ExampleHooks {

  use StringTranslationTrait;

  public function __construct(
    private readonly LoggerChannelInterface $logger,
  ) {}

  #[Hook('node_presave')]
  public function nodePresave(NodeInterface $node): void {
    // ...
  }

  #[Hook('form_node_article_form_alter')]
  public function articleFormAlter(array &$form, FormStateInterface $form_state): void {
    // ...
  }

}
```

The class is autowired automatically — no `services.yml` entry needed for a hook
class in the `Hook` namespace, though you can register it explicitly if it needs
non-autowirable arguments.

**Backward compatibility.** If the module must also run on a version that predates
OOP hooks, keep a thin procedural stub in `.module` marked `#[LegacyHook]` so the
newer core doesn't fire it twice:

```php
#[LegacyHook]
function example_node_presave(NodeInterface $node): void {
  \Drupal::service(ExampleHooks::class)->nodePresave($node);
}
```

If the module only supports 11.1+, drop the `.module` file entirely.

## Recipes over install profiles

A recipe is a directory of config + a `recipe.yml` that can be applied to an
*existing* site, unlike a profile which only runs at install. This is the current
answer to "package this set of features up".

```yaml
# recipe.yml
name: 'Editorial workflow'
description: 'Content moderation with a draft/review/published flow.'
type: 'Workflow'
install:
  - content_moderation
  - workflows
config:
  strict: false
  actions:
    node.type.article:
      setThirdPartySetting:
        module: content_moderation
        key: workflow
        value: editorial
```

```bash
php core/scripts/drupal recipe ../recipes/editorial_workflow
drush cr
```

Recipes are **not idempotent by default** and are not tracked as installed —
applying one twice can duplicate things. Design config actions to be safe to
re-run, and treat a recipe as a one-shot scaffolding tool, not a deployment
mechanism. Config export remains your source of truth.

Reach for a recipe when: standing up a new site from known building blocks,
sharing a feature across sites, or replacing a "features"-style module.

## Single Directory Components

Default choice for reusable UI. See `drupal-standards` → `references/frontend.md`
for the file layout and the `only` keyword rule. Key point: the
`*.component.yml` prop schema is a real contract that's validated, which makes
components safe to hand to a site builder or to Drupal Canvas.

## Config actions

Config actions let one module or recipe modify another's config without an
update hook or a `hook_install`. Available on config entities:

```yaml
config:
  actions:
    core.entity_view_display.node.article.default:
      setComponent:
        name: field_image
        options:
          type: responsive_image
```

Common actions: `setComponent`, `hideComponent`, `grantPermissions`,
`setThirdPartySetting`, `simpleConfigUpdate`, `createIfNotExists`. Prefer these
over programmatic config CRUD in an install hook.

## Things worth actively exploring on new builds

- **Recipes** for anything you'd previously have made a "site setup" module for.
- **SDC + Drupal Canvas** instead of Paragraphs-plus-a-pile-of-templates, on
  greenfield sites. Check the version file for maturity before committing.
- **Project Browser** for installing contrib from the UI — changes how you hand
  a site to a non-developer.
- **Automatic Updates / Package Manager** for small sites where a full
  Composer-plus-CI pipeline is overkill.
- **Workspaces** for staged, previewable content changes — much more capable than
  it was, and often replaces a custom preview workflow.
- **Navigation module** — the Toolbar replacement. Assume new admin UI work
  targets Navigation.
- **`autowire: true`** everywhere. It removes most `services.yml` boilerplate.

## Decoupled / headless

Core ships the API layer: **JSON:API** (zero-config, enable and go) and REST;
GraphQL is contrib. Drupal as content repository + Next.js/React/Vue front end
is a first-class pattern (`next-drupal`, Acquia's headless starter kits).

Decision rule: go headless when the front end genuinely needs an app framework
or serves multiple channels from one content store. Don't go headless to make a
brochure site feel modern — you give up Layout Builder/Canvas, previews, block
placement, and most of the site-builder value, and rebuild them by hand in JS.
"Progressively decoupled" (islands of JS inside Drupal-rendered pages, now
easiest via SDC + a sprinkle of framework) is usually the better trade.

## Upgrade work

Rector plus phpstan-deprecation-rules is the workflow — see
`drupal-standards` → `references/tooling.md`. Order of operations:

1. Get to the latest minor of the current major first. Never jump majors from an
   old minor.
2. `phpstan analyse` with deprecation rules → the full list of what breaks.
3. `rector process --dry-run` → auto-fix what it can, review the diff.
4. Hand-fix the rest, especially hook conversions.
5. `composer why-not drupal/core-recommended ^NEXT` for contrib blockers.
6. Upgrade Status module for a site-wide contrib readiness report.
