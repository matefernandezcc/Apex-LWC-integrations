@IsTest
private class BitlyIntegrationTest {

    /**
     * @description Mock class to simulate the HTTP callout to Bitly API.
     * Implements HttpCalloutMock interface.
     */
    public class BitlyCalloutMock implements HttpCalloutMock {
        
        /**
         * @description Returns a simulated successful response from Bitly.
         * @param req The HttpRequest being sent.
         * @return HttpResponse The simulated response.
         */
        public HttpResponse respond(HttpRequest req) {
            // 1. Create a fake successful JSON response body (similar to Bitly's)
            String fakeResponseBody = '{' +
                                      '  "created_at": "2025-10-23T21:00:00+0000",' +
                                      '  "id": "bit.ly/FAKE123",' +
                                      '  "link": "https://bit.ly/FAKE123",' + // Link generated
                                      '  "long_url": "some_salesforce_url",' +
                                      '  "archived": false,' +
                                      '  "tags": [],' +
                                      '  "deeplinks": [],' +
                                      '  "references": {}' +
                                      '}';

            // 2. Create a simulated HttpResponse
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(fakeResponseBody);
            res.setStatusCode(201); // 201 (Created)
            res.setStatus('Created');
            
            return res;
        }
    }

    /**
     * @description Creates a sample Tank Type record needed for creating Tanks.
     */
    @TestSetup
    static void makeData(){
        Tank_Type__c testType = new Tank_Type__c(Name = 'Type For Bitly Test', Capacity__c = 50, List_Price__c = 500);
        insert testType;
    }

    /**
     * @description Tests the trigger handler and Queueable callout when a SINGLE tank is inserted.
     * Verifies that the Bitly link field is populated (using the mock response).
     */
    @IsTest
    static void testSingleTankInsert_PopulatesBitlyLink() {
        // Arrange
        // 1. Get the Tank Type created in setup
        Tank_Type__c testType = [SELECT Id FROM Tank_Type__c WHERE Name = 'Type For Bitly Test' LIMIT 1];
        
        // 2. Prepare the single tank record
        Tank__c singleTank = new Tank__c(
            Name = 'Single Tank Test',
            Tank_Type__c = testType.Id,
            Serial_Number__c = 'SN-SINGLE-001',
            Status__c = 'Available'
        );

        // 3. Set the Mock Callout before the action that triggers it
        Test.setMock(HttpCalloutMock.class, new BitlyCalloutMock());

        // Act
        Test.startTest();
            // Insert the single tank (this fires the trigger and enqueues the job)
            insert singleTank;
        Test.stopTest(); // This forces the Queueable job to run synchronously within the test

        // Assert
        // 1. Query the tank again to get the updated value
        Tank__c resultTank = [SELECT Id, Bitly_Link__c FROM Tank__c WHERE Id = :singleTank.Id];
        
        // 2. Verify the Bitly link was populated by the mock response
        System.assertEquals('https://bit.ly/FAKE123', resultTank.Bitly_Link__c, 
            'Bitly Link should be populated after single insert.');
    }

    /**
     * @description Tests the trigger handler logic when MULTIPLE tanks are inserted.
     * Verifies that the Bitly link field remains null (callout is skipped).
     */
    @IsTest
    static void testBulkTankInsert_SkipsBitlyLink() {
        // Arrange
        // 1. Get the Tank Type
        Tank_Type__c testType = [SELECT Id FROM Tank_Type__c WHERE Name = 'Type For Bitly Test' LIMIT 1];
        
        // 2. Prepare a list of tanks (more than 1)
        List<Tank__c> bulkTanks = new List<Tank__c>();
        for(Integer i = 0; i < 5; i++) {
            bulkTanks.add(new Tank__c(
                Name = 'Bulk Tank ' + i,
                Tank_Type__c = testType.Id,
                Serial_Number__c = 'SN-BULK-' + i,
                Status__c = 'Available'
            ));
        }

        // 3. Set the Mock Callout (even though we expect it NOT to be called, it's good practice)
        Test.setMock(HttpCalloutMock.class, new BitlyCalloutMock());

        // Act
        Test.startTest();
            // Insert the list of tanks
            insert bulkTanks;
        Test.stopTest(); // Ensures any async process triggered (like our Queueable, if it ran) finishes

        // Assert
        // 1. Query the inserted tanks
        List<Tank__c> resultTanks = [SELECT Id, Bitly_Link__c FROM Tank__c WHERE Serial_Number__c LIKE 'SN-BULK-%'];
        
        // 2. Verify that the Bitly link is NULL for all of them
        for(Tank__c tank : resultTanks) {
            System.assertEquals(null, tank.Bitly_Link__c, 
                'Bitly Link should remain null for bulk inserts. Failed for ID: ' + tank.Id);
        }
    }
}