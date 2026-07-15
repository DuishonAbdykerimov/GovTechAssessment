public with sharing class GrantDisbursementService {

    public static void validateSupportOptionChanges(
        List<Contact> newContacts,
        Map<Id, Contact> oldMap
    ) {
        Set<Id> changedApplicantIds = new Set<Id>();
        Map<Id, Contact> changedApplicants = new Map<Id, Contact>();

        for (Contact applicant : newContacts) {
            Contact oldApplicant = oldMap.get(applicant.Id);

            if (
                oldApplicant != null &&
                applicant.Support_Option__c !=
                    oldApplicant.Support_Option__c &&
                String.isNotBlank(applicant.Support_Option__c)
            ) {
                changedApplicantIds.add(applicant.Id);
                changedApplicants.put(applicant.Id, applicant);
            }
        }

        if (changedApplicantIds.isEmpty()) {
            return;
        }

        Map<String, Support_Option__mdt> optionsByLabel =
            getActiveOptionsByLabel();

        Map<Id, Decimal> paidAmountsByApplicant =
            new Map<Id, Decimal>();

        Map<Id, Integer> paidCountByApplicant =
            new Map<Id, Integer>();

        for (Grant_Disbursement__c disbursement : [
            SELECT
                Grant_Applicant__c,
                Amount_to_be_Disbursed__c,
                Grant_is_Disbursed__c
            FROM Grant_Disbursement__c
            WHERE
                Grant_Applicant__c IN :changedApplicantIds
                AND Grant_is_Disbursed__c = true
        ]) {
            Id applicantId = disbursement.Grant_Applicant__c;

            Decimal currentPaidAmount =
                paidAmountsByApplicant.containsKey(applicantId)
                    ? paidAmountsByApplicant.get(applicantId)
                    : 0;

            paidAmountsByApplicant.put(
                applicantId,
                currentPaidAmount +
                    disbursement.Amount_to_be_Disbursed__c
            );

            Integer currentPaidCount =
                paidCountByApplicant.containsKey(applicantId)
                    ? paidCountByApplicant.get(applicantId)
                    : 0;

            paidCountByApplicant.put(
                applicantId,
                currentPaidCount + 1
            );
        }

        for (Id applicantId : changedApplicants.keySet()) {
            Contact applicant = changedApplicants.get(applicantId);

            Support_Option__mdt newOption =
                optionsByLabel.get(applicant.Support_Option__c);

            if (newOption == null) {
                applicant.Support_Option__c.addError(
                    'The selected support option is not active or does not exist.'
                );
                continue;
            }

            Decimal alreadyDisbursed =
                paidAmountsByApplicant.containsKey(applicantId)
                    ? paidAmountsByApplicant.get(applicantId)
                    : 0;

            Integer paidMonthCount =
                paidCountByApplicant.containsKey(applicantId)
                    ? paidCountByApplicant.get(applicantId)
                    : 0;

            Decimal newOptionTotal =
                newOption.Monthly_Amount__c *
                newOption.Duration_Months__c;

            Integer newDurationMonths =
                Integer.valueOf(newOption.Duration_Months__c);

            if (alreadyDisbursed > newOptionTotal) {
                applicant.Support_Option__c.addError(
                    'The support option cannot be changed because the amount already disbursed exceeds the total amount of the selected option.'
                );
            }

            if (
                paidMonthCount >= newDurationMonths &&
                alreadyDisbursed < newOptionTotal
            ) {
                applicant.Support_Option__c.addError(
                    'The selected support option does not have enough remaining months to distribute the outstanding amount.'
                );
            }
        }
    }

    public static void processApplications(
        List<Contact> newContacts,
        Map<Id, Contact> oldMap
    ) {
        Set<Id> eligibleApplicantIds = new Set<Id>();
        Set<Id> optionChangedApplicantIds = new Set<Id>();

        Map<Id, Contact> contactsById = new Map<Id, Contact>();

        for (Contact applicant : newContacts) {
            contactsById.put(applicant.Id, applicant);

            if (
                applicant.Id != null &&
                String.isNotBlank(applicant.Application_Status__c) &&
                applicant.Eligibility_Status__c == 'Eligible' &&
                String.isNotBlank(applicant.Support_Option__c)
            ) {
                eligibleApplicantIds.add(applicant.Id);
            }

            if (
                oldMap != null &&
                oldMap.containsKey(applicant.Id) &&
                applicant.Support_Option__c !=
                    oldMap.get(applicant.Id).Support_Option__c
            ) {
                optionChangedApplicantIds.add(applicant.Id);
            }
        }

        if (eligibleApplicantIds.isEmpty()) {
            return;
        }

        Map<String, Support_Option__mdt> optionsByLabel =
            getActiveOptionsByLabel();

        List<Grant_Disbursement__c> existingDisbursements = [
            SELECT
                Id,
                Grant_Applicant__c,
                Amount_to_be_Disbursed__c,
                Grant_is_Disbursed__c,
                Disbursed_Date__c,
                Support_Option__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c IN :eligibleApplicantIds
            ORDER BY Disbursed_Date__c ASC
        ];

        Map<Id, List<Grant_Disbursement__c>>
            disbursementsByApplicant =
                new Map<Id, List<Grant_Disbursement__c>>();

        for (Grant_Disbursement__c disbursement :
            existingDisbursements
        ) {
            Id applicantId = disbursement.Grant_Applicant__c;

            if (!disbursementsByApplicant.containsKey(applicantId)) {
                disbursementsByApplicant.put(
                    applicantId,
                    new List<Grant_Disbursement__c>()
                );
            }

            disbursementsByApplicant
                .get(applicantId)
                .add(disbursement);
        }

        List<Grant_Disbursement__c> recordsToDelete =
            new List<Grant_Disbursement__c>();

        List<Grant_Disbursement__c> recordsToInsert =
            new List<Grant_Disbursement__c>();

        for (Id applicantId : eligibleApplicantIds) {
            Contact applicant = contactsById.get(applicantId);

            Support_Option__mdt selectedOption =
                optionsByLabel.get(applicant.Support_Option__c);

            if (selectedOption == null) {
                continue;
            }

            List<Grant_Disbursement__c> applicantDisbursements =
                disbursementsByApplicant.containsKey(applicantId)
                    ? disbursementsByApplicant.get(applicantId)
                    : new List<Grant_Disbursement__c>();

            Boolean supportOptionChanged =
                optionChangedApplicantIds.contains(applicantId);

            if (!supportOptionChanged) {
                if (applicantDisbursements.isEmpty()) {
                    recordsToInsert.addAll(
                        createInitialSchedule(
                            applicant,
                            selectedOption
                        )
                    );
                }

                continue;
            }

            Decimal alreadyDisbursed = 0;
            Integer paidMonthCount = 0;
            Date latestPaidDate;

            for (Grant_Disbursement__c disbursement :
                applicantDisbursements
            ) {
                if (disbursement.Grant_is_Disbursed__c) {
                    alreadyDisbursed +=
                        disbursement.Amount_to_be_Disbursed__c;

                    paidMonthCount++;

                    if (
                        latestPaidDate == null ||
                        disbursement.Disbursed_Date__c >
                            latestPaidDate
                    ) {
                        latestPaidDate =
                            disbursement.Disbursed_Date__c;
                    }
                } else {
                    recordsToDelete.add(disbursement);
                }
            }

            Decimal newOptionTotal =
                selectedOption.Monthly_Amount__c *
                selectedOption.Duration_Months__c;

            Decimal remainingAmount =
                newOptionTotal - alreadyDisbursed;

            Integer newDurationMonths =
                Integer.valueOf(
                    selectedOption.Duration_Months__c
                );

            Integer remainingMonths =
                newDurationMonths - paidMonthCount;

            if (
                remainingAmount <= 0 ||
                remainingMonths <= 0
            ) {
                continue;
            }

            Date firstNewDisbursementDate;

            if (latestPaidDate != null) {
                firstNewDisbursementDate =
                    latestPaidDate.toStartOfMonth().addMonths(1);
            } else {
                firstNewDisbursementDate =
                    Date.today().toStartOfMonth().addMonths(1);
            }

            Decimal regularMonthlyAmount =
                (remainingAmount / remainingMonths)
                    .setScale(2, System.RoundingMode.DOWN);

            for (
                Integer monthIndex = 1;
                monthIndex <= remainingMonths;
                monthIndex++
            ) {
                Decimal paymentAmount =
                    regularMonthlyAmount;

                if (monthIndex == remainingMonths) {
                    paymentAmount =
                        remainingAmount -
                        (
                            regularMonthlyAmount *
                            (remainingMonths - 1)
                        );
                }

                recordsToInsert.add(
                    new Grant_Disbursement__c(
                        Grant_Applicant__c = applicantId,
                        Amount_to_be_Disbursed__c =
                            paymentAmount,
                        Grant_is_Disbursed__c = false,
                        Disbursed_Date__c =
                            firstNewDisbursementDate.addMonths(
                                monthIndex - 1
                            ),
                        Support_Option__c =
                            applicant.Support_Option__c,
                        Sequence_Number__c =
                            paidMonthCount + monthIndex
                    )
                );
            }
        }

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }

    private static List<Grant_Disbursement__c>
        createInitialSchedule(
            Contact applicant,
            Support_Option__mdt selectedOption
        ) {
        List<Grant_Disbursement__c> schedule =
            new List<Grant_Disbursement__c>();

        Date submissionDate =
            applicant.Application_Submission_Date__c == null
                ? Date.today()
                : applicant.Application_Submission_Date__c;

        Date firstDisbursementDate =
            submissionDate.toStartOfMonth().addMonths(1);

        Integer durationMonths =
            Integer.valueOf(
                selectedOption.Duration_Months__c
            );

        for (
            Integer monthNumber = 1;
            monthNumber <= durationMonths;
            monthNumber++
        ) {
            schedule.add(
                new Grant_Disbursement__c(
                    Grant_Applicant__c = applicant.Id,
                    Amount_to_be_Disbursed__c =
                        selectedOption.Monthly_Amount__c,
                    Grant_is_Disbursed__c = false,
                    Disbursed_Date__c =
                        firstDisbursementDate.addMonths(
                            monthNumber - 1
                        ),
                    Support_Option__c =
                        applicant.Support_Option__c,
                    Sequence_Number__c = monthNumber
                )
            );
        }

        return schedule;
    }

    private static Map<String, Support_Option__mdt>
        getActiveOptionsByLabel()
    {
        Map<String, Support_Option__mdt> optionsByLabel =
            new Map<String, Support_Option__mdt>();

        for (Support_Option__mdt optionRecord : [
            SELECT
                MasterLabel,
                Monthly_Amount__c,
                Duration_Months__c,
                Active__c
            FROM Support_Option__mdt
            WHERE Active__c = true
        ]) {
            optionsByLabel.put(
                optionRecord.MasterLabel,
                optionRecord
            );
        }

        return optionsByLabel;
    }
}