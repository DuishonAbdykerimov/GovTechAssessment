# Agency X Grant Portal — Salesforce + Playwright QA Automation

**Production-ready Salesforce grant-management app with an end-to-end
Playwright automation framework** built on the Page Object Model, custom
fixtures, Allure reporting and GitHub Actions CI.

[![E2E Tests](https://github.com/DuishonAbdykerimov/GovTechAssessment/actions/workflows/e2e-tests.yml/badge.svg)](https://github.com/DuishonAbdykerimov/GovTechAssessment/actions/workflows/e2e-tests.yml)
[![Allure Report](https://img.shields.io/badge/Allure_Report-Live-orange)](https://duishonabdykerimov.github.io/GovTechAssessment/)
[![Playwright](https://img.shields.io/badge/Playwright-1.61-2EAD33?logo=playwright&logoColor=white)](https://playwright.dev)
[![Browsers](https://img.shields.io/badge/Browsers-Chromium_·_Firefox_·_WebKit-2EAD33?logo=playwright&logoColor=white)](https://playwright.dev/docs/browsers)
[![Accessibility](https://img.shields.io/badge/A11y-axe--core_WCAG_2.1-663399?logo=accessibleicon&logoColor=white)](https://github.com/dequelabs/axe-core)
[![Salesforce](https://img.shields.io/badge/Salesforce-Apex_%2B_LWC-00A1E0?logo=salesforce&logoColor=white)](https://developer.salesforce.com)
[![Node.js](https://img.shields.io/badge/Node.js-22-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](Dockerfile)
[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/DuishonAbdykerimov/GovTechAssessment/actions)

[Live Allure Report](https://duishonabdykerimov.github.io/GovTechAssessment/) ·
[E2E Docs](tests/README.md)

---

## Overview

A financial-support grant portal built on the Salesforce platform (Apex, LWC,
triggers, validation rules and custom metadata) and exposed to the public
through an Experience Cloud site. Applicants submit their details, the system
evaluates eligibility, and disbursement schedules are generated automatically.

The repository is designed to demonstrate **Middle+/Senior QA Automation**
competencies: a scalable Page Object architecture, hybrid unit + E2E coverage,
CI/CD, and rich reporting.

## Key Features

| Area           | Implementation                                                       |
| -------------- | -------------------------------------------------------------------- |
| Architecture   | Page Object Model, custom Playwright fixtures, test-data builders    |
| App platform   | Salesforce Apex services + triggers, LWC UI, validation rules        |
| Test types     | E2E UI · Eligibility · Negative / validation · **A11y** · **Visual** |
| Cross-browser  | **Chromium · Firefox · WebKit** via a CI matrix                      |
| Accessibility  | Automated **WCAG 2.1 A/AA** audit (`@axe-core/playwright`)           |
| Visual         | Pixel **regression** snapshots with a dedicated baseline workflow    |
| Unit tests     | LWC Jest (component, with coverage) + Apex test classes              |
| Reporting      | Playwright HTML + **Allure** (screenshots, steps, severity, tags)    |
| Authentication | One-time Salesforce CLI login → shared `storageState`                |
| CI/CD          | GitHub Actions → matrix tests → **merged Allure** → GitHub Pages     |
| Config         | `.env` driven — no hardcoded credentials in tests                    |
| Best practices | Auto-waiting, role-based locators, parallel-safe, idempotent data    |

## Architecture

```
force-app/main/default/      # Salesforce source
├── classes/                 # Apex services, controller, triggers, tests
├── lwc/grantApplicationForm # Lightning Web Component + Jest tests
├── objects/                 # Custom fields, validation rules
└── customMetadata/          # Support Option configuration

tests/                       # Playwright E2E framework
├── e2e/                     # Functional, negative & accessibility specs
├── visual/                  # Visual-regression spec + committed baselines
├── pages/                   # Page Objects (locators + actions)
├── fixtures/                # Custom fixtures (pre-opened, authenticated page)
├── data/                    # Test-data builders (randomised, idempotent)
└── global-setup.js          # One-time authentication → storageState

.github/workflows/           # CI: unit + E2E matrix + Allure + baseline refresh
Dockerfile                   # Reproducible Playwright + Salesforce CLI runner
docker-compose.yml           # One-command containerised E2E run
```

## Screenshots

### Grant Application form (Experience Cloud)

![Grant application form](docs/screenshots/application-form.png)

### Allure Report (CI → GitHub Pages)

![Allure dashboard](docs/screenshots/allure-overview.png)

_Live Allure dashboard — functional, accessibility & visual suites across
Chromium, Firefox and WebKit, merged into a single trend-tracked report._

## Getting Started

```bash
# 1. Install dependencies
npm install
npx playwright install

# 2. Authenticate a Salesforce org
sf org login web --alias grant-portal

# 3. Configure environment
cp .env.example .env   # then fill in the values below
```

`.env`:

```bash
PORTAL_URL=https://<your-domain>.my.site.com/agencyxgrants/
SF_TARGET_ORG=<username-or-alias>
SF_SITE_ID=<Experience-site-id>
SF_COMMUNITY_PATH=<community-url-path>
```

## Running the tests

```bash
npm run test:unit                 # LWC Jest unit tests
npm run test:unit:coverage        # LWC Jest with coverage report
npm run test:e2e                  # Playwright E2E across all browsers + a11y + visual
npm run test:e2e -- --project=chromium   # a single browser
npm run test:e2e -- --project=visual     # visual regression only
npm run test:e2e:update-snapshots # refresh visual baselines (this OS)
npm run test:e2e:headed           # watch it run in a real browser
npm run test:e2e:ui               # Playwright interactive UI mode
npm run allure:serve              # generate + open the Allure report
```

> Visual baselines are OS-specific. Local runs use macOS/Windows baselines;
> the Linux baselines used by CI are generated by the **Update Visual
> Baselines** workflow (Actions → run manually) and committed automatically.

## Running the tests in Docker

For a fully reproducible run (no local Node/browser setup required), use the
provided image — it is based on the official Playwright image, so all browsers
and OS dependencies are pinned to the project's version, and it bundles the
Salesforce CLI used for authentication.

```bash
# 1. Export the Salesforce credential (kept out of the image)
export SFDX_AUTH_URL="$(sf org display --verbose --target-org <org> \
  --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["sfdxAuthUrl"])')"

# 2. Build and run the suite (PORTAL_URL/SF_SITE_ID/SF_COMMUNITY_PATH from .env)
docker compose run --rm e2e
```

Results are written to `./allure-results` and `./playwright-report` on the host.
You can override the command, e.g. run a single browser:

```bash
docker compose run --rm e2e npx playwright test --project=chromium
```

## Test coverage (E2E)

Every functional/accessibility scenario runs on **Chromium, Firefox and
WebKit**; the visual-regression scenario is pinned to a single engine for
stable baselines.

| Scenario                                      | Severity | Tags                    |
| --------------------------------------------- | -------- | ----------------------- |
| Application form renders all fields           | critical | smoke, ui               |
| Eligible applicant submits successfully       | blocker  | regression, happy-path  |
| Applicant above income threshold not eligible | critical | regression, eligibility |
| Eligible submission with Option Two           | normal   | regression, happy-path  |
| Eligible submission with Option Three         | normal   | regression, happy-path  |
| Invalid Singapore phone number rejected       | normal   | regression, validation  |
| Invalid Singapore postal code rejected        | normal   | regression, validation  |
| Form meets WCAG 2.1 A/AA (no critical issues) | critical | a11y, wcag              |
| Form matches its approved visual baseline     | normal   | visual, ui              |

## CI/CD

Every push and pull request runs these jobs via **GitHub Actions**
(`.github/workflows/e2e-tests.yml`):

1. **LWC Unit Tests** — Jest with coverage (report uploaded as an artifact).
2. **E2E matrix** — one job per browser (`chromium`, `firefox`, `webkit`),
   each authenticates to the org and runs the functional, accessibility and
   negative suites, uploading its Allure results as an artifact.
3. **Publish Allure Report** — merges the results from all browsers, restores
   historical trends, generates one Allure report and publishes it to
   **GitHub Pages**.

A separate **Update Visual Baselines**
(`.github/workflows/update-visual-baselines.yml`) workflow regenerates the
Linux visual baselines on demand and commits them back.

### Required repository secrets

| Secret              | Description                                      |
| ------------------- | ------------------------------------------------ |
| `SFDX_AUTH_URL`     | `sf org display --verbose` → _Sfdx Auth Url_     |
| `PORTAL_URL`        | Public Experience Cloud form URL                 |
| `SF_SITE_ID`        | Experience site id                               |
| `SF_COMMUNITY_PATH` | Community URL path used for authenticated access |

---

<div align="center">

**Author — Duishon Abdykerimov**

QA Automation Engineer

[![GitHub](https://img.shields.io/badge/GitHub-DuishonAbdykerimov-181717?logo=github&logoColor=white)](https://github.com/DuishonAbdykerimov)

<sub>Built with Salesforce · Playwright · Allure · GitHub Actions · Docker</sub>

</div>
