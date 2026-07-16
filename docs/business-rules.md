# Business rules

## Eligibility (`GrantApplicationService`)

Constant: `ELIGIBILITY_INCOME_LIMIT = 2000`.

| Monthly income | Eligibility status |
| -------------- | ------------------ |
| `null`         | Pending            |
| `&lt; 2000`    | Eligible           |
| `≥ 2000`       | Not Eligible       |

Also on every grant Contact save:

1. Skip if `Application_Status__c` is blank (ordinary Contact).
2. Set `Application_Submission_Date__c` only when null.
3. Set `Grant_Applicant_Phone_Key__c` from digits in `Phone`.

## Initial disbursement schedule

When an applicant is **Eligible** with a valid active support option and has **no**
existing disbursements:

- First `Disbursed_Date__c` = start of month **after** `Application_Submission_Date__c`
- One row per month for `Duration_Months__c`
- Amount = `Monthly_Amount__c` from CMDT
- `Grant_is_Disbursed__c = false`
- `Sequence_Number__c = 1..N`

Not-eligible applicants get **no** schedule.

## Support option change

**Before update** (`validateSupportOptionChanges`):

- New option must exist and be active.
- Block if already paid amount **&gt;** new option total (`monthly × duration`).
- Block if paid month count **≥** new duration while paid amount is still below new total
  (not enough remaining months).

**After update** (`processApplications` when option changed):

1. Keep paid disbursements.
2. Delete unpaid disbursements.
3. Spread remaining amount over remaining months (down-round monthly; last month takes remainder).
4. Next unpaid date starts the month after the latest paid date (or next month if none paid).

## Controller validation

Before DML, `GrantApplicationController.validateInput` enforces:

- All required fields present
- Phone `^65 [0-9]{4} [0-9]{4}$`
- Postal code `^[0-9]{6}$`
- Income ≥ 0
- Support option exists and is active in CMDT

## Declarative validation (Contact)

See README §7 — same formats, scoped with `NOT(ISBLANK(TEXT(Application_Status__c)))`.
