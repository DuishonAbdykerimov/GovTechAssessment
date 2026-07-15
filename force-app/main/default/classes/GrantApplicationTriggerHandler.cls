public with sharing class GrantApplicationTriggerHandler {

    public static void handle() {
        List<Contact> newContacts = (List<Contact>) Trigger.new;
        Map<Id, Contact> oldMap = Trigger.oldMap == null
            ? null
            : (Map<Id, Contact>) Trigger.oldMap;

        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            GrantApplicationService.prepareApplications(newContacts, oldMap);
        }

        if (Trigger.isBefore && Trigger.isUpdate) {
            GrantDisbursementService.validateSupportOptionChanges(
                newContacts,
                oldMap
            );
        }

        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            GrantDisbursementService.processApplications(newContacts, oldMap);
        }
    }
}
