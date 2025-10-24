/**
 * @description Trigger on Tank__c object. 
 * Delegates all logic to the handler class.
 * @author Mateo Fernandez
 * @date 2025-10-23
 */
trigger TankTrigger on Tank__c (after insert) {
    new TankTriggerHandler().run();
}