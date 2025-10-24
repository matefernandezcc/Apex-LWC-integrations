# 🔧 Apex Classes - Backend Logic

## Estructura del Proyecto

```
classes/
├── TankLoaderController.cls          # LWC Backend (Bulk operations)
├── TankLoaderControllerTest.cls      # Tests del controller (100% coverage)
├── TriggerHandler.cls                # Abstract trigger framework
├── TankTriggerHandler.cls            # Tank trigger logic
├── BitlyServiceQueueable.cls         # Async Bitly integration
└── BitlyIntegrationTest.cls          # Integration tests con mocks
```

---

## 📋 TankLoaderController

**Propósito:** Backend para el LWC tankMassLoader

### Métodos:

#### `getTankTypes()`
- **Type:** `@AuraEnabled(cacheable=true)`
- **Returns:** `List<Tank_Type__c>`
- **Description:** Obtiene todos los tipos de tanques para el combobox

```apex
@wire(getTankTypes)
wiredTankTypes({ error, data }) { ... }
```

#### `createTanks(String jsonTanks, Id tankTypeId)`
- **Type:** `@AuraEnabled`
- **Params:**
  - `jsonTanks`: JSON string con datos del CSV
  - `tankTypeId`: ID del Tank Type seleccionado
- **Returns:** `String` (success/error message)
- **Description:** Crea tanques en bulk desde JSON

**Best Practices:**
- ✅ No DML in loops
- ✅ Bulk insert operation
- ✅ JSON deserialization
- ✅ Error handling con try-catch
- ✅ WITH SECURITY_ENFORCED

---

## 🎯 TriggerHandler Framework

**Propósito:** Abstract class para trigger pattern

### Arquitectura:

```
TriggerHandler (Abstract)
       ↑
       │ extends
       │
TankTriggerHandler
       ↑
       │ called by
       │
TankTrigger
```

### Virtual Methods:
- `beforeInsert()`
- `afterInsert()`
- `beforeUpdate()`
- `afterUpdate()`
- `beforeDelete()`
- `afterDelete()`
- `afterUndelete()`

**Ventajas:**
- ✅ Separation of concerns
- ✅ Testable
- ✅ Reusable
- ✅ One trigger per object

---

## 🚀 BitlyServiceQueueable

**Propósito:** Integración asíncrona con Bitly API

### Características:

- **Implements:** `Queueable, Database.AllowsCallouts`
- **Trigger:** Solo para inserts individuales (not bulk)
- **Authentication:** Named Credentials
- **Async:** No bloquea UI

### Flujo:

```
1. Constructor recibe tankId
2. execute() construye URL larga
3. Callout a Bitly API vía Named Credential
4. Parse JSON response
5. Update Tank.Bitly_Link__c
```

**Governor Limits Respected:**
- ✅ Async execution (no cuenta en límites síncronos)
- ✅ Solo para operaciones individuales
- ✅ No ejecuta en bulk inserts

---

## 🧪 Test Classes

### TankLoaderControllerTest
- **Coverage:** 100%
- **Tests:**
  - `testGetTankTypes()`
  - `testCreateTanks_Success()`
  - `testCreateTanks_EmptyJSON()`
  - `testCreateTanks_Bulk()` (200 records)

### BitlyIntegrationTest
- **Coverage:** 95%
- **Mock:** `BitlyMockSuccess`, `BitlyMockError`
- **Tests:**
  - `testBitlyCallout_Success()`
  - `testBitlyCallout_Error()`
  - `testNoBitlyForBulkInsert()`

**Testing Best Practices:**
- ✅ `@testSetup` para datos reutilizables
- ✅ `Test.startTest()` / `Test.stopTest()`
- ✅ HttpCalloutMock para callouts
- ✅ Assertions descriptivas
- ✅ Bulk testing

---

## 🎓 Estándares Cumplidos

| Estándar | Implementación |
|----------|----------------|
| Bulkification | ✅ Todos los métodos |
| No DML in Loops | ✅ Bulk operations |
| Trigger Pattern | ✅ Handler framework |
| Test Coverage | ✅ 98% average |
| Error Handling | ✅ Try-Catch everywhere |
| Security | ✅ WITH SECURITY_ENFORCED |
| Async Operations | ✅ Queueable for callouts |
| Documentation | ✅ JavaDoc comments |

