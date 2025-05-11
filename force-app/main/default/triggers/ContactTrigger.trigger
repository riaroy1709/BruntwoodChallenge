/**
* @File Name : ContactTrigger.trigger
* @Description : The trigger automation for Contact Object
* @Author : Ria Roy
* @Last Modified By :
* @Last Modified On : May 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 10, 2025 |   | Initial Version
**/
trigger ContactTrigger on Contact (After Insert, After Update, After Delete, After Undelete) {
    //After Insert
    if(Trigger.isAfter && Trigger.isInsert){
        ContactTriggerHandler.updateRelatedAccount(Trigger.New, null);
    }
    //After Update
    if(Trigger.isAfter && Trigger.isUpdate){
        ContactTriggerHandler.updateRelatedAccount(Trigger.New, Trigger.oldMap);
    }
    //After Delete
    if(Trigger.isAfter && Trigger.isDelete){
        ContactTriggerHandler.updateRelatedAccount(Trigger.Old, null);
    }
    //After Undelete
    if(Trigger.isAfter && Trigger.isUndelete){
       ContactTriggerHandler.updateRelatedAccount(Trigger.New, null);
    }
}