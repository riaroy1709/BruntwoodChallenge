/**
* @File Name : ContactTriggerHandlerTest.cls
* @Description : Test Class for ContactTriggerHandler Class for Contact Object
* @Author : Ria Roy
* @Last Modified By :
* @Last Modified On : May 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 10, 2025 |   | Initial Version
**/

@isTest
private class ContactTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Insert Contacts related to the Account with different positions and years of service
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alice', LastName = 'Admin', AccountId = acc.Id, Position__c = 'Administrative', Years_Of_Service__c = 1),
            new Contact(FirstName = 'Bob', LastName = 'Finance', AccountId = acc.Id, Position__c = 'Finance', Years_Of_Service__c = 5),
            new Contact(FirstName = 'Carol', LastName = 'Ops', AccountId = acc.Id, Position__c = 'Operational Manager', Years_Of_Service__c = 3),
            new Contact(FirstName = 'David', LastName = 'CEO', AccountId = acc.Id, Position__c = 'CEO', Years_Of_Service__c = 2)
        };
        insert contacts;
    }

    @isTest
    static void testUpdateRelatedAccount() {
        // Get test account and related contacts
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = [SELECT Id, FirstName, AccountId, Position__c, Years_Of_Service__c FROM Contact WHERE AccountId = :acc.Id];

        // Prepare old map for simulation
        Map<Id, Contact> oldMap = new Map<Id, Contact>();
        for (Contact con : contacts) {
            oldMap.put(con.Id, con);
        }

        // Simulate update: change position of one contact
        Contact contactToUpdate = contacts[0];
        contactToUpdate.Position__c = 'Finance';
        update contactToUpdate;

        // Query updated contact again
        List<Contact> updatedContacts = [SELECT Id, AccountId, Position__c, Years_Of_Service__c FROM Contact WHERE Id = :contactToUpdate.Id];

        // Call the method under test
        Test.startTest();
        ContactTriggerHandler.updateRelatedAccount(updatedContacts, oldMap);
        Test.stopTest();

        // Validate results on Account
        Account updatedAcc = [
            SELECT Total_Number_Of_Contacts__c, Number_Of_Finance_Employees__c, Main_Contact__c 
            FROM Account 
            WHERE Id = :acc.Id
        ];

        System.assertEquals(4, updatedAcc.Total_Number_Of_Contacts__c, 'Total contacts should be 4');
        System.assertEquals(2, updatedAcc.Number_Of_Finance_Employees__c, 'Finance employees should be 2');
        System.assertNotEquals(null, updatedAcc.Main_Contact__c, 'Main Contact should be populated');
    }

    @isTest
    static void testGetMainContactMethod() {
        // Get contacts for testing getMainContact logic
        List<Contact> contacts = [
            SELECT Id, Position__c, Years_Of_Service__c 
            FROM Contact 
            WHERE Position__c != null
        ];

        Test.startTest();
        Id result = ContactTriggerHandler.getMainContact(contacts);
        Test.stopTest();

        // We know the CEO (David) should be the main contact
        Contact ceo = [SELECT Id FROM Contact WHERE Position__c = 'CEO' LIMIT 1];
        System.assertEquals(ceo.Id, result, 'Main contact should be the CEO');
    }
}