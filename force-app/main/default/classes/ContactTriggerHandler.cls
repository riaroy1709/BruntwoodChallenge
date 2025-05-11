/**
* @File Name : ContactTriggerHandler.cls
* @Description : Trigger Handler Class for Contact Object
* @Author : Ria Roy
* @Last Modified By :
* @Last Modified On : May 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 10, 2025 |   | Initial Version
**/

public with sharing class ContactTriggerHandler {
    /**
     * @Description : This method is used to update the related account
     * @param newContactList : List of new Contact records or Old Contact records which are deleted
     * @param oldContactMap : Map of old Contact records
     */
    public static void updateRelatedAccount(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        Set<Id> accountIds = new Set<Id>();

        // Collect all the AccountIds that are related to Contacts on Insert, Delete or Undelete
        // If oldContactMap is null, it means this is an insert or Delete or undelete operation
        if(oldContactMap == null){
            for(Contact con : newContactList){
                if (con.AccountId != null) {
                    accountIds.add(con.AccountId);
                }
            }
        }
        // If oldContactMap is not null, it means this is an update operation
        else{
            for (Contact con : newContactList) {
            // Check if the AccountId or Position or Years of Service has changed for the contact and 
                if (con.AccountId != null &&
                        (oldContactMap.get(con.Id).AccountId != con.AccountId ||
                        oldContactMap.get(con.Id).Position__c != con.Position__c) ||
                        (oldContactMap.get(con.Id).Years_Of_Service__c != con.Years_Of_Service__c)) {
                    // Add the AccountId to the set if there is a change
                    accountIds.add(con.AccountId);
                }
            }
        }
        
        // If there are any account IDs to process, query the related accounts
        if (!accountIds.isEmpty()) {
            
            // Query the related accounts and their contacts Using a subquery 
            List<Account> relatedAccounts = [
                SELECT Id, Total_Number_Of_Contacts__c, Number_Of_Finance_Employees__c, Main_Contact__c, 
                       (SELECT Id, Position__c, Years_Of_Service__c FROM Contacts)  
                FROM Account
                WHERE Id IN :accountIds
            ];
            
            // Create a list to hold the accounts to be updated
            List<Account> accountsToUpdate = new List<Account>();
            
            // Iterate through each related account and update the fields
            for (Account acc : relatedAccounts) {
                Integer totalContacts = acc.Contacts.size();
                List<Contact> financeContacts = new List<Contact>();
                List<Contact> relatedContacts = acc.Contacts;

                // Filter finance employees
                for (Contact con : acc.Contacts) {
                    if (con.Position__c == 'Finance') {
                        financeContacts.add(con);
                    }
                }

                // Set Main Contact based on rank and service years
                if (relatedContacts.size() > 0) {
                    acc.Main_Contact__c = getMainContact(relatedContacts);
                }
                
                // Update the account fields
                acc.Total_Number_Of_Contacts__c = totalContacts;
                acc.Number_Of_Finance_Employees__c = financeContacts.size();
                accountsToUpdate.add(acc);
            }
            
            // Update the accounts in bulk
            if (!accountsToUpdate.isEmpty()) {
                try {
                    update accountsToUpdate;
                } catch (DmlException e) {
                    // Handle any exceptions that occur during the update
                    System.debug('Error updating accounts: ' + e.getMessage());
                }
            }
        }
    }

    /**
     * @Description : This method returns the main contact from the list of contacts
     * @param relatedContacts : List of Contacts related to an Account
     * @return : Contact Id of the Main Contact
    */
    public static Id getMainContact(List<Contact> relatedContacts) {
        // Defined a map to rank positions
        // Note: These mappings can also be stored in the Custom Metadata which can give us the freedom to configure them in the future without need of Deployment
        Map<String, Integer> positionRank = new Map<String, Integer> {
            'CEO' => 4,
            'Operational Manager' => 3,
            'Finance' => 2,
            'Administrative' => 1
        };
        // Initialize variables to track the main contact
        Id mainContactId = null;
        Integer highestRank = 0;
        Integer highestYearsOfService = -1;

        // Iterate through the related contacts to find the main contact
        for (Contact con : relatedContacts) {
            // Check if the contact has a valid position and rank
            if (con.Position__c != null && positionRank.containsKey(con.Position__c)) {
                Integer rank = positionRank.get(con.Position__c);
                Integer yearsOfService = con.Years_Of_Service__c != null ? con.Years_Of_Service__c.intValue() : 0;

                // Determine the main contact based on rank and seniority (years of service)
                if (rank > highestRank || (rank == highestRank && yearsOfService > highestYearsOfService)) {
                    highestRank = rank;
                    highestYearsOfService = yearsOfService;
                    mainContactId = con.Id;
                }
            }
        }
        return mainContactId;
    }
}