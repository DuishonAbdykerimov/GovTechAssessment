# Agency X Grant Portal — Salesforce

A financial-support grant portal built on the Salesforce platform (Apex, LWC,
triggers, validation rules and custom metadata) and exposed to the public
through an Experience Cloud site. Applicants submit their details, the system
evaluates eligibility, and disbursement schedules are generated automatically.

[![Salesforce](https://img.shields.io/badge/Salesforce-Apex_%2B_LWC-00A1E0?logo=salesforce&logoColor=white)](https://developer.salesforce.com)
[![E2E Tests](https://github.com/DuishonAbdykerimov/GovTechAssessment/actions/workflows/e2e-tests.yml/badge.svg)](https://github.com/DuishonAbdykerimov/GovTechAssessment/actions/workflows/e2e-tests.yml)
[![Allure Report](https://img.shields.io/badge/Allure_Report-Live-orange)](https://duishonabdykerimov.github.io/GovTechAssessment/)

> **QA automation & end-to-end testing** live in [`tests/README.md`](tests/README.md) —
> Playwright (cross-browser + accessibility + visual), Docker and CI/CD.
> Live test report: <https://duishonabdykerimov.github.io/GovTechAssessment/>

## Architecture

```
force-app/main/default/
├── classes/                 # Apex services, controller, trigger handler, tests
├── lwc/grantApplicationForm # Lightning Web Component (public form) + Jest tests
├── triggers/                # Contact trigger
├── objects/                 # Custom fields & validation rules
└── customMetadata/          # Support Option configuration
```

## Overview

_TODO: describe the solution at a high level._

## Data model

_TODO: custom fields on Contact, Support Option custom metadata, keys._

## Business logic (Apex)

_TODO: services, controller, eligibility rules, disbursement generation._

## User interface (LWC)

_TODO: grantApplicationForm component, validation, UX._

## Automation & validation

_TODO: triggers, validation rules._

## Deployment

_TODO: how to deploy to a scratch/dev org, sample data import._

---

<div align="center">

**Author — Duishon Abdykerimov**

QA Automation Engineer

[![GitHub](https://img.shields.io/badge/GitHub-DuishonAbdykerimov-181717?logo=github&logoColor=white)](https://github.com/DuishonAbdykerimov)

<sub>Built with Salesforce · Playwright · Allure · GitHub Actions · Docker</sub>

</div>
