# PHP standards

Drupal's PHP standard is PSR-12-adjacent but not PSR-12. Where they conflict,
Drupal wins. The differences that bite: 2-space indent (not 4), `} else {` on one
line, and Drupal's own docblock grammar.

## File header

Every file that isn't a class file gets a `@file` docblock:

```php
<?php

/**
 * @file
 * Hook implementations and shared helpers for the Example module.
 */

declare(strict_types=1);
```

Class files get a namespace instead — no `@file` needed:

```php
<?php

declare(strict_types=1);

namespace Drupal\example\Service;

use Drupal\Core\Entity\EntityTypeManagerInterface;
```

`declare(strict_types=1);` is standard in new core code and expected in new
contrib. Add it to new files. Do **not** add it to an existing file without
checking the whole file still passes tests — it changes coercion behavior.

`use` statements: one per line, alphabetical, no leading backslash, no grouping
braces. Blank line between the namespace and the first `use`, and after the last.

## Docblocks

The summary is **one line, one sentence, imperative, ending in a period**, and
must fit within 80 characters including the `* `. "Returns the thing." not
"This function returns the thing" and not "Return the thing".

```php
/**
 * Loads published nodes of a given type for the current user.
 *
 * Longer description if the summary isn't enough. Wraps at 80 characters.
 * Separated from the summary by a blank line.
 *
 * @param string $type
 *   The node bundle machine name.
 * @param int $limit
 *   (optional) Maximum number of nodes to return. Defaults to 10.
 *
 * @return \Drupal\node\NodeInterface[]
 *   The loaded nodes, keyed by node ID.
 *
 * @throws \Drupal\Core\Entity\EntityStorageException
 *   Thrown when the node storage handler cannot be loaded.
 */
```

Rules that trip people up:

- Parameter description goes on the **next line**, indented 2 extra spaces, and
  is a full sentence ending in a period.
- Optional params start with `(optional)` and state the default.
- Fully-qualified class names in `@param`/`@return`/`@throws` types, with a
  leading backslash — `\Drupal\node\NodeInterface`, never the short `NodeInterface`.
- `@return` is omitted entirely for `void`. Don't write `@return void`.
- When a native type declaration says everything the tag would, the tag is still
  required for the *description*. Only drop `@param` if there's genuinely nothing
  to say beyond the type — and reviewers usually think there is.
- `{@inheritdoc}` alone is correct for interface implementations. Don't restate
  the parent docblock.

## Types

Use native type declarations everywhere you can: parameters, return types, and
typed properties. Nullable as `?Foo`, union types where genuinely needed. Do not
use `mixed` unless the value really is unconstrained.

```php
public function loadForUser(AccountInterface $account, ?string $bundle = NULL): array {
```

`NULL`, `TRUE`, `FALSE` are **uppercase** in Drupal. This is one of the loudest
differences from every other PHP project and phpcs will flag it.

## Class and constant naming

- `UpperCamelCase` for classes, interfaces, traits, enums. `lowerCamelCase` for
  methods and properties.
- **Never** put `Drupal` in a class name, and never suffix `Class`. The namespace
  already says it's Drupal; `NodeManagerClass` is noise.
- Interfaces **must** end in `Interface`; traits in `Trait`; test classes in
  `Test`; exceptions in `Exception`.
- Acronyms are camel-cased, not shouted: `SampleXmlParser`, not
  `SampleXMLParser`. `JsonApiResource`, not `JSONAPIResource`.
- Constants are `UPPER_SNAKE_CASE`. Use the `const` keyword, not `define()` —
  `const` is resolved at compile time and is the standard in modern code. Class
  constants get an explicit visibility (`public const FOO = 1;`).

## Dependency injection

New code injects. Static `\Drupal::` calls in a class are a review failure.

Constructor promotion is standard in current core — use it:

```php
final class ArticlePromoter {

  public function __construct(
    private readonly EntityTypeManagerInterface $entityTypeManager,
    private readonly LoggerChannelInterface $logger,
    private readonly TimeInterface $time,
  ) {}

}
```

Register with **autowiring** where the dependency is an unambiguous interface —
core supports `autowire: true` and it removes most `services.yml` noise:

```yaml
services:
  Drupal\example\ArticlePromoter:
    autowire: true
```

Reference the service by its FQCN, not a snake_case id, for new services. Keep
snake_case ids only for backward compatibility with existing consumers, aliased:

```yaml
  example.article_promoter:
    alias: Drupal\example\ArticlePromoter
```

For plugins and forms that need services, implement
`ContainerFactoryPluginInterface` / `ContainerInjectionInterface` and use
`create()`. Never fetch from the container inside `build()` or `submitForm()`.

## Hooks

New code uses OOP hooks. Procedural `.module` hooks are deprecated. See the
`drupal-modern-core` skill for the full pattern and the backward-compatibility
shim — but the short version:

```php
namespace Drupal\example\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class ExampleHooks {

  #[Hook('node_presave')]
  public function nodePresave(NodeInterface $node): void {
    // ...
  }

}
```

## Plugins

Attribute-based discovery, not annotations. Annotations are deprecated core-wide.

