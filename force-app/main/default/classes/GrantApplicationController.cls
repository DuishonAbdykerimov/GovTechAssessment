public with sharing class GrantApplicationController {

    @AuraEnabled(cacheable=true)
    public static List<SupportOptionResponse> getSupportOptions() {
        List<SupportOptionResponse> results =
            new List<SupportOptionResponse>();

        for (Support_Option__mdt optionRecord : [
            SELECT
                MasterLabel,
                Monthly_Amount__c,
                Duration_Months__c,
                Display_Order__c
            FROM Support_Option__mdt
            WHERE Active__c = true
            ORDER BY Display_Order__c ASC
        ]) {
            results.add(
                new SupportOptionResponse(
                    optionRecord.MasterLabel,
                    optionRecord.Monthly_Amount__c,
                    Integer.valueOf(optionRecord.Duration_Months__c)
                )
            );
        }

        return results;
    }

    @AuraEnabled
    public static ApplicationResponse submitApplication(
        String firstName,
        String lastName,
        String phone,
        String postalCode,
        Decimal monthlyIncome,
        String supportOption
    ) {
        validateInput(
            firstName,
            lastName,
            phone,
            postalCode,
            monthlyIncome,
            supportOption
        );

        String normalizedPhone = phone.replaceAll('[^0-9]', '');

        Contact applicant = new Contact(
            FirstName = firstName.trim(),
            LastName = lastName.trim(),
            Phone = phone.trim(),
            MailingPostalCode = postalCode.trim(),
            Monthly_Income__c = monthlyIncome,
            Support_Option__c = supportOption,
            Application_Status__c = 'Submitted',
            Grant_Applicant_Phone_Key__c = normalizedPhone
        );

        try {
            upsert applicant Grant_Applicant_Phone_Key__c;

            Contact savedApplicant = [
                SELECT
                    Id,
                    Name,
                    Eligibility_Status__c,
                    Application_Submission_Date__c,
                    Support_Option__c
                FROM Contact
                WHERE Id = :applicant.Id
                LIMIT 1
            ];

            String message;

            if (savedApplicant.Eligibility_Status__c == 'Eligible') {
                message =
                    'Your application has been submitted successfully. ' +
                    'You are eligible for financial support.';
            } else {
                message =
                    'Your application has been submitted successfully. ' +
                    'You are currently not eligible for financial support.';
            }

            return new ApplicationResponse(
                true,
                savedApplicant.Id,
                savedApplicant.Eligibility_Status__c,
                message
            );

        } catch (DmlException exceptionRecord) {
            throw new AuraHandledException(
                getFriendlyDmlMessage(exceptionRecord)
            );
        }
    }

    private static void validateInput(
        String firstName,
        String lastName,
        String phone,
        String postalCode,
        Decimal monthlyIncome,
        String supportOption
    ) {
        if (
            String.isBlank(firstName) ||
            String.isBlank(lastName) ||
            String.isBlank(phone) ||
            String.isBlank(postalCode) ||
            monthlyIncome == null ||
            String.isBlank(supportOption)
        ) {
            throw new AuraHandledException(
                'Complete all required application fields.'
            );
        }

        if (!Pattern.matches('^65 [0-9]{4} [0-9]{4}$', phone.trim())) {
            throw new AuraHandledException(
                'Enter a valid Singapore phone number in the format 65 6812 3456.'
            );
        }

        if (!Pattern.matches('^[0-9]{6}$', postalCode.trim())) {
            throw new AuraHandledException(
                'Enter a valid 6-digit Singapore postal code.'
            );
        }

        if (monthlyIncome < 0) {
            throw new AuraHandledException(
                'Monthly income cannot be negative.'
            );
        }

        List<Support_Option__mdt> selectedOptions = [
            SELECT Id
            FROM Support_Option__mdt
            WHERE MasterLabel = :supportOption
            AND Active__c = true
            LIMIT 1
        ];

        if (selectedOptions.isEmpty()) {
            throw new AuraHandledException(
                'Select a valid active support option.'
            );
        }
    }

    private static String getFriendlyDmlMessage(DmlException exceptionRecord) {
        return exceptionRecord.getDmlMessage(0);
    }

    public class SupportOptionResponse {
        @AuraEnabled
        public String label;

        @AuraEnabled
        public String value;

        @AuraEnabled
        public Decimal monthlyAmount;

        @AuraEnabled
        public Integer durationMonths;

        public SupportOptionResponse(
            String optionLabel,
            Decimal amount,
            Integer months
        ) {
            label = optionLabel;
            value = optionLabel;
            monthlyAmount = amount;
            durationMonths = months;
        }
    }

    public class ApplicationResponse {
        @AuraEnabled
        public Boolean success;

        @AuraEnabled
        public Id contactId;

        @AuraEnabled
        public String eligibilityStatus;

        @AuraEnabled
        public String message;

        public ApplicationResponse(
            Boolean wasSuccessful,
            Id applicantId,
            String status,
            String responseMessage
        ) {
            success = wasSuccessful;
            contactId = applicantId;
            eligibilityStatus = status;
            message = responseMessage;
        }
    }
}