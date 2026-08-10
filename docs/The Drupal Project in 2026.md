# The Drupal Project in 2026: Standards, Testing, Community, Accessibility, Modules, and a Contribution Plan

**Scope note:** Current as of 10 August 2026. Drupal 11 is the current major (11.4.x line; 11.4.5 released 6 Aug 2026). Drupal 12 is targeted for the week of 7 December 2026 (the earlier August 2026 window required beta-by-15-May), running on Symfony 8 and PHP 8.5. Drupal 10 reaches end of life 9 December 2026. Drupal 7 reached EOL 5 January 2025.

---

## 1. Latest Drupal Coding Standards

**TL;DR:** Drupal's PHP standards are Drupal-specific (2-space indent, not PSR-2 brace style) but layer PSR-4 autoloading and increasingly PER/PSR-12 ideas on top. Enforcement is via PHP_CodeSniffer + `drupal/coder`, PHPStan (currently **level 1** in core, with documented intent to reach level 2) with `phpstan-drupal`, and `drupal-rector` for deprecations — all bundled in `drupal/core-dev` and wired into GitLab CI. The biggest recent architectural shift is **OOP hooks** (hooks as classes via `#[Hook]` attributes, Drupal 11.1+) and attributes replacing annotations for plugins. Standards changes go through the Coding Standards Committee via a documented policy-issue workflow.