```php
#[Block(
  id: 'example_promo',
  admin_label: new TranslatableMarkup('Promotional block'),
  category: new TranslatableMarkup('Example'),
)]
final class PromoBlock extends BlockBase implements ContainerFactoryPluginInterface {
```

Note `new TranslatableMarkup(...)` — you cannot call `t()` in an attribute.

## Translatable strings

```php
$this->t('Hello @name, you have @count items.', ['@name' => $name, '@count' => $count]);
```

- `@var` — escaped, the default, use this.
- `%var` — escaped and emphasized (`<em>`).
- `:url` — for href attributes only, runs through `UrlHelper`.
- Never concatenate: `t('Hello ') . $name` is wrong and untranslatable.
- Never pass a variable as the whole string: `t($message)` is a review failure —
  the string extractor can't see it.
- Plurals use `formatPlural()`, not an `if` on the count.

In a class, `$this->t()` via `StringTranslationTrait`. In procedural code, `t()`.

## Logging

```php
$this->logger->error('Failed to promote node @nid: @message', [
  '@nid' => $node->id(),
  '@message' => $e->getMessage(),
]);
```

Inject `logger.factory` and call `->get('example')`, or inject a
`LoggerChannelInterface` directly. Placeholders, never interpolation. Never log
user credentials, tokens, or full request bodies.

## Security

- **Never** build SQL by concatenation. Use the query builder with placeholders,
  or entity query.
- Render arrays over raw HTML strings. If you must emit markup, `#markup` runs
  through `Xss::filterAdmin()` — for full control use `#type => 'inline_template'`
  or a Twig template.
- `Html::escape()`, `Xss::filter()`, `Xss::filterAdmin()` — know which you need.
- Check access explicitly. `$node->access('update', $account)`. Route access
  requirements in `*.routing.yml` are the first line, not the only line.
- `#access` on form elements hides but does not protect — validate server-side too.
- File uploads: use the `file` / `managed_file` element with explicit
  `file_validate_extensions`. Never trust a client-supplied filename.
- Unrouted user input into `Url::fromUri()` needs `UrlHelper::isValid($url, TRUE)`.

## Tests

PHPUnit is the framework. Simpletest was deprecated in Drupal 8, moved to contrib
in 8.7, and removed in Drupal 9 — if you find `WebTestBase`, it's dead code.

Every contributed module needs tests. Pick the **cheapest tier that proves the
thing**, because each tier costs an order of magnitude more wall-clock:

| Directory | Base class | Bootstraps | Use for |
|---|---|---|---|
| `tests/src/Unit/` | `UnitTestCase` | Nothing | Pure logic, parsing, isolated services. Milliseconds. Mock everything (Prophecy or PHPUnit mocks). |
| `tests/src/Kernel/` | `KernelTestBase` | Container + DB schema | Entity API, queries, service integration. **The sweet spot** — most tests belong here. |
| `tests/src/Functional/` | `BrowserTestBase` | Full site install | User journeys, form submission, HTTP status. Slow: fresh install per class. |
| `tests/src/FunctionalJavascript/` | `WebDriverTestBase` | Full site + Chromedriver | AJAX, dynamic DOM, anything needing real JS. |
| `tests/src/Build/` | `BuildTestBase` | Isolated build env | Packaging, Composer scaffolding. Rare outside core. |

Every test class needs `$defaultTheme` set (usually `'stark'`) and an explicit
`$modules` array. `@group example` (or the `#[Group]` attribute in current core)
is required or the test won't run in CI.

### Beyond PHPUnit

- **Nightwatch.js** — core's pure-JS browser framework (`tests/src/Nightwatch/`).
  Use when you're testing what the user *sees* rather than backend state.
  **Caveat:** there's an active core proposal (#3467492) to replace Nightwatch
  with **Playwright** over flakiness — don't build large new Nightwatch suites;
  check the issue's status first.
- **Behat** — Gherkin/BDD. Worth it on agency projects where a product owner
  writes the scenarios. Not used by core.
- **Drupal Test Traits (`weitzman/drupal-test-traits`)** — the answer to
  "`BrowserTestBase` installs an empty site, but I need to test *this* site."
  Extend `ExistingSiteBase` to run tests against a real, populated database with
  the live config. This is the right tool for staging smoke tests and deployment
  verification on a large client site; it's the wrong tool for contrib, which
  must work in a vacuum.

## Things that read as "not written by a Drupal developer"

- `use Drupal\Core\...;` for a class then calling it fully-qualified anyway.
- Building entity queries then calling `->execute()` without
  `->accessCheck(TRUE)` or an explicit `->accessCheck(FALSE)` — this throws in
  current core, and a bare `accessCheck(FALSE)` needs a comment saying why.
- `drupal_set_message()` — removed years ago. It's
  `$this->messenger()->addStatus()`.
- `db_query()`, `entity_load()`, `format_date()` — all removed. Use the services.
- Hardcoded paths. Use `Url::fromRoute()` and route names.
- `global $user`. Inject `current_user`.
- Storing config in `variable_get`-style state when it should be config entities.
  `State` is for non-exportable runtime values only (last cron run, a cursor).
