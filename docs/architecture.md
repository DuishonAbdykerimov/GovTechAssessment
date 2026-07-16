# Architecture

## Layering

| Layer   | Components                                          | Responsibility                                           |
| ------- | --------------------------------------------------- | -------------------------------------------------------- |
| UI      | `grantApplicationForm` (LWC)                        | Collect input, client validation, call Apex              |
| Entry   | `GrantApplicationController`                        | Support-option query, submit + server validation, upsert |
| Trigger | `ContactTrigger` → `GrantApplicationTriggerHandler` | Route before/after insert/update                         |
| Domain  | `GrantApplicationService`                           | Submission date, phone key, eligibility                  |
| Domain  | `GrantDisbursementService`                          | Option-change guards + disbursement schedule             |
| Config  | `Support_Option__mdt`                               | Programme amount / duration / active / order             |
| Data    | `Contact`, `Grant_Disbursement__c`                  | Applicant + monthly payments                             |

## System flow

```mermaid
flowchart LR
    A[Public Applicant] --> B[Experience Cloud]
    B --> C[LWC grantApplicationForm]
    C --> D[GrantApplicationController]
    D <--> E[(Support_Option__mdt)]
    D --> F[(Contact)]
    F --> G[ContactTrigger]
    G --> H[GrantApplicationService]
    G --> I[GrantDisbursementService]
    I --> J[(Grant_Disbursement__c)]
```

## Trigger orchestration

```mermaid
sequenceDiagram
    participant LWC as grantApplicationForm
    participant CTRL as GrantApplicationController
    participant TR as ContactTrigger
    participant GAS as GrantApplicationService
    participant GDS as GrantDisbursementService
    participant DB as Contact / Grant_Disbursement__c

    LWC->>CTRL: submitApplication(...)
    CTRL->>CTRL: validateInput
    CTRL->>DB: upsert Contact (Phone Key)
    DB->>TR: before insert/update
    TR->>GAS: prepareApplications
    Note over GAS: submission date, phone key, eligibility
    TR->>GDS: validateSupportOptionChanges (before update)
    DB->>TR: after insert/update
    TR->>GDS: processApplications
    GDS->>DB: insert / delete Grant_Disbursement__c
    CTRL-->>LWC: ApplicationResponse
```

## Why this shape

- **Thin controller** — UI-facing validation and upsert only.
- **Trigger handler** — keeps the trigger one line and testable.
- **Services** — eligibility and disbursement stay independent and bulk-safe.
- **Custom Metadata** — programme changes without a code deploy (activate / amounts / months).
