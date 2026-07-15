public with sharing class GrantApplicationService {

    private static final Decimal ELIGIBILITY_INCOME_LIMIT = 2000;

    public static void prepareApplications(
        List<Contact> newContacts,
        Map<Id, Contact> oldMap
    ) {
        for (Contact applicant : newContacts) {

            // Ignore ordinary Contacts that are not grant applications.
            if (String.isBlank(applicant.Application_Status__c)) {
                continue;
            }

            System.debug('applicant: ' + applicant);    
            // Preserve the original application submission date.
            if (applicant.Application_Submission_Date__c == null) {
                applicant.Application_Submission_Date__c = Date.today();
            }

            if (String.isNotBlank(applicant.Phone)) {
            applicant.Grant_Applicant_Phone_Key__c =
            applicant.Phone.replaceAll('[^0-9]', '');
            }
            
            // Determine eligibility based on monthly income.
            if (applicant.Monthly_Income__c == null) {
                applicant.Eligibility_Status__c = 'Pending';
            } else if (applicant.Monthly_Income__c < ELIGIBILITY_INCOME_LIMIT) {
                applicant.Eligibility_Status__c = 'Eligible';
            } else {
                applicant.Eligibility_Status__c = 'Not Eligible';
            }
        }
    }
}