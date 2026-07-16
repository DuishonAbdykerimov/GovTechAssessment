/**
 * Narrow persistence helper for public portal submissions.
 *
 * Runs without sharing so an Experience Cloud guest can upsert a Contact
 * that was previously created when matching on Grant_Applicant_Phone_Key__c.
 * With sharing alone the existing row is invisible, upsert becomes insert,
 * and the unique External Id throws DUPLICATE_VALUE.
 */
public without sharing class GrantApplicationPersistenceService {
  public static Contact upsertApplicant(Contact applicant) {
    upsert applicant Contact.Grant_Applicant_Phone_Key__c;
    return applicant;
  }
}
