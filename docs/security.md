# Security model

## Apex

- `GrantApplicationController`, `GrantApplicationService`, `GrantDisbursementService`,
  and `GrantApplicationTriggerHandler` are declared `with sharing`.
- The only intentional public entry points are:
  - `getSupportOptions` (`@AuraEnabled(cacheable=true)`)
  - `submitApplication` (`@AuraEnabled`)
- Failures return `AuraHandledException` with a user-facing message (no stack dumps to the UI).

## Data scoping

- Grant automation runs only when `Application_Status__c` is populated.
- Ordinary Contacts (no application status) skip eligibility and disbursement logic.
- Validation rules use the same gate, so non-grant Contacts are not forced into grant formats.

## Experience Cloud

The LWC is exposed to:

- `lightningCommunity__Page`
- `lightningCommunity__Default`
- (also App / Home page for internal demos)

Org configuration (not in source) must grant the guest or community user:

| Access                                            | Why                |
| ------------------------------------------------- | ------------------ |
| Apex class access to `GrantApplicationController` | Form wire + submit |
| Create / update Contact (grant fields)            | Upsert application |
| Read `Support_Option__mdt`                        | Populate combobox  |
| Read related disbursements (internal users)       | Caseworker review  |

Principle of least privilege: guest users should not get broad org CRUD — only what the form needs.

## Secrets & CI

- Org credentials never live in the image or repo.
- CI / Docker receive `SFDX_AUTH_URL` at runtime via GitHub Secrets / env.
- Local `.env` is git-ignored; use `.env.example` as the template.
