@IsTest
private class GrantApplicationControllerTest {

    @IsTest
    static void shouldReturnActiveSupportOptions() {
        Test.startTest();

        List<GrantApplicationController.SupportOptionResponse> options =
            GrantApplicationController.getSupportOptions();

        Test.stopTest();

        System.assertEquals(
            3,
            options.size(),
            'Three active support options should be returned.'
        );

        System.assertEquals('Option One', options[0].label);
        System.assertEquals('Option One', options[0].value);
        System.assertEquals(500, options[0].monthlyAmount);
        System.assertEquals(3, options[0].durationMonths);

        System.assertEquals('Option Two', options[1].label);
        System.assertEquals(300, options[1].monthlyAmount);
        System.assertEquals(6, options[1].durationMonths);

        System.assertEquals('Option Three', options[2].label);
        System.assertEquals(200, options[2].monthlyAmount);
        System.assertEquals(12, options[2].durationMonths);
    }

    @IsTest
    static void shouldSubmitEligibleApplication() {
        Test.startTest();

        GrantApplicationController.ApplicationResponse response =
            GrantApplicationController.submitApplication(
                'Portal',
                'Eligible Applicant',
                '65 6812 3700',
                '323700',
                1500,
                'Option One'
            );

        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.contactId);
        System.assertEquals('Eligible', response.eligibilityStatus);

        System.assert(
            response.message.contains('eligible for financial support'),
            'A friendly eligibility message should be returned.'
        );

        Contact applicant = [
            SELECT
                FirstName,
                LastName,
                Phone,
                MailingPostalCode,
                Monthly_Income__c,
                Support_Option__c,
                Application_Status__c,
                Eligibility_Status__c,
                Grant_Applicant_Phone_Key__c
            FROM Contact
            WHERE Id = :response.contactId
        ];

        System.assertEquals('Portal', applicant.FirstName);
        System.assertEquals('Eligible Applicant', applicant.LastName);
        System.assertEquals('65 6812 3700', applicant.Phone);
        System.assertEquals('323700', applicant.MailingPostalCode);
        System.assertEquals(1500, applicant.Monthly_Income__c);
        System.assertEquals('Option One', applicant.Support_Option__c);
        System.assertEquals('Submitted', applicant.Application_Status__c);
        System.assertEquals('Eligible', applicant.Eligibility_Status__c);
        System.assertEquals(
            '6568123700',
            applicant.Grant_Applicant_Phone_Key__c
        );

        Integer disbursementCount = [
            SELECT COUNT()
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :response.contactId
        ];

        System.assertEquals(
            3,
            disbursementCount,
            'Option One should create three disbursements.'
        );
    }

    @IsTest
    static void shouldSubmitNotEligibleApplication() {
        Test.startTest();

        GrantApplicationController.ApplicationResponse response =
            GrantApplicationController.submitApplication(
                'Portal',
                'Not Eligible',
                '65 6812 3701',
                '323701',
                2000,
                'Option Three'
            );

        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('Not Eligible', response.eligibilityStatus);

        System.assert(
            response.message.contains('not eligible'),
            'A friendly not eligible message should be returned.'
        );

        Integer disbursementCount = [
            SELECT COUNT()
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :response.contactId
        ];

        System.assertEquals(
            0,
            disbursementCount,
            'A not eligible applicant should not receive disbursements.'
        );
    }

    @IsTest
    static void shouldUpdateExistingApplicantByPhoneKey() {
        GrantApplicationController.ApplicationResponse originalResponse =
            GrantApplicationController.submitApplication(
                'Original',
                'Applicant',
                '65 6812 3702',
                '323702',
                1400,
                'Option One'
            );

        Test.startTest();

        GrantApplicationController.ApplicationResponse updatedResponse =
            GrantApplicationController.submitApplication(
                'Updated',
                'Applicant',
                '65 6812 3702',
                '654321',
                1300,
                'Option Two'
            );

        Test.stopTest();

        System.assertEquals(
            originalResponse.contactId,
            updatedResponse.contactId,
            'The existing Contact should be updated instead of creating a duplicate.'
        );

        Contact updatedApplicant = [
            SELECT
                FirstName,
                MailingPostalCode,
                Monthly_Income__c,
                Support_Option__c
            FROM Contact
            WHERE Id = :updatedResponse.contactId
        ];

        System.assertEquals('Updated', updatedApplicant.FirstName);
        System.assertEquals('654321', updatedApplicant.MailingPostalCode);
        System.assertEquals(1300, updatedApplicant.Monthly_Income__c);
        System.assertEquals('Option Two', updatedApplicant.Support_Option__c);

        Integer contactCount = [
            SELECT COUNT()
            FROM Contact
            WHERE Grant_Applicant_Phone_Key__c = '6568123702'
        ];

        System.assertEquals(
            1,
            contactCount,
            'Only one Contact should exist for the normalized phone number.'
        );

        List<Grant_Disbursement__c> disbursements = [
            SELECT
                Amount_to_be_Disbursed__c,
                Support_Option__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :updatedResponse.contactId
        ];

        System.assertEquals(6, disbursements.size());

        for (Grant_Disbursement__c disbursement : disbursements) {
            System.assertEquals(
                300,
                disbursement.Amount_to_be_Disbursed__c
            );

            System.assertEquals(
                'Option Two',
                disbursement.Support_Option__c
            );
        }
    }

    @IsTest
    static void shouldRejectInvalidPhone() {
        Boolean errorReceived = false;

        Test.startTest();

        try {
            GrantApplicationController.submitApplication(
                'Invalid',
                'Phone',
                '0704084169',
                '323703',
                1500,
                'Option One'
            );
        } catch (AuraHandledException exceptionRecord) {
            errorReceived = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            errorReceived,
            'An invalid phone number should be rejected.'
        );
    }

    @IsTest
    static void shouldRejectInvalidPostalCode() {
        Boolean errorReceived = false;

        Test.startTest();

        try {
            GrantApplicationController.submitApplication(
                'Invalid',
                'Postal Code',
                '65 6812 3704',
                '12345',
                1500,
                'Option One'
            );
        } catch (AuraHandledException exceptionRecord) {
            errorReceived = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            errorReceived,
            'An invalid postal code should be rejected.'
        );
    }

    @IsTest
    static void shouldRejectNegativeIncome() {
        Boolean errorReceived = false;

        Test.startTest();

        try {
            GrantApplicationController.submitApplication(
                'Negative',
                'Income',
                '65 6812 3705',
                '323705',
                -100,
                'Option One'
            );
        } catch (AuraHandledException exceptionRecord) {
            errorReceived = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            errorReceived,
            'Negative monthly income should be rejected.'
        );
    }

    @IsTest
    static void shouldRejectMissingRequiredFields() {
        Boolean errorReceived = false;

        Test.startTest();

        try {
            GrantApplicationController.submitApplication(
                null,
                'Missing First Name',
                '65 6812 3706',
                '323706',
                1500,
                'Option One'
            );
        } catch (AuraHandledException exceptionRecord) {
            errorReceived = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            errorReceived,
            'Missing required fields should be rejected.'
        );
    }

    @IsTest
    static void shouldRejectInactiveOrUnknownSupportOption() {
        Boolean errorReceived = false;

        Test.startTest();

        try {
            GrantApplicationController.submitApplication(
                'Invalid',
                'Support Option',
                '65 6812 3707',
                '323707',
                1500,
                'Unknown Option'
            );
        } catch (AuraHandledException exceptionRecord) {
            errorReceived = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            errorReceived,
            'An unknown support option should be rejected.'
        );
    }
}