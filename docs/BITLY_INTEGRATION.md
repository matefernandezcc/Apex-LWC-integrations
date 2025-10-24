# 🌐 Bitly Integration - Technical Documentation

## Overview

Integración asíncrona con Bitly API para generar URLs cortas de tanques, aplicable **solo a creaciones individuales** (no bulk).

---

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────┐
│                    USER ACTION                             │
│  Create Tank (Single) → TankTrigger fires                 │
└────────────────┬──────────────────────────────────────────┘
                 │
                 ▼
┌───────────────────────────────────────────────────────────┐
│              TANKTRIGGERHANDLER                            │
│  if (Trigger.new.size() == 1) {                           │
│      System.enqueueJob(new BitlyServiceQueueable(id));   │
│  }                                                         │
└────────────────┬──────────────────────────────────────────┘
                 │
                 ▼
┌───────────────────────────────────────────────────────────┐
│          BITLYSERVICEQUEUEABLE (Async)                     │
│                                                            │
│  1. Build long URL:                                        │
│     https://vantegrate.my.salesforce.com/a0A1...          │
│                                                            │
│  2. HTTP Request via Named Credential:                    │
│     POST callout:Bitly_API/v4/shorten                     │
│     Body: {"long_url": "https://..."}                     │
│                                                            │
│  3. Parse response:                                        │
│     {"link": "https://bit.ly/3xYz12A"}                    │
│                                                            │
│  4. Update Tank:                                           │
│     Tank.Bitly_Link__c = shortUrl                         │
└───────────────────────────────────────────────────────────┘
```

---

## 🔑 Named Credential Setup

### Configuration

```
Setup → Named Credentials → New Legacy

┌──────────────────────────────────────────┐
│ Label:            Bitly API              │
│ Name:             Bitly_API              │
│ URL:              https://api-ssl.bitly.com │
│ Identity Type:    Named Principal        │
│ Authentication:   Password Authentication│
│                                          │
│ Username:         bitly                  │
│ Password:         [YOUR_BITLY_TOKEN]     │
│                                          │
│ Generate Auth Header: ✅                 │
│                                          │
│ Custom Headers:                          │
│   Key: Authorization                     │
│   Value: Bearer {!$Credential.Password}  │
└──────────────────────────────────────────┘
```

### Benefits of Named Credentials

| Benefit | Description |
|---------|-------------|
| **Security** | Token no está hardcodeado en código |
| **Flexibility** | Cambiar token sin redeploy |
| **Auditability** | Logs no exponen credenciales |
| **Simplicity** | `callout:Bitly_API` es todo lo que necesitas |

---

## 💻 Code Implementation

### Apex Queueable

```apex
public class BitlyServiceQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id tankId;
    
    public BitlyServiceQueueable(Id tankId) {
        this.tankId = tankId;
    }
    
    public void execute(QueueableContext context) {
        // 1. Build long URL
        String longUrl = System.URL.getOrgDomainUrl().toExternalForm() 
                         + '/' + this.tankId;
        
        // 2. HTTP Request with Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Bitly_API/v4/shorten'); // ← Magic here!
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"long_url": "' + longUrl + '"}');
        
        // 3. Send callout
        HttpResponse res = new Http().send(req);
        
        // 4. Process response
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> result = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String shortUrl = (String)result.get('link');
            
            // 5. Update Tank
            update new Tank__c(Id = this.tankId, Bitly_Link__c = shortUrl);
        }
    }
}
```

---

## 🚦 Governor Limits Protection

### Problem

Salesforce tiene límites de callouts:
- **Synchronous:** 100 callouts por transacción
- **Queueable:** 50 enqueues por transacción

### Solution

**Single Record Detection:**

```apex
protected override void afterInsert() {
    // ✅ Solo ejecuta para 1 registro
    if (Trigger.new.size() == 1) {
        Tank__c newTank = Trigger.new[0];
        System.enqueueJob(new BitlyServiceQueueable(newTank.Id));
    }
    
    // ❌ NO ejecuta para bulk (ej: 200 tanques desde CSV)
}
```

**Escenarios:**

| Scenario | Records | Bitly Integration? | Why? |
|----------|---------|-------------------|------|
| UI creation | 1 | ✅ Yes | Individual insert |
| API single | 1 | ✅ Yes | Individual insert |
| LWC bulk load | 50 | ❌ No | Bulk insert (protects limits) |
| Data Loader | 200 | ❌ No | Bulk insert (protects limits) |

---

## 🧪 Testing

### Mock Callouts

```apex
@isTest
private class BitlyMockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Verify endpoint
        System.assert(req.getEndpoint().contains('bitly'));
        
        // Mock response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"link":"https://bit.ly/test123"}');
        return res;
    }
}

@isTest
static void testBitlyIntegration() {
    Test.setMock(HttpCalloutMock.class, new BitlyMockSuccess());
    
    Tank__c tank = new Tank__c(/* ... */);
    
    Test.startTest();
    insert tank;  // Triggers Bitly integration
    Test.stopTest();
    
    tank = [SELECT Bitly_Link__c FROM Tank__c WHERE Id = :tank.Id];
    System.assertEquals('https://bit.ly/test123', tank.Bitly_Link__c);
}
```

---

## 📊 Monitoring & Debugging

### Debug Logs

1. Setup → Debug Logs
2. New → Select User
3. Debug Level: FINEST
4. Create Tank
5. View logs for:
   - Queueable enqueue
   - HTTP request/response
   - Tank update

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Named Credential not found` | Typo en nombre | Verificar `Bitly_API` exacto |
| `Unauthorized request` | Token inválido | Regenerar token en Bitly |
| `Too many callouts` | Bulk sin protección | Agregar `size() == 1` check |
| `Field not writeable` | FLS | Dar permisos al campo |

---

## 🎯 Best Practices Implemented

- ✅ Async execution (Queueable)
- ✅ Named Credentials (secure tokens)
- ✅ Governor limit protection
- ✅ Error handling
- ✅ Test coverage con mocks
- ✅ Single responsibility principle
- ✅ Proper HTTP method (POST)
- ✅ JSON serialization
- ✅ Database.AllowsCallouts interface

---

## 📚 References

- [Bitly API Docs](https://dev.bitly.com/)
- [Salesforce Named Credentials](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_named_credentials.htm)
- [Queueable Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm)
- [HTTP Callouts](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_http_overview.htm)

