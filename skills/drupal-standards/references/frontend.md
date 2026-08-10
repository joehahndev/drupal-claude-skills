# Front-end standards: Twig, JS, CSS, SDC, libraries

## Twig

Templates live in `templates/`, named after the theme hook with dashes:
`node--article--teaser.html.twig`, `block--system-branding-block.html.twig`.

```twig
{#
/**
 * @file
 * Theme override for an article teaser.
 *
 * Available variables:
 * - node: The node entity with limited access to object properties.
 * - label: The title of the node.
 * - content: All node items. Use {{ content }} to print them all.
 *
 * @see template_preprocess_node()
 */
#}
<article{{ attributes.addClass(classes) }}>
  {{ title_prefix }}
  <h2{{ title_attributes }}>{{ label }}</h2>
  {{ title_suffix }}
  {{ content }}
</article>
```

Rules:

- **No PHP logic in templates.** Move it to a preprocess function. Reviewers
  reject `{% if node.field_foo.0.value matches ... %}` chains.
- Print with `{{ }}`, logic with `{% %}`, comments with `{# #}`.
- **Do not use `|raw`.** Drupal's auto-escaping is the security boundary. If you
  genuinely have safe markup, it should already be a render array or
  `Markup::create()` in PHP with a comment explaining why.
- Use `{{ attributes }}`, `{{ title_attributes }}`, `{{ content_attributes }}` —
  never hand-write `class="..."` on an element that has an attributes object.
- `{{ content }}` prints everything; printing individual fields
  (`{{ content.field_foo }}`) means you must handle the leftovers — use
  `{{ content|without('field_foo') }}` so new fields don't silently vanish.
- Translate with `{% trans %}` blocks or the `|t` filter. Same placeholder rules
  as PHP.
- 2-space indent. Attributes on one line unless the line gets unreadable.
- `{{ link(label, url) }}` and `{{ path('route.name') }}` over hand-built anchors.
- Whitespace control (`{%- -%}`) sparingly and only where it matters.

### The render-array drilling anti-pattern

Do **not** reach into a render array to pull a raw value:

```twig
{# WRONG — silently breaks caching #}
{{ content.field_subtitle[0]['#markup'] }}
{{ node.field_subtitle.value }}
```

Bypassing the render pipeline strips the cache tags, contexts, and max-age that
were attached to that array. The page then caches without knowing it depends on
that field, and edits stop invalidating it — you serve stale HTML and the bug
looks unrelated to this template.

Print the rendered element (`{{ content.field_subtitle }}`), or if you need the
scalar, compute it in a preprocess function and call
`CacheableMetadata::createFromRenderArray()` / `$variables['#cache']['tags']` to
carry the dependency forward yourself.

## Single Directory Components (SDC)

SDC is the current standard for reusable UI in themes and modules. Prefer it over
loose templates + a preprocess + a library entry. A component is one directory:

```
components/
  card/
    card.component.yml
    card.twig
    card.css
    card.js
```

Two files are mandatory: the Twig template and the `*.component.yml`. Note the
template extension is **`.twig`, not `.html.twig`** — SDC deliberately sheds that
convention, and getting it wrong means the component silently isn't discovered.

`card.component.yml` declares props and slots with JSON Schema — this is the
contract, and it's validated. **Props** are structured scalars (string, integer,
boolean, enum); **slots** are unstructured nested markup or render arrays. Getting
that split right matters: contrib tooling and Drupal Canvas generate data-entry
forms from the prop schema, so anything you smuggle through as a slot becomes
invisible to site builders.

```yaml
$schema: https://git.drupalcode.org/project/drupal/-/raw/HEAD/core/assets/schemas/v1/metadata.schema.json
name: Card
status: stable
props:
  type: object
  required:
    - heading
  properties:
    heading:
      type: string
      title: Heading
    variant:
      type: string
      enum: [default, featured]
      default: default
slots:
  body:
    title: Body
```

Use it:

```twig
{% include 'mytheme:card' with { heading: label, variant: 'featured' } only %}
```

`only` is effectively mandatory — without it the component inherits the parent
scope and the prop contract is a lie.

CSS/JS files sitting next to the component are attached automatically. Don't also
declare them in `*.libraries.yml`.

## Libraries

Everything else attaches through `MYTHEME.libraries.yml`:

```yaml
global:
  version: 1.x
  css:
    theme:
      css/global.css: {}
  js:
    js/global.js: {}
  dependencies:
    - core/drupal
    - core/once
```

- **Never** load jQuery unless you actually need it — `core/jquery` is a
  dependency you must justify. Core is moving off it.
- `core/once` replaced `jQuery.once`. Use it.
- `core/drupal`, `core/drupalSettings`, `core/drupal.ajax` as needed.
- Attach from a render array (`#attached: ['library' => ['mytheme/global']]`) or
  a preprocess — not from a `<script>` tag in a template.
- External assets need `{ type: external, minified: true }` and, for anything
  going to production, an `integrity`/`crossorigin` attribute. Better: vendor it
  locally. Private/internal sites should have **zero** external asset requests.

## JavaScript

Drupal core follows ESLint with the Airbnb-derived core config, plus Prettier for
formatting. Behaviors, not DOMContentLoaded:

```js
((Drupal, once) => {
  Drupal.behaviors.exampleToggle = {
    attach(context) {
      once('example-toggle', '.js-example-toggle', context).forEach((element) => {
        element.addEventListener('click', () => {
          element.classList.toggle('is-open');
        });
      });
    },
  };
})(Drupal, once);
```

- Behaviors run on initial load **and** after every AJAX insert. Anything that
  binds to the DOM belongs in a behavior, wrapped in `once()`.
