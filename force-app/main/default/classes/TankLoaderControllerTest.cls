@IsTest
private class TankLoaderControllerTest {

    /**
     * @description Creates sample Tank Type records for testing.
     */
    @TestSetup
    static void makeData(){
        List<Tank_Type__c> testTypes = new List<Tank_Type__c>{
            new Tank_Type__c(Name = 'Test Type A', Capacity__c = 100, List_Price__c = 1000),
            new Tank_Type__c(Name = 'Test Type B', Capacity__c = 200, List_Price__c = 2000)
        };
        insert testTypes;
    }

    /**
     * @description Tests the getTankTypes method. 
     * Verifies it returns the correct list of Tank Types.
     */
    @IsTest
    static void testGetTankTypes_ReturnsTypes() {

        // Act
        Test.startTest();
        List<Tank_Type__c> result = TankLoaderController.getTankTypes();
        Test.stopTest();

        // Assert (Verify the results)
        // Check that it returned the 2 types we created in setup
        System.assertEquals(2, result.size(), 'Should have returned 2 Tank Types.'); 

        // Check that the names match
        System.assertEquals('Test Type A', result[0].Name, 'First type name should match.');
    }

    /**
     * @description Tests the createTanks method with valid JSON data.
     * Verifies that tanks are created correctly.
     */
    @IsTest
    static void testCreateTanks_WithValidJson_CreatesTanks() {
        // Arrange
        // 1. Get the ID of one of the Tank Types created in @TestSetup
        Tank_Type__c testType = [SELECT Id FROM Tank_Type__c WHERE Name = 'Test Type A' LIMIT 1];
        
        // 2. Simulate the JSON string that the LWC would send (like from PapaParse)
        // IMPORTANT: The keys ('Name', 'Serial Number') MUST match the Apex code's expectations
        String validJson = '[' +
                           '  {"Name": "Tank From CSV 1", "Serial Number": "CSV-SN-001"},' +
                           '  {"Name": "Tank From CSV 2", "Serial Number": "CSV-SN-002"}' +
                           ']';

        // Act
        Test.startTest();
        // Call the method being tested
        String resultMessage = TankLoaderController.createTanks(validJson, testType.Id);
        Test.stopTest();

        // Assert (Verify the results)
        // 1. Check the success message returned by the method
        System.assert(resultMessage.startsWith('Success'), 'Result message should indicate success.');
        
        // 2. Query the database to verify the tanks were actually created
        List<Tank__c> createdTanks = [
            SELECT Id, Name, Serial_Number__c, Status__c, Tank_Type__c 
            FROM Tank__c 
            WHERE Serial_Number__c LIKE 'CSV-SN-%' // Filter for the tanks created in this test
        ];
        
        // Verify that 2 tanks were created
        System.assertEquals(2, createdTanks.size(), 'Should have created 2 tanks.');

        // Verify fields on one of the created tanks
        System.assertEquals('Tank From CSV 1', createdTanks[0].Name, 'First tank name should match CSV.');
        System.assertEquals('Available', createdTanks[0].Status__c, 'Status should default to Available.');
        System.assertEquals(testType.Id, createdTanks[0].Tank_Type__c, 'Tank Type ID should match the one passed.');
    }

    /**
     * @description Tests the createTanks method with invalid JSON data.
     * Verifies that the method return a 'No tanks to create' message.
     */
    @IsTest
    static void testCreateTanks_WithEmptyJson_ReturnsError() {
        // 1. Get the ID of one of the Tank Types created in @TestSetup
        Tank_Type__c testType = [SELECT Id FROM Tank_Type__c WHERE Name = 'Test Type A' LIMIT 1];
        
        // 2. Simulate an empty JSON string
        String invalidJson = '[]';

        // Act
        Test.startTest();
        String resultMessage = TankLoaderController.createTanks(invalidJson, testType.Id);
        Test.stopTest();

        // Assert (Verify the results)
        // Check the error message returned by the method
        System.assert(resultMessage.startsWith('No tanks'), 'Result message should indicate No tanks to create.');
    }

    // 2. testCreateTanks_WithMissingRequiredField_ReturnsError() (e.g., JSON without 'Name')
}