@IsTest
private class GrantApplicationServiceTest {

    @IsTest
    static void ordinaryContactShouldNotTriggerGrantLogic() {
        Contact contactRecord = new Contact(
            FirstName = 'Ordinary',
            LastName = 'Contact',
            Phone = '0704084169'
        );

        Test.startTest();
        insert contactRecord;
        Test.stopTest();

        Contact savedContact = [
            SELECT
                Eligibility_Status__c,
                Application_Submission_Date__c,
                Grant_Applicant_Phone_Key__c
            FROM Contact
            WHERE Id = :contactRecord.Id
        ];

        System.assertEquals(
            null,
            savedContact.Eligibility_Status__c,
            'Ordinary Contact should not receive an eligibility status.'
        );

        System.assertEquals(
            null,
            savedContact.Application_Submission_Date__c,
            'Ordinary Contact should not receive a submission date.'
        );

        System.assertEquals(
    null,
    savedContact.Grant_Applicant_Phone_Key__c,
    'Ordinary Contacts should not receive a grant applicant phone key.'

        );
    }

    @IsTest
    static void eligibleApplicantShouldBePrepared() {
        Contact applicant = createApplicant(
            'Eligible',
            'Applicant',
            '65 6812 3500',
            '123500',
            1500,
            'Option One'
        );

        Test.startTest();
        insert applicant;
        Test.stopTest();

        Contact savedApplicant = [
            SELECT
                Eligibility_Status__c,
                Application_Submission_Date__c,
                Grant_Applicant_Phone_Key__c
            FROM Contact
            WHERE Id = :applicant.Id
        ];

        System.assertEquals(
            'Eligible',
            savedApplicant.Eligibility_Status__c
        );

        System.assertEquals(
            Date.today(),
            savedApplicant.Application_Submission_Date__c
        );

        System.assertEquals(
            '6568123500',
            savedApplicant.Grant_Applicant_Phone_Key__c
        );
    }

    @IsTest
    static void applicantAtIncomeLimitShouldBeNotEligible() {
        Contact applicant = createApplicant(
            'Not',
            'Eligible',
            '65 6812 3501',
            '123501',
            2000,
            'Option Two'
        );

        Test.startTest();
        insert applicant;
        Test.stopTest();

        Contact savedApplicant = [
            SELECT Eligibility_Status__c
            FROM Contact
            WHERE Id = :applicant.Id
        ];

        System.assertEquals(
            'Not Eligible',
            savedApplicant.Eligibility_Status__c
        );

        Integer disbursementCount = [
            SELECT COUNT()
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c = :applicant.Id
        ];

        System.assertEquals(
            0,
            disbursementCount,
            'A not eligible applicant must not receive disbursements.'
        );
    }

    @IsTest
    static void bulkApplicantsShouldBeProcessed() {
        List<Contact> applicants = new List<Contact>{
            createApplicant(
                'Bulk',
                'Applicant One',
                '65 6812 3502',
                '123502',
                1000,
                'Option One'
            ),
            createApplicant(
                'Bulk',
                'Applicant Two',
                '65 6812 3503',
                '123503',
                1500,
                'Option Two'
            ),
            createApplicant(
                'Bulk',
                'Applicant Three',
                '65 6812 3504',
                '123504',
                2500,
                'Option Three'
            )
        };

        Test.startTest();
        insert applicants;
        Test.stopTest();

        Map<String, Contact> applicantsByPhone =
            new Map<String, Contact>();

        for (Contact applicant : [
            SELECT
                Phone,
                Eligibility_Status__c,
                Grant_Applicant_Phone_Key__c
            FROM Contact
            WHERE Id IN :applicants
        ]) {
            applicantsByPhone.put(applicant.Phone, applicant);
        }

        System.assertEquals(
            'Eligible',
            applicantsByPhone
                .get('65 6812 3502')
                .Eligibility_Status__c
        );

        System.assertEquals(
            'Eligible',
            applicantsByPhone
                .get('65 6812 3503')
                .Eligibility_Status__c
        );

        System.assertEquals(
            'Not Eligible',
            applicantsByPhone
                .get('65 6812 3504')
                .Eligibility_Status__c
        );

        Integer totalDisbursements = [
            SELECT COUNT()
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c IN :applicants
        ];

        System.assertEquals(
            9,
            totalDisbursements,
            'Option One should create 3 and Option Two should create 6 records.'
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