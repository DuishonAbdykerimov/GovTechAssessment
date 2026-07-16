# Deployment

## Prerequisites

- Salesforce CLI (`sf`)
- Authenticated target org (scratch, sandbox, or Developer Edition)
- API version aligned with `sfdx-project.json` (`64.0`)

## Deploy source

```bash
sf org login web --alias grant-portal
sf project deploy start --source-dir force-app --target-org grant-portal
```

## Post-deploy checklist

1. Confirm Custom Metadata records: Option One / Two / Three are **Active**.
2. Confirm `Grant_Applicant_Phone_Key__c` is **External ID** + **Unique**.
3. Assign Experience Cloud guest/community access (Apex + fields) — see [`security.md`](security.md).
4. Place `grantApplicationForm` on the community page and **Publish**.
5. Smoke-test: submit an eligible and a not-eligible application.

## Verify with tests

```bash
# Apex
sf apex run test --target-org grant-portal --test-level RunLocalTests --result-format human --wait 30

# LWC
npm install
npm run test:unit

# E2E (needs .env — see .env.example)
npx playwright install
npm run test:e2e
```

## Sample data

See [`bulk-upload.md`](bulk-upload.md) and files under [`data/`](../data/).
