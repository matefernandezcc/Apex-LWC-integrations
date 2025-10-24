# 🏗️ System Architecture

## High-Level Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     SALESFORCE ORG                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐      ┌──────────────┐      ┌────────────┐ │
│  │   SALES     │      │    TANK      │      │  EXTERNAL  │ │
│  │   PROCESS   │      │  MANAGEMENT  │      │   APIs     │ │
│  └─────────────┘      └──────────────┘      └────────────┘ │
│         │                     │                     │        │
│         ▼                     ▼                     ▼        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              DECLARATIVE LAYER                        │  │
│  │  - Flows (Lead Conversion)                           │  │
│  │  - Process Builder (Tank Status)                     │  │
│  │  - Validation Rules (XOR constraint)                 │  │
│  │  - Formula Fields (Serial Number display)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              PROGRAMMATIC LAYER                       │  │
│  │                                                       │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐ │  │
│  │  │    LWC     │  │    APEX     │  │  TRIGGERS    │ │  │
│  │  │            │  │             │  │              │ │  │
│  │  │ tankMass   │  │ Tank        │  │ Tank         │ │  │
│  │  │ Loader     │  │ Loader      │  │ Trigger      │ │  │
│  │  │            │  │ Controller  │  │              │ │  │
│  │  └────────────┘  └─────────────┘  └──────────────┘ │  │
│  │        │                │                 │          │  │
│  │        └────────────────┼─────────────────┘          │  │
│  │                         │                            │  │
│  │                         ▼                            │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │         ASYNC PROCESSING                      │  │  │
│  │  │  - BitlyServiceQueueable                     │  │  │
│  │  │  - HTTP Callouts                             │  │  │
│  │  │  - Named Credentials                         │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              DATA LAYER                               │  │
│  │  - Tank__c                                           │  │
│  │  - Tank_Type__c                                      │  │
│  │  - Order__c                                          │  │
│  │  - Lead (extended)                                   │  │
│  │  - Opportunity (extended)                            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │   BITLY API  │
                  └──────────────┘
```

---

## Component Interaction Diagram

### Sales Process Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │ Creates Lead
     ▼
┌─────────────────────────────┐
│         Lead Object          │
│ - Min_Price__c              │
│ - Max_Price__c              │
│ - Desired_Capacity__c       │
└────────┬────────────────────┘
         │ Convert
         ▼
┌─────────────────────────────┐
│     Flow: Lead to Opp       │
│  with Tank Match            │
└────────┬────────────────────┘
         │
         ├─ Tank found? ──────┐
         │                    │
       YES                   NO
         │                    │
         ▼                    ▼
┌──────────────┐    ┌──────────────┐
│ Opportunity  │    │ Opportunity  │
│ + Tank__c    │    │ + Order__c   │
└──────────────┘    └──────────────┘
```

### Tank Creation Flow

```
┌─────────────────────────────────────┐
│  User opens tankMassLoader LWC      │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  Step 1: Select Tank Type           │
│  (@wire getTankTypes)               │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  Step 2: Upload CSV file            │
│  (PapaParse parses client-side)     │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  Step 3: Click Process              │
│  (Sends JSON to Apex)               │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  TankLoaderController.createTanks() │
│  - Deserialize JSON                 │
│  - Build Tank__c objects            │
│  - Bulk insert (NO DML in loop)     │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  TankTrigger fires                  │
│  - if (size == 1) → Bitly           │
│  - if (size > 1) → Skip Bitly       │
└─────────┬───────────────────────────┘
          │
          ▼ (if single)
┌─────────────────────────────────────┐
│  BitlyServiceQueueable (Async)      │
│  - Build URL                        │
│  - Call Bitly API                   │
│  - Update Tank.Bitly_Link__c        │
└─────────────────────────────────────┘
```

---

## Technology Stack

### Frontend Layer
- **Lightning Web Components (LWC)**
  - Modern JavaScript (ES6+)
  - Shadow DOM
  - Lightning Design System (SLDS)
  - PapaParse library (CSV parsing)

### Backend Layer
- **Apex**
  - Controllers (`@AuraEnabled`)
  - Triggers (Bulkified)
  - Queueable Jobs (Async)
  - Test Classes (98% coverage)

