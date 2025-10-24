/**
 * @description Apex controller for the tankMassLoader LWC. 
 * Provides methods to get Tank Types and create Tank records in bulk.
 * @author Mateo Fernandez
 * @date 2025-10-23
 */
public with sharing class TankLoaderController {

    /**
     * @description Fetches all Tank_Type__c records to populate the LWC combobox.
     * @return List<Tank_Type__c> A list of tank types.
     */
    @AuraEnabled(cacheable=true)
    public static List<Tank_Type__c> getTankTypes() {
        try {
            // Query with FLS check and ordering
            return [
                SELECT Id, Name 
                FROM Tank_Type__c 
                WITH SECURITY_ENFORCED
                ORDER BY Name
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Receives a JSON string of Tank records from the LWC, 
     * deserializes them, assigns the correct Tank Type, and inserts them in bulk.
     * @param jsonTanks A JSON string representing a list of tanks from the CSV.
     * @param tankTypeId The Id of the Tank_Type__c to assign to all new tanks.
     * @return String with success or error message.
     */
    @AuraEnabled
    public static String createTanks(String jsonTanks, Id tankTypeId) {
        // Deserialize the JSON string into a generic list of objects
        // We can't deserialize directly to List<Tank__c> because the CSV 
        // won't have the API names exactly.
        List<Object> csvRows = (List<Object>) JSON.deserializeUntyped(jsonTanks);
        
        List<Tank__c> tanksToInsert = new List<Tank__c>();

        try {
            // Loop 1: Prepare the list in memory
            // This is NOT a "DML in loop", it's a data processing loop.
            for(Object row : csvRows) {
                Map<String, Object> rowMap = (Map<String, Object>) row;
                
                Tank__c newTank = new Tank__c();
                
                // --- Field Mapping ---
                // Assign the selected Tank Type
                newTank.Tank_Type__c = tankTypeId; 
                
                // Map the fields from the CSV (e.g. 'Serial Number') 
                // to the Salesforce field ('Serial_Number__c')
                // IMPORTANT! The 'Serial Number' MUST match 
                // with the header of your CSV file.

                // Serial Number Mapping (required)
                if(rowMap.containsKey('Serial Number')) {
                    newTank.Serial_Number__c = (String)rowMap.get('Serial Number');
                }
                
                // Tank Name Mapping (required)
                if(rowMap.containsKey('Name')) {
                    newTank.Name = (String)rowMap.get('Name');
                }

                // (Add any other field that comes in the CSV here)
                
                // Set the default status
                newTank.Status__c = 'Available'; 
                
                tanksToInsert.add(newTank);
            }

            // Loop 2: Insert the list (bulk)
            if (!tanksToInsert.isEmpty()) {
                insert tanksToInsert;
                return 'Success: Created ' + tanksToInsert.size() + ' new tanks.';
            } else {
                return 'No tanks to create. Check your CSV file.';
            }

        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}