### Tooling stack (current)
- **PHP_CodeSniffer + Coder**: `drupal/coder ^8.3.x` provides the `Drupal` and `DrupalPractice` sniff rulesets. Installed standards include MySource, PEAR, PSR1, PSR2, PSR12, Squiz, Zend, Drupal, DrupalPractice.
- **`drupal/core-dev`**: the official dev meta-package. As of the current line it bundles `drupal/coder ^8.3.x` (which pulls `squizlabs/php_codesniffer`), `micheh/phpcs-gitlab`, `phpstan/phpstan ^1.12.27 || ^2.2.0`, `phpstan/extension-installer`, `mglaman/phpstan-drupal ^1.3.9 || ^2.0.15`, `phpstan/phpstan-phpunit`, `phpunit/phpunit ^11.5.50`, Behat/Mink + drivers, `mikey179/vfsstream`, `phpspec/prophecy(-phpunit)`, and Symfony test components.
- **PHPStan + phpstan-drupal**: Core's config is `core/phpstan.neon.dist`. As of Drupal 11.4.5 the config is **`level: 1`** with supplementary explicit rules (missing function/method return typehints, private-constant-through-static, Drupal's own TestClass rules); a comment in the file confirms level 2 is a future goal. Core moved to PHPStan 2.0 in Drupal 11.2; the "level 2" figure you may have seen dates from the PHPStan 1.x era (April 2024, node/3441298). Core uses a **PHP-format baseline** at `core/.phpstan-baseline.php` and enables PHPStan's **bleeding edge** config for performance. Regenerate the baseline with:
  ```
  vendor/bin/phpstan analyze --configuration=./core/phpstan.neon.dist --memory-limit=-1 --generate-baseline=core/.phpstan-baseline.php
  ```
  There are long-running meta issues to raise levels (e.g., #3425412 "Bump PHPStan rule level to 2"; #3426047 "Bump PHPStan to level 9 and accept a large baseline"). In 2025 the committee also adopted **PHPStan/phpdoc types as the canonical reference of allowed types** (issue #3468236, discussed at the 2025-02-26 Coding Standards meeting).
- **Rector / drupal-rector**: `palantirnet/drupal-rector` automates deprecation fixes. The **1.0 line** ships full Drupal 11 deprecation coverage (11.0–11.4) plus Drupal 10.3 additions, a container-managed `DrupalRectorSettings` service, and Composer-based sets (`DrupalSetProvider` pins rules to the exact installed Drupal version). Install with `composer require --dev palantirnet/drupal-rector`, copy a `rector.php`, then `vendor/bin/rector process`.
- **drupal-check**: `mglaman/drupal-check` wraps PHPStan for a quick deprecation scan.
- **PHP CS Fixer**: used by some contrib maintainers and available, but Coder/PHPCS is the canonical PHP style enforcer for Drupal; Twig CS Fixer is the emerging tool for Twig.
- **GrumPHP / pre-commit**: not mandated by core, but common in agency setups to run PHPCS/PHPStan on commit. Core itself ships `core/scripts/dev/commit-code-check.sh` (the local pre-commit check runner).

### Language-by-language standards
- **PHP**: 2-space indentation (no tabs), Drupal brace/spacing conventions, `example.com` for example URLs (RFC 2606). PSR-4 tree starts under `core/lib/` for core and `modulename/src` for modules. Naming: `UpperCamelCase` classes, `lowerCamelCase` methods/properties, `snake_case` procedural functions prefixed with the module machine name, `CONSTANT_CASE` constants. Modern PHP features are now embraced: typed properties, constructor property promotion, return types, and (increasingly) enums.
- **Docblocks / API docs**: Drupal has its own API documentation standard (the `@` tags, `{@inheritdoc}`, `@param`/`@return` with types). Constructor docblocks may be omitted (ratified change). `@file` docblock no longer required when a file contains a single class/interface.
- **JavaScript**: core uses **ESLint** (Airbnb-derived config in `core/.eslintrc.*`) and **Prettier** for formatting. JS is authored to modern ES syntax and transpiled/managed via the core `package.json`.
- **CSS**: formatting follows the community consensus doc (based on Nicolas Gallagher's idiomatic CSS and SMACSS by Jonathan Snook, with a nod to Nicole Sullivan's OOCSS). Architecture uses **SMACSS** for categorization (Base/Layout/Component/State/Theme, with Drupal-adjusted nomenclature). Core themes — notably **Olivero** — use **BEM** class naming. Stylelint enforces CSS.
- **Twig**: standards cover whitespace, filter usage, `{{ }}`/`{% %}` spacing, printing variables safely; **Twig CS Fixer** is the tool. Single Directory Components (SDC) are the modern component pattern.
- **YAML**: 2-space indent, used for `*.info.yml`, `*.services.yml`, `*.routing.yml`, `*.libraries.yml`, config schema, and recipes.
- **SQL** and **security** standards round out the guide.

### OOP hooks and modern DI conventions (the big 11.x shift)
- **Hooks as classes**: since **Drupal 11.1**, hooks can be implemented as methods on a service class using the `#[Hook('hook_name')]` attribute (namespace convention `Drupal\mymodule\Hook\...`, typically a `src/Hook/` directory). Benefits: PSR-4 autoloading (the `.module` file is no longer scanned, improving bootstrap), dependency injection into hooks, and unit-testability. Procedural hooks still work; a `#[LegacyHook]` attribute bridges old procedural function names to new methods. The plan is to **remove procedural hooks in Drupal 12**, and preprocess hooks became OOP-capable in modules around 11.2 (themes remain procedural). The Hux contrib module offered this pattern earlier (from ~9.35).
- **Attributes over annotations**: plugin discovery has moved from Doctrine annotations to **PHP 8 attributes** as the preferred/standard approach.
- **Autowiring & DI**: `autowire: true` in services, constructor property promotion for injected services, and `Autowire` attributes are now idiomatic.

### How standards are proposed and ratified
Changes are managed by the **Coding Standards Committee** in the **Coding Standards project** issue queue (`drupal.org/project/coding_standards`). Process: (1) open an issue using the template; (2) at least two additional active community members comment in support; (3) create a change record; (4) once RTBC, the committee reviews; (5) if agreed, it's tagged "Needs announcement for final discussion" and announced on the Drupal core blog with a ~14-day feedback window; (6) if core is affected, it needs core-committer sign-off plus a Coder rule for automated enforcement and a core patch to comply. Recent committee membership additions included Aaron McHale, Björn Brala, Derek Wright, and Urvashi Vora, and the process was streamlined so issues stay in the Coding Standards queue rather than bouncing to the core queue.

---

## 2. Latest Drupal Testing Standards

**TL;DR:** Testing is 100% **PHPUnit-based** (Simpletest fully removed in Drupal 9). Four PHP test types — Unit, Kernel, Functional (BrowserTestBase), FunctionalJavascript (WebDriverTestBase) — plus Build tests. Drupal 11 shipped with PHPUnit 10.5 at 11.0, moving to **PHPUnit 11 in 11.2**; Drupal 12 targets PHPUnit 12+. JS uses **Nightwatch.js**, but there is an active core proposal to **replace Nightwatch with Playwright** (issue #3467492) because Nightwatch is a source of flaky pipelines. CI has migrated from bespoke DrupalCI to **GitLab CI/CD templates** (patch testing and DrupalCI were turned off 1 July 2024). Contrib enables CI by adding a seven-line `.gitlab-ci.yml`.

### Test types

| Type | Base class | Boots | Use for | Speed |
|---|---|---|---|---|
| **Unit** | `Drupal\Tests\UnitTestCase` | No Drupal, no DB | Pure logic, isolated classes, mocked deps | Fastest |
| **Kernel** | `Drupal\KernelTests\KernelTestBase` | Partial kernel, DB, selected modules/services | API/integration where mocking is impractical | Medium |
| **Functional** | `Drupal\Tests\BrowserTestBase` | Full install, no JS (Mink/Goutte) | End-to-end HTTP, forms, permissions | Slow |
| **FunctionalJavascript** | `Drupal\FunctionalJavascriptTests\WebDriverTestBase` | Full install + real browser (Chromedriver) | AJAX, JS behaviors, off-canvas, CKEditor | Slowest |
| **Build** | `Drupal\BuildTests\Framework\BuildTestBase` | Isolated build (e.g., Composer) | Packaging, Composer, scaffolding | Slow |

- **Simpletest**: converted to PHPUnit through Drupal 8.7; the module was **removed in Drupal 9**. Legacy `WebTestBase`/`DrupalWebTestCase` are gone.
- Namespaces/dirs: `tests/src/Unit`, `tests/src/Kernel`, `tests/src/Functional`, `tests/src/FunctionalJavascript`; JS tests in `tests/src/Nightwatch`.
- **Running tests**: `phpunit` directly (via `core/phpunit.xml`), or `core/scripts/run-tests.sh` for the core runner. Needs env vars `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB`, `BROWSERTEST_OUTPUT_DIRECTORY`. DDEV is the common local harness (Chromedriver as an add-on service for JS/Nightwatch).

### JavaScript testing
- **Nightwatch.js** was added in Drupal 8.6 (W3C WebDriver, Chromedriver out of the box) as part of the JavaScript Modernization Initiative; tests live at `mymodule/tests/src/Nightwatch/Tests/*.js`.
- **Current direction**: issue #3467492 ("[policy, no patch] Replace Nightwatch with Playwright") proposes converting Nightwatch tests to **Playwright**, and moving some to FunctionalJavascript + axe where appropriate, citing Nightwatch flakiness and low ecosystem adoption. Treat Playwright as a proposal/in-progress direction, not a completed switch. There is no Vitest adoption in core; Vitest/Playwright appear mainly in ecosystem discussion.
- **Accessibility in tests**: axe-core runs against core UI; a11y checks are part of the automated gate.

### CI: DrupalCI → GitLab CI
- GitLab CI enabled for the whole ecosystem in summer 2023, announced at DrupalCon Lille 2023. Per Drupal.org's October 2023 post *"Drupal core's GitLab CI testing is now five times faster than DrupalCI,"* **"Drupal CI core runs take just over 50 minutes, but GitLab CI can run the same test suite in under ten minutes!"** — and the DA later reported the runs are now down to about 5 minutes.
- **Patch testing is dead.** Per the Drupal.org blog, *"DrupalCI and all patch testing will be turned off on July 1, 2024,"* and *"With the exception of Drupal 7, it is not possible to run tests on patches against Drupal core anymore."* Contributions must be **merge requests** to be tested.
- Adoption for contrib is, per the DA's *"GitLab CI: Drupal's strategy to empower a whole ecosystem,"* **"as easy as adding a seven-line file to their project."** The standard contrib `.gitlab-ci.yml` inherits central templates from the **GitLab Templates** project (`drupal/gitlab_templates`):
  ```yaml
  include:
    - project: $_GITLAB_TEMPLATES_REPO
      ref: $_GITLAB_TEMPLATES_REF
      file:
        - '/includes/include.drupalci.main.yml'
        - '/includes/include.drupalci.variables.yml'
        - '/includes/include.drupalci.workflows.yml'
  ```
  This gives PHPCS, PHPStan, ESLint/Stylelint, Cspell, PHPUnit jobs, and opt-in jobs to test against multiple core versions (e.g., `OPT_IN_TEST_PREVIOUS_MAJOR`, next-major, max PHP). Everything is overridable per project.

### Testing gate and best practices
- **Testing gate**: core changes must include test coverage (or justify why not) and pass CI; the gate is one of the core "gates." Core does not publish a single numeric code-coverage target, but new code is expected to be covered and not reduce coverage.
- **Writing testable code**: prefer Kernel over Functional where possible (much faster); inject dependencies (OOP hooks make hook logic unit-testable); avoid static `\Drupal::` calls in business logic; use data providers; keep JS behaviors small and DOM-decoupled.
- **Common pitfalls**: over-using BrowserTestBase for logic better tested at unit/kernel level; flaky JS waits (use proper `waitForElementVisible`/assertion waits); not enabling required modules in `$modules`; forgetting `$defaultTheme`; relying on install-profile side effects.

---

## 3. History of the Drupal Community and Current Preferences

**TL;DR:** Drupal began as Dries Buytaert's dorm message board (2000, University of Antwerp), open-sourced 15 January 2001 after a "drop.org" typo. It grew from a PHP-hook framework (D4–D7) into a Symfony/OOP platform (D8, 2015), then adopted semantic versioning and continuous innovation (D8→D11). Governance blends a founder/project-lead (Dries), core committers, subsystem maintainers, and the independent **Drupal Association** (owns Drupal.org, runs DrupalCon). The defining 2025–2026 story is **Drupal CMS** (ex-Starshot, launched 15 Jan 2025) plus **Experience Builder**, **recipes**, **automatic updates**, and **Project Browser** — a repositioning to win back site builders from WordPress. Work has moved to **GitLab merge requests**, DDEV is the de facto local dev, and the **contribution credit system** ranks the marketplace.

### Origins and milestones
- **2000–2001**: Dries Buytaert and Hans Snijder built a dorm network + news board; the software became drop.org, open-sourced as **Drupal 1.0 on 15 January 2001**. Name from Dutch "druppel" (droplet); "drop.org" was a typo for "dorp.org" (village). Drupal 2.0 followed 15 March 2001, adding translation.
- **Drupal 4/5 (2002–2007)**: install profiles, the theme system matured; **Views** and **CCK** emerged in contrib and reshaped site building. Drupal 5 introduced the web installer and jQuery.
- **Drupal 6 (2008)**: better i18n, menu system, CCK ubiquity; underpinned the first whitehouse.gov on Drupal (2009), a landmark for open source in government.
- **Drupal 7 (2011)**: Field API in core (CCK absorbed), Render API, huge contrib ecosystem; the last "procedural PHP" generation and, for many, the most beloved. EOL 5 January 2025.
- **Drupal 8 (2015)**: ground-up **Symfony-based rewrite** — OOP, dependency injection, Twig templating, Composer, configuration management, Entity API, CKEditor, in-place editing, REST in core. The hardest migration in Drupal history (rebuilds rather than upgrades).
- **Continuous innovation / SemVer (D8+)**: scheduled minor releases every ~6 months adding backward-compatible features behind deprecations; majors every ~2 years to drop deprecations and bump dependencies.
- **Drupal 9 (2020)**: essentially D8 minus deprecations, updated Symfony/Twig — an easy upgrade, proving the new model.
- **Drupal 10 (Dec 2022)**: CKEditor 5, Claro admin theme + Olivero front-end theme as defaults, Symfony 6, Theme Starterkit, modern JS.
- **Drupal 11 (2 Aug 2024)**: Symfony 7, PHP 8.3 minimum (8.4 recommended from 11.3+), recipes, Single Directory Components, OOP hooks (11.1), automatic updates maturing. Current line 11.4.x.
- **Drupal 12 (targeted week of 7 Dec 2026)**: Symfony 8, PHP 8.5 minimum, removal of deprecated code and procedural hooks, PHPUnit 12+.

### Governance
- **Founder / project lead**: Dries Buytaert sets direction and philosophy but the model deliberately distributes power. **Core committers** (product, framework, release managers) gatekeep core; **subsystem maintainers** own areas; **initiative leads** drive strategic work.
- **Drupal Association**: independent non-profit that owns/operates Drupal.org infrastructure, runs DrupalCon, employs engineering/DevOps staff, and stewards the marketplace and credit system. Dries has no financial relationship with the DA beyond trademark licensing.
- **Community Working Group / governance bodies** handle conduct (e.g., the Aaron Winborn Award). Governance has evolved over 20+ years and periodically restructures.
- **DrupalCon & DrupalCamps**: DrupalCon is the flagship (e.g., Portland 2024 where Starshot was announced; Atlanta 2025; **Rotterdam 28 Sep–1 Oct 2026** for Europe). DrupalCamps are regional volunteer events and the usual on-ramp for speaking.

### Notable turning points shaping norms
- The **D8 rewrite** split the community between "site builders" and "PHP engineers" and drove the "proudly invented elsewhere" embrace of Symfony/Composer.
- The **contribution credit system** (issue credits tracked since 2015, marketplace ranking from ~2015) created a direct financial incentive for organizations to contribute — largely positive, but with ongoing anti-gaming enforcement (including new AI-generated-contribution guidance).
- Governance and conduct crises in the late 2010s led to clearer codes of conduct and the CWG's current form.
- **"Come for the code, stay for the community"** remains the stated ethos and appears on Drupal.org's community pages.

### Current strategic initiatives (2025–2026)
- **Drupal CMS** (formerly Starshot): a product built on core, launched **15 January 2025**, aimed at non-developer site builders. Uses recipes + Project Browser + Automatic Updates. The DA is prioritizing marketing Drupal CMS over raw core. Drupal CMS 1.1.0 shipped 19 March 2025 (removing the `launch-drupal-cms.sh` script). Ships **Gin** as default admin theme.
- **Experience Builder (XB)**: next-gen in-browser page builder combining Layout Builder + Paragraphs + SDC + basic theming; first stable targeted late 2025, intended for Drupal CMS 2.0. Treat exact timing as evolving.
- **Recipes**: composable packages of modules + config + default content, applied to any site.
- **Automatic Updates** and **Project Browser**: in-browser module discovery/install and safe core/contrib updates.
- **Marketing/positioning shift**: clearer "Drupal Core = framework, Drupal CMS = product" split; industry landing pages; Drupal AI initiative.

### Current preferences and norms
- **Where work happens**: issue queues remain the system of record for discussion, but **code lands via GitLab merge requests from issue forks** on `git.drupalcode.org`. Patches are no longer CI-tested.
- **GitLab for contrib**: all projects have GitLab CI available; many maintainers run multi-version test matrices.
- **Slack**: the primary real-time channel (e.g., `#gitlab`, initiative channels, `#contribute`). IRC is historical.
- **Credit economy**: issue credits (granted by maintainers), org credits, and event/sponsorship credits feed marketplace rank and Certified Partner tiers.
- **Mentorship**: contribution days at DrupalCon/Camps, the Novice tag, and mentored sprints; strong norms around welcoming first-timers.
- **Tooling**: **DDEV** is the de facto local environment; Composer-based project scaffolding (`drupal/recommended-project`); **Drush** for CLI; Composer for everything.

---

## 4. Drupal and Accessibility

**TL;DR:** Drupal targets **WCAG 2.2 AA** and **ATAG 2.0 AA** as project policy, enforces an **accessibility core gate** on every UI change (automated axe-core + manual review), and has a dedicated Accessibility Team. Core themes Olivero (front-end) and Claro (admin) were built accessibility-first; CKEditor 5, off-canvas dialogs, and contextual links got accessibility work. **Editoria11y** is the standout editorial contrib checker and ships in the Drupal CMS "Accessibility Tools" recipe. Legal drivers are converging on **WCAG 2.1/2.2 AA**: the **EAA** became enforceable **28 June 2025**; the **ADA Title II** rule deadlines were **extended one year on 20 April 2026 to 26 April 2027** (populations ≥50,000) and 26 April 2028 (smaller/special districts). Build to **WCAG 2.2 AA** now.

### Commitment and governance
- **Statement**: Drupal's official accessibility page commits to following the latest recommended WCAG (currently **WCAG 2.2 AA**) and ATAG 2.0. Drupal took the GAAD Foundation **#GAADPledge** in 2022.
- **Accessibility core gate**: UI-affecting changes must pass accessibility checks; goal is WCAG (2.2) AA + ATAG 2.0 AA. New patterns get tagged "needs accessibility review." Every core commit runs Nightwatch + axe-core; failures block the change.
- **Team/history**: work accelerated in Drupal 7 with the first core accessibility maintainers (Everett Zufelt was the first). The Accessibility Team maintains standards and reviews.

### Historical and current core a11y work
- **Olivero** (default front-end theme, D10+): designed accessibility-first, BEM CSS, tested to WCAG 2.1 AA.
- **Claro** (admin theme): high-contrast, accessible admin UI.
- **CKEditor 5**: accessibility improvements in the editor baseline.
- **Off-canvas dialogs, contextual links, Ajax**: keyboard-operability and screen-reader work.
- **Automated + manual testing**: axe-core in CI; manual keyboard/AT testing expected per the gate.

### Accessibility contrib modules
- **Editoria11y** (`drupal/editoria11y`): real-time, multilingual editorial accessibility checker (Princeton-developed; shares a test suite with the Sa11y library). Per the official editoria11y.com Features page and the Drupal.org project page, **"Editoria11y's core tests detect more than 50 common content accessibility problems,"** with add-ons providing roughly 40 additional tests (it flags things like fake headings, "click here" links, alt-text problems, and tables without headers). Included in the **Drupal CMS Accessibility Tools recipe** (`drupal/drupal_cms_accessibility_tools`). The project page explicitly cautions that the tool **"is meant to supplement, not replace, testing your code and visual design with developer-focused tools,"** and warns against "modules that claim they can fix" accessibility automatically.
- **Sa11y**: has a Drupal wrapper; more author-facing (color/readability scoring).
- **CivicTheme** and similar: accessible design-system themes for gov/enterprise.
- Caution: AI-widget "overlay" modules (generic accessibility toolbars) are widely distrusted by disabled users and by the Editoria11y maintainers; they are not a substitute for real remediation.

### Drupal vs other CMSes
Drupal's differentiator is **governance**: accessibility is a hard gate on core commits, and Drupal CMS ships an accessibility checker by default. WordPress has more "accessibility-ready" themes by count and shipped some responsive-image defaults earlier, but lacks Drupal's commit-blocking gate. Drupal's weak point is the **contributed theme/module ecosystem**, where a11y quality varies widely — theme choice is the single biggest front-end variable.

### Legal drivers (build to WCAG 2.2 AA)
- **Section 508** (US federal ICT): aligns to WCAG 2.0 AA.
- **ADA Title II** (US state/local gov): the 2024 DOJ rule wrote WCAG 2.1 AA into law; on **20 April 2026 the DOJ extended compliance dates by one year** — now **26 April 2027** (entities serving ≥50,000) and **26 April 2028** (smaller entities/special districts).
- **European Accessibility Act (EAA)**: enforceable **28 June 2025** for private-sector digital products/services sold to EU consumers (extraterritorial — the law follows the customer, not the company HQ); microenterprises (<10 staff and <€2M turnover) have limited exemption; service contracts pre-dating June 2025 must comply by 28 June 2027.
- **EN 301 549**: harmonized EU standard; current **v3.2.1 references WCAG 2.1 AA**; **v4.1.1 (incorporating WCAG 2.2) expected late 2026/early 2027**.
- **Practical guidance**: build to **WCAG 2.2 AA** now (superset of 2.1, future-proof). Pick an accessible base theme and treat it as an "accessibility floor" that brand variation cannot fall below; gate third-party procurement; put Editoria11y in the editorial workflow; and test with keyboard + screen reader, not just automated tools. Automated coverage is real but partial: Deque's Automated Accessibility Coverage Report puts axe-core coverage at **57.38%** (from "over 2,000 audits ... spanning over 13,000 pages ... covering nearly 300,000 issues"), and the axe-core README states you can "find on average 57% of WCAG issues automatically." Editorial content (alt text, headings, PDFs, third-party embeds, captions) drives the majority of post-launch findings.

---

## 5. Must-Have Contrib Modules for a Public-Facing Site/Web App

**TL;DR:** For a Drupal 11 public site, the durable stack is SEO (Metatag, Pathauto, Redirect, Simple XML Sitemap, optionally Schema.org Metatag), anti-spam (Honeypot, Antibot, Captcha, TFA, Password Policy, Seckit, Username Enumeration Prevention), performance (Purge + CDN, AdvAgg, Blazy, Image Optimize; BigPipe is in core), editorial (Paragraphs, Gin, Linkit, Scheduler, Diff, Entity Usage, Webform), media (core Media + Focal Point, SVG Image), devops (Admin Toolbar, Devel, Config Split, Config Ignore, Environment Indicator, Stage File Proxy, Backup and Migrate), privacy/analytics (Google Tag, Klaro), search (Search API + Solr), and access/workflow (core Content Moderation/Workflows, Group, Permissions by Term). **Views, Layout Builder, Media, Content Moderation, Workflows, BigPipe, CKEditor 5, and Settings Tray are in core** — don't add contrib for them. Verify D11 compatibility per project page before shipping.

| Category | Module (machine name) | Status / D11 | Notes |
|---|---|---|---|
| SEO | Metatag (`metatag`) | Maintained, D11 | Meta/OG/Twitter tags; in Drupal CMS SEO recipe |
| SEO | Pathauto (`pathauto`) | Maintained, D11 | Token-based URL aliases; needs Token, CTools |
| SEO | Redirect (`redirect`) | Maintained, D11 | 301 management; pairs with Pathauto |
| SEO | Simple XML Sitemap (`simple_sitemap`) | Maintained, D11 | Multilingual XML sitemaps |
| SEO | Schema.org Metatag (`schema_metatag`) | Maintained, D11 | JSON-LD structured data |
| Spam/Security | Honeypot (`honeypot`) | Maintained, D11 | Spam prevention w/o UX cost; in Drupal CMS |
| Spam/Security | Antibot (`antibot`) | Maintained, D11 | JS-based bot blocking |
| Spam/Security | CAPTCHA (`captcha`) + reCAPTCHA | Maintained, D11 | Challenge on forms |
| Spam/Security | Security Kit (`seckit`) | Maintained, D11 | Security headers (CSP, etc.) |
| Spam/Security | Password Policy (`password_policy`) | Maintained, D11 | Complexity/expiry rules |
| Spam/Security | TFA (`tfa`) | Maintained, D11 | Two-factor auth |
| Spam/Security | Username Enumeration Prevention (`username_enumeration_prevention`) | Maintained, D11 | Hardening |
| Performance | Purge (`purge`) + provider | Maintained, D11 | Cache invalidation to Varnish/CDN |
| Performance | Advanced CSS/JS Aggregation (`advagg`) | Verify D11 release | Core aggregation improvements reduce its necessity |
| Performance | Blazy (`blazy`) | Maintained, D11 | Lazy-load images/video |
| Performance | ImageAPI Optimize (`imageapi_optimize`) | Maintained, D11 | Image compression pipelines |
| Performance | **BigPipe** | **In core** | Enable core module; no contrib needed |
| Editorial | Paragraphs (`paragraphs`) | Maintained, D11 | Component content; may cede ground to Experience Builder over time |
| Editorial | Gin (`gin`) | Maintained, D11 | Modern admin theme; default in Drupal CMS; Gin 4.x; needs Gin Toolbar |
| Editorial | Linkit (`linkit`) | Maintained, D11 | Autocomplete internal links in CKEditor |
| Editorial | Scheduler (`scheduler`) | Maintained, D11 | Publish/unpublish scheduling |
| Editorial | Diff (`diff`) | Maintained, D11 | Revision comparison |
| Editorial | Entity Usage (`entity_usage`) | Maintained, D11 | Track where entities are referenced |
| Forms | Webform (`webform`) | Maintained, D11 | The forms platform; large ecosystem |
| Media | **Media / Media Library** | **In core** | Use core; add contrib only for extras |
| Media | Focal Point (`focal_point`) | Maintained, D11 | Crop focus for responsive images |
| Media | SVG Image (`svg_image`) | Maintained, D11 | SVG upload support |
| DevOps | Admin Toolbar (`admin_toolbar`) | Maintained, D11 | Dropdown admin menu; near-universal |
| DevOps | Devel (`devel`) + Kint | Maintained, D11 | Debugging; dev-only |
| DevOps | Config Split (`config_split`) | Maintained, D11 | Env-specific config |
| DevOps | Config Ignore (`config_ignore`) | Maintained, D11 | Exclude config from import/export |
| DevOps | Environment Indicator (`environment_indicator`) | Maintained, D11 | Visual env banner |
| DevOps | Stage File Proxy (`stage_file_proxy`) | Maintained, D11 | Pull prod files on demand |
| DevOps | Backup and Migrate (`backup_migrate`) | Verify D11 release | DB/file backups |
| Privacy/Analytics | Google Tag (`google_tag`) | Maintained, D11 | GTM/GA4 |
| Privacy/Analytics | Klaro (`klaro`) | Maintained, D11 | Consent manager; in Drupal CMS privacy recipe |
| Search | Search API (`search_api`) + Solr (`search_api_solr`) | Maintained, D11 | Faceted/enterprise search |
| Access/Workflow | **Content Moderation / Workflows** | **In core** | Use core modules |
| Access/Workflow | Group (`group`) | Maintained, D11 | Access control / micro-sites |
| Access/Workflow | Permissions by Term (`permissions_by_term`) | Maintained, D11 | Taxonomy-based access |

**Now covered by core (drop the old contrib):** Views, CKEditor (now CKEditor 5), Media & Media Library, Layout Builder, Content Moderation, Workflows, BigPipe, Settings Tray, Datetime/Datetime Range, Layout Discovery, JSON:API, Migrate. **EU Cookie Compliance** is being superseded by **Klaro** in modern builds (Klaro ships in Drupal CMS). **AdvAgg** and **Backup and Migrate**: confirm the current stable D11 release before relying on them.

**In Drupal CMS by default (via recipes):** the base install pulls a curated set (~57 projects across recipes, per TheDropTimes' inventory). Confirmed inclusions include **Gin** (admin) with **Gin Toolbar**, **Editoria11y** (Accessibility Tools recipe), **Metatag/Pathauto/Simple XML Sitemap/Redirect** (SEO), **Klaro** (privacy), **Honeypot** (spam), plus **Field Group**, **Token**, and dependency utilities (Checklist API, jQuery UI shims, Date Augmenter API). Recipes are opt-in during install and can be applied later.

---

## 6. A Plan to Contribute More to Drupal.org Code and Community

**TL;DR:** Set up a real-name Drupal.org account + full profile, join Slack, and use the **merge-request-from-issue-fork** workflow (patches are dead). Earn credit through code, review, docs, mentoring, events, and translations — credit is granted by maintainers and feeds your (and your org's) marketplace rank. Start with **Novice**-tagged issues and contribution days, run a **DDEV + `drupal/core-dev`** local setup, and build toward **maintaining/adopting contrib** and **opting projects into security coverage**. For a solo studio, the fastest brand ROI is: maintain 1–3 useful contrib modules, get them security-covered, list your org, and speak at a DrupalCamp.

### Account, profile, credit
- Create a Drupal.org account (real name; shared accounts are banned from committing). Fill out the profile, add your organization, and link your GitLab (`git.drupalcode.org`) identity.
- **Credit system**: contributions on issues can credit multiple people and an organization. Only **maintainers grant credit**. Credited work types: code, issue triage/review, documentation, mentoring, event volunteering/sponsorship, translations, security review. Credits are public and feed the **marketplace ranking** (issue credits from the last 12 months, weighted by project usage — a 1–10 score where 10 ≈ 1,000,000 sites; issues fixed in the last 90 days count for marketplace sort), plus case studies, DA membership/support, events sponsored, and projects supported. Certified Partner tiers derive from weighted credits + verified case studies + tier.
- **Individual DA membership** (Ripple Makers) gives a small org boost per member and supports the DA.

### Finding good first work
- **Novice** tag + "good first issue"-style filters in issue queues.
- **Needs Review Queue Initiative** and RTBC review work — reviewing others' MRs is high-value and earns credit.
- **Contribution days** at DrupalCon/DrupalCamps (mentored).

### Local core dev setup (DDEV)
- Use **DDEV** + `git clone` of core (or `coder.ddev.com` cloud workspaces, which include a Drupal Issue Picker to check out an issue fork automatically). Install dev tooling via **`drupal/core-dev`** (`composer require --dev drupal/core-dev` in a full project; for a core clone, `composer install` pulls it). If Composer balks on core-dev packages, `composer install --prefer-source` is a known workaround.
- Run checks locally before pushing: `core/scripts/dev/commit-code-check.sh` (PHPCS, PHPStan, ESLint/Stylelint, Cspell), and `vendor/bin/phpunit`.
- For deprecations on your own projects: `palantirnet/drupal-rector` + `mglaman/drupal-check`.

### Merge request workflow (current)
1. Find or create an issue.
2. Click **Create issue fork** on the issue; a fork + branch appear on `git.drupalcode.org`.
3. Branch naming: default is `{issue-number}-{short-description}` (e.g., `3456789-fix-typo`); hyphen-separated, concise (Git's limit is 255 chars). For multi-dev issues, work on the issue branch; for simple solo fixes you can commit directly to it.
4. Clone the fork, add it as a remote, commit, push.
5. On the issue, click **Compare** → **Create merge request**; source = issue branch, target = the correct dev branch (e.g., `11.x` / `11.2.x`).
6. To re-roll: **rebase** (preferred — cleaner history for reviewers) or merge upstream into the same branch; don't open multiple MRs per issue. Additional commits auto-update the MR and re-trigger CI. Live-preview deployments are available for testing MRs.
7. Respond to review, set status (Needs work / Needs review / RTBC), keep the issue summary updated.

### Becoming a contrib maintainer / adopting abandoned modules
- Offer to co-maintain via the project's issue queue; maintainers can grant you commit access.
- **Adopt abandoned projects** through the ownership-transfer process (comment in the queue, then follow the "Abandoned"/ownership-transfer webform); the DA/maintainers can reassign.
- **Security coverage opt-in**: as of the 2024 change, there's no separate project-application gate — instead you apply once for the **"vetted" role** by submitting one project to the **security advisory coverage applications** queue (`drupal.org/project/projectapplications`). Requirements: a full (non-sandbox) project, write-to-VCS access, no known security issues, and a **10-day wait** for new projects. Use the **review bonus** (review 3 other applications, reference them) to fast-track — the backlog can otherwise run months. Once vetted, you can opt any current/future project into coverage — but only **stable releases** get the shield, and once opted in you can't opt out (only the Security Team can reverse it).

### Community, docs, and visibility
- **Slack**: join and lurk the relevant channels (`#contribute`, `#gitlab`, initiative channels) before diving in.
- **Documentation**: edit Drupal.org docs pages, write change records, improve module READMEs — all creditable.
- **Speaking**: submit to DrupalCamps (low barrier) then DrupalCon (e.g., Rotterdam 2026); talks build personal brand fast.
- **Initiatives**: join a strategic initiative (Drupal CMS, Experience Builder, AI, Automatic Updates) via its Slack channel and meetings.

### Business/brand angle
- **Organization credit** rolls up individual contributions to your studio's Drupal.org org page and marketplace position.
- **Marketplace listing** for agencies requires org setup + contributions + verified **case studies**; Certified Partner tiers need weighted credits + case studies + tier.
- Maintaining a widely-used module is the single highest-leverage reputation move for a solo shop (usage-weighted credit means a high-usage project earns far more per issue).

### Phased timeline (for an already-expert solo dev/agency)
- **First 30 days**: complete profile + org; join Slack; set up DDEV core-dev; fix 2–3 **Novice** issues via MR; review 3 security applications and file your own vetted-role application; publish or adopt one small contrib module. *(This part is genuinely achievable in a few evenings for someone at your level.)*
- **By 90 days**: get your module security-covered; become co-maintainer on one existing module; submit a DrupalCamp talk; land a handful of credited core/contrib MRs; start triaging one project's queue regularly.
- **By 6 months**: maintain 1–3 modules with green GitLab CI; speak at a Camp; contribute to one initiative; accumulate enough credited work (and 1–2 case studies) to make your org visible on the marketplace; mentor at a contribution day.
- **Benchmarks that change the plan**: if a module you maintain crosses meaningful usage, prioritize its issue queue and security responsiveness over new work; if you're chasing Certified Partner tier, weight effort toward high-usage projects (credit is usage-weighted) and case studies; when Drupal 12 lands (Dec 2026), pivot toward deprecation cleanup (Rector) and D12 compatibility MRs, which will be plentiful and easily creditable.

---

## Caveats and Confidence
- **PHPStan level**: core is at **level 1** in Drupal 11.4.5 (verified from the shipped `core/phpstan.neon.dist`), with explicit intent to reach level 2. Older sources citing "level 2" reflect the PHPStan 1.x era (pre-11.2).
- **Drupal 12 details** (Symfony 8, PHP 8.5, PHPUnit 12+) are **targeted/planned**; D12 is unreleased as of 10 Aug 2026 and the exact PHPUnit pin is still in flux. The confirmed release window is the week of 7 Dec 2026.
- **Playwright replacing Nightwatch** is a **proposal in progress** (#3467492), not a completed migration.
- **Experience Builder** timing ("late 2025", "Drupal CMS 2.0") is a moving target — verify current XB release status before planning around it.
- **Module D11 compatibility** and **Drupal CMS default inclusions** change release-to-release; confirm on each project page and the current `drupal_cms` recipe set before shipping. AdvAgg and Backup and Migrate specifically warrant a release check.
- Primary facts are anchored to Drupal.org, the core issue queue, the Drupal Association, and the axe-core/Deque and Editoria11y/Princeton primary sources; agency blogs (Lullabot, PreviousNext, Vardot, Acquia, Palantir, DrupalEasy, mglaman.dev) were used for corroboration.