### Declarative Layer
- **Flow Builder**
  - Lead conversion automation
  - Tank matching logic
  - Order creation
  
- **Process Builder**
  - Tank status updates
  
- **Validation Rules**
  - XOR constraint (Tank vs Order)
  
- **Formula Fields**
  - Cross-object references

### Integration Layer
- **Named Credentials**
  - Secure token storage
  - Bitly API authentication
  
- **HTTP Callouts**
  - RESTful API calls
  - JSON serialization

---

## Data Model

### Entity Relationship Diagram

```
Tank_Type__c (1) ────────── (N) Tank__c
      │                           │
      │                           │
      │                      (1)  │
      │                           │
      └───── (N) Order__c ────────┴──── (N) Opportunity
                    │                          │
                    └──────── (XOR) ───────────┘
                           (only one)

Lead ──[Conversion]──> Account + Contact + Opportunity
```

### Key Objects

1. **Tank_Type__c** (Master)
   - Tank categories
   - Reusable across multiple tanks

2. **Tank__c** (Detail)
   - Individual tank instances
   - Status: Available/Reserved/Sold
   - Links to Opportunities

3. **Order__c** (Custom Request)
   - When no Tank matches
   - Captures desired specifications
   - Links to Opportunities

4. **Opportunity** (Extended)
   - Either Tank OR Order (XOR)
   - Validation rule enforces constraint

---

## Security Architecture

### Permission Sets

```
┌──────────────┐         ┌──────────────┐
│  Sales User  │         │ Tank Manager │
└──────┬───────┘         └──────┬───────┘
       │                        │
       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│ Can:            │     │ Can:            │
│ - Lead CRUD     │     │ - Tank CRUD     │
│ - Opp CRUD      │     │ - Tank_Type CRUD│
│ - Account CRUD  │     │ - Order Read    │
│                 │     │                 │
│ Cannot:         │     │ Cannot:         │
│ - Tank Edit     │     │ - Lead access   │
│ - Tank_Type Edit│     │ - Opp access    │
└─────────────────┘     └─────────────────┘
```

### Field-Level Security
- FLS enforced via `WITH SECURITY_ENFORCED`
- Permission Sets control field access
- Sharing Rules for record-level access

---

## Integration Points

### External Systems

| System | Protocol | Authentication | Purpose |
|--------|----------|----------------|---------|
| Bitly | HTTPS REST | Named Credential | Short URL generation |
| (Future) Analytics | REST | OAuth 2.0 | Reporting dashboards |
| (Future) ERP | SOAP | Basic Auth | Inventory sync |

---

## Scalability Considerations

### Performance Optimization

1. **Bulk Operations**
   - All Apex methods support bulk (200+ records)
   - No DML in loops
   - Efficient SOQL queries

2. **Async Processing**
   - Queueable for callouts
   - Future methods for long operations
   - Batch Apex for large data volumes

3. **Caching**
   - `@AuraEnabled(cacheable=true)` for LWC
   - Platform Cache for frequently accessed data

### Governor Limits Protection

- Single-record detection for callouts
- Bulk insert pattern throughout
- Test coverage for 200+ record scenarios

---

## Monitoring & Logging

### Debug Strategy

1. **Debug Logs**
   - Setup → Debug Logs
   - User trace flags
   - Apex execution analysis

2. **System.debug() Statements**
   - LoggingLevel.ERROR for exceptions
   - Key decision points logged

3. **Event Monitoring**
   - Track API usage
   - Monitor performance
   - Identify bottlenecks

---

## Deployment Strategy

### Source-Driven Development

```bash
# Local development
sf project deploy start --source-dir force-app

# Sandbox deployment
sf project deploy start --target-org sandbox

# Production deployment
sf project deploy start --target-org production --test-level RunLocalTests
```

### CI/CD Pipeline (Future)

```
GitHub → Jenkins → Validate → Deploy to Sandbox → Run Tests → Deploy to Prod
```

---

## Future Enhancements

- [ ] Einstein Analytics dashboards
- [ ] Mobile app with Salesforce Mobile SDK
- [ ] Scheduled batch for Tank maintenance
- [ ] Email notifications with Email Templates
- [ ] Chatter integration for collaboration
- [ ] Custom Lightning App for Tank Managers

---

## References

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Lightning Web Components Dev Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)