- Always scope queries to `context`, never `document`.
- Provide `detach()` if you bind global listeners or start timers.
- `js-` prefixed classes are for JavaScript hooks only — never style them.
- Use `Drupal.t()` for user-facing strings in JS, and `Drupal.checkPlain()` /
  `Drupal.theme()` for markup.
- ES modules and modern syntax are fine in current core. No transpilation is set
  up for custom code by default — target evergreen browsers.
- `drupalSettings` for passing values from PHP; never inline `<script>` with
  interpolated data.
- `lowerCamelCase` for variables and functions, matching PHP method naming.
- **Prefix variables holding jQuery objects with `$`** — `const $form =
  $('#form-id');` — so the prototype is obvious at the call site. (This is a
  convention for when jQuery is genuinely in play, not a licence to use it.)
- Terminate every statement with an explicit semicolon. Automatic semicolon
  insertion is disallowed; the exceptions are the block forms of `function`,
  `if`, `switch`, `try`, and `while`.

## CSS

Drupal follows a BEM-ish convention with SMACSS-derived file categories.

```css
/**
 * @file
 * Card component.
 */

.card {
  display: grid;
  gap: var(--spacing-m);
}

.card__heading {
  font-size: var(--font-size-l);
}

.card--featured {
  border-color: var(--color-accent);
}
```

- Component class = `.block__element--modifier`. One component per file.
- 2-space indent, one selector per line, one declaration per line, lowercase hex.
- Comment blocks use the `/** @file */` header, section dividers use the 80-char
  rule-comment style seen in core.
- **State classes** are `is-` / `has-` prefixed: `.is-active`, `.has-children`.
- CSS custom properties over preprocessor variables in new work — core is moving
  that way and it survives into the browser.
- Logical properties (`margin-inline-start`) over physical, for RTL support.
  Drupal supports RTL and core themes are audited for it.
- Don't `!important`. If you're fighting core specificity, the fix is usually a
  library `weight` or overriding the right theme hook.

## Accessibility

Drupal targets **WCAG 2.2 AA** (the latest recommended release, and the target
moves with it) plus **ATAG 2.0** — meaning the *authoring* experience, not just
the rendered site, must be accessible. This is one of four **core gates**
(Performance, Usability, Testing, Accessibility) that hard-block a merge into
core; core releases have been delayed over late-discovered a11y regressions.
Contributed projects are held to the same bar in review.

- **Native semantic HTML first** — `<nav>`, `<button>`, `<dialog>`, `<details>`.
  ARIA is a *fallback* for when native HTML lacks the descriptive power, not a
  default. Over-applied ARIA on `<div>` soup actively degrades screen-reader
  usability and can create conflicting states. A `<div>` with a click handler is
  a bug.
- Every interactive control is keyboard-reachable and has a visible focus style.
  Never `outline: none` without a replacement.
- `Drupal.announce()` for dynamic content changes that a screen reader must hear.
- `.visually-hidden` (core class) for screen-reader-only text — don't reinvent it,
  and never use `display: none`, which hides it from AT too. Add `.focusable`
  when a keyboard user should reveal it on tab (the "Skip to main content"
  pattern).
- Color contrast 4.5:1 for body text, 3:1 for large text and UI boundaries.
- Every non-text element that carries meaning — SVG, chart, icon-as-background —
  needs a text alternative. Video needs captions and a transcript.
- Test with keyboard only, then with a screen reader (NVDA or VoiceOver), before
  calling it done. Automated tooling (axe-core) finds only ~57% of WCAG issues
  by Deque's own measurement — the remainder is manual. Core runs axe-core in CI
  on every commit.

### Legal drivers (worth naming to clients)

Build to **WCAG 2.2 AA** now — it's a superset of 2.1 and where every regime is
heading. As verified 2026-08:

- **European Accessibility Act** — enforceable since **2025-06-28** for digital
  products/services sold to EU consumers, extraterritorially (follows the
  customer, not the company HQ). Pre-existing service contracts get until
  2027-06-28.
- **ADA Title II** (US state/local gov): WCAG 2.1 AA written into the 2024 DOJ
  rule; deadlines extended in April 2026 to **2027-04-26** (populations ≥50k)
  and **2028-04-28** (smaller entities).
- **Section 508** (US federal): WCAG 2.0 AA. **EN 301 549** (EU): v3.2.1
  references WCAG 2.1 AA; the 2.2-based revision is expected late 2026/2027.

For editorial content (where most post-launch findings come from — alt text,
headings, PDFs, embeds), put **Editoria11y** in the workflow: an in-context
checker for authors, shipped in Drupal CMS's Accessibility Tools recipe. Avoid
"accessibility overlay" widgets — distrusted by disabled users and not
remediation.

### Accessibility Champions review (for core/contrib initiatives)

Large UI work follows a phased sign-off with the Accessibility Topic Maintainers,
because retrofitting a11y means foundational rewrites:

1. **Design review** — interaction design, contrast, and whether the proposed DOM
   can support AT requirements. *Before code is written.*
2. **Alpha review** — scope challenges and theoretical barriers in the prototype.
3. **Beta review** — definitive technical solutions mapped to every barrier found.
4. **Stable review** — final core-gate clearance, manual + automated verification.

The `#accessibility` channel on Drupal Slack is where this coordination happens.

## Theming

- Theme hook suggestions via `hook_theme_suggestions_HOOK_alter()`, not
  conditionals inside a template.
- Preprocess in `MYTHEME.theme` (or an OOP preprocess class in current core).
  Keep them thin — heavy logic belongs in a service.
- Never alter markup by string replacement. Find the theme hook.
- `libraries-override` and `libraries-extend` in `*.info.yml` to swap or extend
  core/contrib assets rather than fighting them with CSS.
