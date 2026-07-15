@IsTest
private class GrantDisbursementServiceTest {

    @IsTest
    static void shouldCreateInitialScheduleForOptionOne() {
        Contact applicant = createApplicant(
            'Initial',
            'Option One',
            '65 6812 3600',
            '223600',
            1500,
            'Option One'
        );

        Test.startTest();
        insert applicant;
        Test.stopTest();

        List<Grant_Disbursement__c> disbursements = [
            SELECT
                Amount_to_be_Disbursed__c,
                Disbursed_Date__c,
                Support_Option__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
            ORDER BY Sequence_Number__c
        ];

        System.assertEquals(3, disbursements.size());

        for (Integer i = 0; i < disbursements.size(); i++) {
            System.assertEquals(
                500,
                disbursements[i].Amount_to_be_Disbursed__c
            );
            System.assertEquals(
                'Option One',
                disbursements[i].Support_Option__c
            );
            System.assertEquals(
                i + 1,
                disbursements[i].Sequence_Number__c
            );
        }
    }

    @IsTest
    static void shouldReplaceUnpaidScheduleWhenOptionChanges() {
        Contact applicant = createApplicant(
            'Change',
            'Option',
            '65 6812 3601',
            '223601',
            1400,
            'Option One'
        );

        insert applicant;

        applicant.Support_Option__c = 'Option Two';

        Test.startTest();
        update applicant;
        Test.stopTest();

        List<Grant_Disbursement__c> disbursements = [
            SELECT
                Amount_to_be_Disbursed__c,
                Support_Option__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
            ORDER BY Sequence_Number__c
        ];

        System.assertEquals(6, disbursements.size());

        for (Grant_Disbursement__c record : disbursements) {
            System.assertEquals(
                300,
                record.Amount_to_be_Disbursed__c
            );
            System.assertEquals(
                'Option Two',
                record.Support_Option__c
            );
        }
    }

    @IsTest
    static void shouldRecalculateAfterPartialDisbursement() {
        Contact applicant = createApplicant(
            'Partial',
            'Disbursement',
            '65 6812 3602',
            '223602',
            1300,
            'Option Two'
        );

        insert applicant;

        List<Grant_Disbursement__c> originalSchedule = [
            SELECT
                Id,
                Grant_is_Disbursed__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
            ORDER BY Sequence_Number__c
        ];

        originalSchedule[0].Grant_is_Disbursed__c = true;
        originalSchedule[1].Grant_is_Disbursed__c = true;
        update new List<Grant_Disbursement__c>{
            originalSchedule[0],
            originalSchedule[1]
        };

        applicant.Support_Option__c = 'Option Three';

        Test.startTest();
        update applicant;
        Test.stopTest();

        List<Grant_Disbursement__c> recalculated = [
            SELECT
                Amount_to_be_Disbursed__c,
                Grant_is_Disbursed__c,
                Support_Option__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
            ORDER BY Sequence_Number__c
        ];

        System.assertEquals(12, recalculated.size());

        Integer paidCount = 0;
        Integer unpaidCount = 0;

        for (Grant_Disbursement__c record : recalculated) {
            if (record.Grant_is_Disbursed__c) {
                paidCount++;
            } else {
                unpaidCount++;
                System.assertEquals(
                    180,
                    record.Amount_to_be_Disbursed__c
                );
                System.assertEquals(
                    'Option Three',
                    record.Support_Option__c
                );
            }
        }

        System.assertEquals(2, paidCount);
        System.assertEquals(10, unpaidCount);
    }

    @IsTest
    static void shouldBlockInvalidDowngrade() {
        Contact applicant = createApplicant(
            'Invalid',
            'Downgrade',
            '65 6812 3603',
            '223603',
            1200,
            'Option Three'
        );

        insert applicant;

        List<Grant_Disbursement__c> schedule = [
            SELECT
                Id,
                Grant_is_Disbursed__c,
                Sequence_Number__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
            ORDER BY Sequence_Number__c
            LIMIT 8
        ];

        for (Grant_Disbursement__c record : schedule) {
            record.Grant_is_Disbursed__c = true;
        }

        update schedule;

        applicant.Support_Option__c = 'Option One';

        Test.startTest();

        Boolean failedAsExpected = false;

        try {
            update applicant;
        } catch (DmlException exceptionRecord) {
            failedAsExpected = true;

            System.assert(
                exceptionRecord.getMessage().contains(
                    'amount already disbursed exceeds'
                )
            );
        }

        Test.stopTest();

        System.assertEquals(
            true,
            failedAsExpected,
            'The downgrade should have been blocked.'
        );
    }

    private static Contact createApplicant(
        String firstName,
        String lastName,
        String phone,
        String postalCode,
        Decimal monthlyIncome,
        String supportOption
    ) {
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            Phone = phone,
            MailingPostalCode = postalCode,
            Monthly_Income__c = monthlyIncome,
            Support_Option__c = supportOption,
            Application_Status__c = 'Submitted'
        );
    }
}