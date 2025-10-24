/**
 * @description Queueable job to fetch a short URL from Bitly for a new Tank.
 * @author Mateo Fernandez
 */
public class BitlyServiceQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id tankId;

    public BitlyServiceQueueable(Id tankId) {
        this.tankId = tankId;
    }

    public void execute(QueueableContext context) {
        
        // 1. Build the long URL    
        String longUrl = System.URL.getOrgDomainUrl().toExternalForm() + '/' + this.tankId;

        // 2. Create the HttpRequest
        HttpRequest req = new HttpRequest();
        
        // "callout:" + "Named Credential Name" + "/endpoint path"
        // Salesforce replaces this with the base URL (https://api-ssl.bitly.com)
        // and automatically adds the "Authorization" header
        req.setEndpoint('callout:Bitly_API/v4/shorten');
        
        req.setMethod('POST');
        // The Header 'Authorization' is set ONLY.
        req.setHeader('Content-Type', 'application/json');
        
        // 3. Build the JSON Body
        String jsonBody = '{"long_url": "' + longUrl + '", "domain": "bit.ly"}';
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            // 4. Send the call
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String shortUrl = (String)resultMap.get('link');

                // 5. Update the tank
                Tank__c tankToUpdate = new Tank__c(
                    Id = this.tankId,
                    Bitly_Link__c = shortUrl
                );
                update tankToUpdate;
            } else {
                System.debug(LoggingLevel.ERROR, 'Error de Bitly: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en Callout: ' + e.getMessage());
        }
    }
}