# End-to-End Tests — Agency X Grant Portal

Production-grade [Playwright](https://playwright.dev/) suite that validates the
public **Grant Application** form (LWC `grantApplicationForm`) on the Agency X
Experience Cloud site, with rich [Allure](https://allurereport.org/) reporting.

## Architecture

The suite follows the **Page Object Model** with custom Playwright fixtures, so
specs read as business scenarios rather than low-level automation.

```
tests/
├── e2e/
│   └── grant-application.spec.js   # Test scenarios (steps + Allure metadata)
├── pages/
│   └── grant-application.page.js   # Page Object: locators + actions
├── fixtures/
│   └── portal.fixtures.js          # Custom fixture: pre-opened application page
├── data/
│   └── applicants.js               # Test-data builders (randomised, idempotent)
├── global-setup.js                 # One-time authentication → storageState
└── .auth/state.json                # Cached session (git-ignored, auto-generated)
```

### Why this design

- **Page Object Model** — locators and actions live in one place; specs never
  touch raw selectors, so UI changes require a single edit.
- **Custom fixtures** — every test receives an already-opened, authenticated
  `grantApplicationPage`; no repeated boilerplate.
- **Authenticate once** — `global-setup.js` signs in via the Salesforce CLI and
  saves the session to `storageState`. Tests run fully in parallel and share it,
  which keeps the suite fast and avoids rate limiting.
- **Idempotent data** — phone numbers (the org's unique key) are randomised, so
  the suite can run repeatedly without cleanup.

## Prerequisites

1. Node.js 18+ and project dependencies installed:

```bash
npm install
npx playwright install
```

2. An authenticated Salesforce org (Salesforce CLI):

```bash
sf org login web --alias grant-portal
```

3. A `.env` file in the project root:

```bash
PORTAL_URL=https://<your-domain>.my.site.com/agencyxgrants/
SF_TARGET_ORG=<username-or-alias>
SF_SITE_ID=<Experience-site-id>
SF_COMMUNITY_PATH=<community-url-path>
```

## Running the tests

```bash
npm run test:e2e            # headless run (all browsers/projects)
npm run test:e2e:headed     # watch it run in a real browser
npm run test:e2e:ui         # Playwright interactive UI mode
npm run test:e2e:report     # open the last Playwright HTML report
```

## Allure reporting

```bash
npm run allure:serve        # generate + open a temporary report (quickest)
npm run allure:generate     # build static report into allure-report/
npm run allure:open         # open the generated static report
npm run test:e2e:allure     # run tests, then build & open the report
```

The Allure report includes, per test:

- **Suites / features / stories** grouped via `epic` / `feature` / `story`
- **Severity** and **tags** (`smoke`, `regression`, `validation`, …)
- **Step-by-step** breakdown from `test.step(...)`
- **Screenshots** attached at each key stage
- **Trace, video and screenshots on failure** (from the Playwright config)

## Test coverage

| Scenario                                   | Severity | Tags                   |
| ------------------------------------------ | -------- | ---------------------- |
| Application form renders all fields        | critical | smoke, ui              |
| Eligible applicant submits successfully    | blocker  | regression, happy-path |
| Invalid Singapore phone number is rejected | normal   | regression, validation |
