# Bulk upload

Grant Contacts can be loaded in bulk (Data Loader, `sf data upsert`, or Import Wizard).
The natural external id is `Grant_Applicant_Phone_Key__c` (digits-only phone).

## Create sample

File: [`data/grant_applicants.csv`](../data/grant_applicants.csv)

| FirstName | LastName        | Phone        | Postal | Income | Option       | Status    | Phone key  |
| --------- | --------------- | ------------ | ------ | -----: | ------------ | --------- | ---------- |
| Bulk      | Applicant One   | 65 6812 3460 | 123460 |   1500 | Option One   | Submitted | 6568123460 |
| Bulk      | Applicant Two   | 65 6812 3461 | 123461 |   1400 | Option Two   | Submitted | 6568123461 |
| Bulk      | Applicant Three | 65 6812 3462 | 123462 |   2200 | Option Three | Submitted | 6568123462 |

Expected outcomes after import + triggers:

- Applicant One / Two → **Eligible** + disbursement schedules
- Applicant Three (income 2200) → **Not Eligible**, no schedule

## Update sample

File: [`data/grant_applicants_update.csv`](../data/grant_applicants_update.csv)

Updates Applicant One by the same phone key (new name, postal code, income, Option Two).

## CLI example

```bash
sf data upsert bulk \
  --sobject Contact \
  --file data/grant_applicants.csv \
  --external-id Grant_Applicant_Phone_Key__c \
  --target-org grant-portal \
  --wait 10
```

## Notes

- Phone must match `65 #### ####` or Contact validation rules fail.
- Leave `Application_Status__c` blank only for non-grant Contacts.
- Triggers run in bulk; avoid row-by-row API inserts when loading large sets.
