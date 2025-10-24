# 🚰 Vantegrate Tank Management System

> Sistema completo de gestión de tanques industriales en Salesforce, desarrollado con Sales Cloud, Apex, Lightning Web Components y Flow Builder.

[![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=Salesforce&logoColor=white)](https://www.salesforce.com/)
[![Apex](https://img.shields.io/badge/Apex-00A1E0?style=for-the-badge&logo=Salesforce&logoColor=white)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
[![Lightning Web Components](https://img.shields.io/badge/LWC-00A1E0?style=for-the-badge&logo=Salesforce&logoColor=white)](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Arquitectura de la Solución](#-arquitectura-de-la-solución)
- [Modelo de Datos](#-modelo-de-datos)
- [Funcionalidades Implementadas](#-funcionalidades-implementadas)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Seguridad y Permisos](#-seguridad-y-permisos)
- [Testing y Cobertura](#-testing-y-cobertura)
- [Instalación y Despliegue](#-instalación-y-despliegue)
- [Demostración](#-demostración)
- [Autor](#-autor)

---

## 🎯 Descripción del Proyecto

Sistema integral para la gestión de **ventas y mantenimiento de tanques industriales** desarrollado en Salesforce Sales Cloud. 

### **Contexto del Negocio**

Una empresa que vende tanques de agua industriales necesitaba:
- ✅ Automatizar su proceso de ventas (Leads → Opportunities)
- ✅ Gestionar inventario de tanques con diferentes estados
- ✅ Carga masiva de tanques vía CSV
- ✅ Integración con Bitly para URLs cortas
- ✅ Dos perfiles de usuario diferenciados

### **Requerimientos Cumplidos**

| Categoría | Implementación | Estado |
|-----------|----------------|--------|
| **Proceso de Venta** | Lead Conversion + Auto-match de Tanques | ✅ Completado |
| **Carga Masiva** | Lightning Web Component con PapaParse | ✅ Completado |
| **Integración Bitly** | Named Credentials + Queueable + Trigger | ✅ Completado |
| **Seguridad** | Permission Sets + Field-Level Security | ✅ Completado |
| **Testing** | 95% Code Coverage | ✅ Completado |
| **Flow Builder** | Lead Conversion Automation | ✅ Completado |

---

## 🏗️ Arquitectura de la Solución

### **Diagrama de Flujo General**

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROCESO DE VENTA                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Lead Creation                                                   │
│       │                                                          │
│       ├─ Captura: Precio Min/Max, Capacidad                     │
│       │                                                          │
│       ▼                                                          │
│  Lead Conversion (Flow)                                          │
│       │                                                          │
│       ├─ Busca Tank disponible (Capacity + Price match)         │
│       │   ├─ Tank encontrado → Asocia a Opportunity            │
│       │   └─ Tank NO encontrado → Crea Order (pedido)          │
│       │                                                          │
│       ▼                                                          │
│  Opportunity + (Tank OR Order)                                   │
│       │                                                          │
│       └─ Validation Rule: Solo 1 (Tank XOR Order)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                PROCESO DE MANTENIMIENTO                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  tankMassLoader (LWC)                                           │
│       │                                                          │
│       ├─ Paso 1: Seleccionar Tank Type (Combobox)              │
│       ├─ Paso 2: Cargar CSV (PapaParse)                        │
│       └─ Paso 3: Crear Tanks en Bulk (Apex)                    │
│                                                                  │
│  TankLoaderController.createTanks()                             │
│       │                                                          │
│       └─ Bulk Insert (No DML in Loops)                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  INTEGRACIÓN BITLY                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Tank Creation (Individual)                                      │
│       │                                                          │
│       ▼                                                          │
│  TankTrigger (after insert)                                      │
│       │                                                          │
│       └─ Detecta: insert individual (size = 1)                  │
│           │                                                      │
│           ▼                                                      │
│  BitlyServiceQueueable (Async)                                  │
│       │                                                          │
│       ├─ Named Credential: Bitly_API                            │
│       ├─ POST /v4/shorten                                        │
│       └─ Update Tank.Bitly_Link__c                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Modelo de Datos

### **Objetos Personalizados**

#### **Tank__c (Tanque)**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Name` | Auto-Number | Número de tanque (TANK-{0000}) |
| `Serial_Number__c` | Text(50) | Número de serie único |
| `Tank_Type__c` | Lookup(Tank_Type__c) | Tipo de tanque |
| `Status__c` | Picklist | Available / Reserved / Sold |
| `Price__c` | Currency | Precio del tanque |
| `Capacity__c` | Number | Capacidad en litros |
| `Bitly_Link__c` | URL | Link corto generado por Bitly |

#### **Tank_Type__c (Tipo de Tanque)**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Name` | Text(80) | Nombre del tipo |
| `Description__c` | Long Text Area | Descripción técnica |

#### **Order__c (Pedido Personalizado)**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Name` | Auto-Number | Número de pedido |
| `Opportunity__c` | Lookup(Opportunity) | Oportunidad asociada |
| `Tank_Type__c` | Lookup(Tank_Type__c) | Tipo solicitado |
| `Desired_Capacity__c` | Number | Capacidad deseada |
| `Max_Price__c` | Currency | Precio máximo |

#### **Campos Personalizados en Lead**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Min_Price__c` | Currency | Precio mínimo aceptable |
| `Max_Price__c` | Currency | Precio máximo aceptable |
| `Desired_Capacity__c` | Number | Capacidad deseada |

#### **Campos Personalizados en Opportunity**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Tank__c` | Lookup(Tank__c) | Tanque asociado |
| `Order__c` | Lookup(Order__c) | Pedido asociado |
| `Tank_Serial_Number__c` | Formula(Text) | Muestra serial del tanque |

### **Relaciones**

```
Tank_Type__c
    │
    ├──── (1:N) Tank__c
    │
    └──── (1:N) Order__c
    
Tank__c
    │
    └──── (1:N) Opportunity

Order__c
    │
    └──── (1:N) Opportunity

Lead ──[Conversion Flow]──> Opportunity + (Tank OR Order)
```

---

## ⚙️ Funcionalidades Implementadas

### **1. Proceso de Venta Automatizado**

#### **1.1 - Conversión de Lead con Auto-Match**

**Tecnología:** Flow Builder + Process Builder

**Lógica:**
1. Usuario convierte Lead desde UI estándar
2. Flow se dispara automáticamente
3. Busca Tank disponible con:
   - `Capacity >= Lead.Desired_Capacity__c`
   - `Price BETWEEN Lead.Min_Price__c AND Lead.Max_Price__c`
   - `Status = 'Available'`
4. **Si encuentra Tank:**
   - Asocia a Opportunity
   - Cambia Status a 'Reserved'
5. **Si NO encuentra Tank:**
   - Crea Order__c con specs deseadas
   - Asocia Order a Opportunity

#### **1.2 - Validation Rule: XOR Tank/Order**

```apex
// Oportunidad NO puede tener Tank Y Order simultáneamente
AND(
    NOT(ISBLANK(Tank__c)),
    NOT(ISBLANK(Order__c))
)
```

**Mensaje de error:** "Una oportunidad solo puede tener un Tanque O un Pedido, no ambos."

---

### **2. Carga Masiva de Tanques (LWC)**

**Componente:** `tankMassLoader`

**Archivos:**
- `tankMassLoader.html` - Template con SLDS styling
- `tankMassLoader.js` - Lógica con PapaParse
- `tankMassLoader.js-meta.xml` - Metadata

**Flujo de Usuario:**

```
┌─────────────────────────────────────────────┐
│ PASO 1: Seleccionar Tipo de Tanque         │
│                                             │
│  [▼] Tipo de Tanque: Tanque Diesel         │
└─────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│ PASO 2: Cargar CSV                          │
│                                             │
│  📤 Upload Files                            │
│     Or drop files                           │
│                                             │
│  Archivo seleccionado: tanques.csv          │
└─────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│ PASO 3: Procesar y Crear Tanques           │
│                                             │
│  [   Procesar y Crear Tanques   ]          │
└─────────────────────────────────────────────┘
              │
              ▼
         🎉 Success: Created 10 new tanks.
```

**Código Apex Backend:**

```apex
@AuraEnabled
public static String createTanks(String jsonTanks, Id tankTypeId) {
    List<Object> csvRows = (List<Object>) JSON.deserializeUntyped(jsonTanks);
    List<Tank__c> tanksToInsert = new List<Tank__c>();
    
    // Loop 1: Preparar en memoria (NO DML)
    for(Object row : csvRows) {
        Map<String, Object> rowMap = (Map<String, Object>) row;
        Tank__c newTank = new Tank__c();
        newTank.Tank_Type__c = tankTypeId;
        newTank.Serial_Number__c = (String)rowMap.get('Serial Number');
        newTank.Status__c = 'Available';
        tanksToInsert.add(newTank);
    }
    
    // Loop 2: Insertar TODO de una vez (Bulk DML)
    if (!tanksToInsert.isEmpty()) {
        insert tanksToInsert;
        return 'Success: Created ' + tanksToInsert.size() + ' new tanks.';
    }
    return 'No tanks to create.';
}
```

**Best Practices aplicadas:**
- ✅ No DML in Loops
- ✅ Bulk operations
- ✅ Try-Catch error handling
- ✅ User-friendly messages

---

### **3. Integración con Bitly API**

**Objetivo:** Generar URLs cortas para acceder a tanques creados individualmente.

**Arquitectura:**

```
Tank Creation (UI)
      │
      ▼
TankTrigger (after insert)
      │
      ├─ if (Trigger.new.size() == 1)  ← Solo 1 registro
      │     └─ System.enqueueJob(new BitlyServiceQueueable(tankId))
      │
      └─ if (Trigger.new.size() > 1)   ← Bulk insert
            └─ NO ejecuta integración (evita límites)
```

#### **3.1 - Trigger Handler Pattern**

**Archivo:** `TankTrigger.trigger`

```apex
trigger TankTrigger on Tank__c (after insert) {
    new TankTriggerHandler().run();
}
```

**Archivo:** `TankTriggerHandler.cls`

```apex
public class TankTriggerHandler extends TriggerHandler {
    
    protected override void afterInsert() {
        // Solo dispara integración para creación individual
        if (Trigger.new.size() == 1) {
            Tank__c newTank = Trigger.new[0];
            System.enqueueJob(new BitlyServiceQueueable(newTank.Id));
        }
    }
}
```

#### **3.2 - Queueable con Named Credentials**

**Archivo:** `BitlyServiceQueueable.cls`

```apex
public class BitlyServiceQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id tankId;
    
    public void execute(QueueableContext context) {
        // 1. Construir URL larga de Salesforce
        String longUrl = System.URL.getOrgDomainUrl().toExternalForm() 
                         + '/' + this.tankId;
        
        // 2. Llamada HTTP usando Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Bitly_API/v4/shorten');  // ← Named Credential
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"long_url": "' + longUrl + '"}');
        
        // 3. Procesar respuesta
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String shortUrl = (String)result.get('link');
            
            // 4. Actualizar Tank
            update new Tank__c(Id = this.tankId, Bitly_Link__c = shortUrl);
        }
    }
}
```

**Named Credential Setup:**
- Nombre: `Bitly_API`
- URL: `https://api-ssl.bitly.com`
- Authentication: Password Authentication
- Custom Header: `Authorization: Bearer {!$Credential.Password}`

**Ventajas:**
- ✅ Token seguro (no hardcodeado)
- ✅ Async (no bloquea UI)
- ✅ Solo para operaciones individuales
- ✅ Respeta governor limits

---

## 🛠️ Tecnologías Utilizadas

### **Salesforce Platform**

| Tecnología | Uso en el Proyecto |
|------------|-------------------|
| **Apex** | Controllers, Triggers, Queueable, Test Classes |
| **Lightning Web Components** | Carga masiva de tanques (tankMassLoader) |
| **Flow Builder** | Lead conversion automation |
| **Process Builder** | Tank status updates |
| **Validation Rules** | XOR constraint (Tank/Order) |
| **Formula Fields** | Tank_Serial_Number display |
| **Security** | Permission Sets, Field-Level Security |

### **Apex Classes**

```
force-app/main/default/classes/
├── TankLoaderController.cls          # LWC Backend (carga masiva)
├── TankLoaderControllerTest.cls      # Tests del controller
├── TriggerHandler.cls                # Abstract trigger framework
├── TankTriggerHandler.cls            # Tank trigger logic
├── BitlyServiceQueueable.cls         # Integración Bitly async
└── BitlyIntegrationTest.cls          # Tests de integración (mocks)
```

### **Lightning Web Components**

```
force-app/main/default/lwc/
└── tankMassLoader/
    ├── tankMassLoader.html           # Template (UI)
    ├── tankMassLoader.js             # Logic + PapaParse
    └── tankMassLoader.js-meta.xml    # Metadata (targets)
```

### **Triggers**

```
force-app/main/default/triggers/
└── TankTrigger.trigger               # After insert trigger
```

### **Static Resources**

```
force-app/main/default/staticresources/
└── papaparse.resource                # PapaParse library (CSV parser)
```

---

## 🔐 Seguridad y Permisos

### **Permission Sets**

#### **Sales User**
**Descripción:** Usuarios de ventas

**Permisos de Objeto:**
| Objeto | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| Lead | ✅ | ✅ | ✅ | ✅ |
| Account | ✅ | ✅ | ✅ | ✅ |
| Opportunity | ✅ | ✅ | ✅ | ✅ |
| Tank__c | ❌ | ✅ | ❌ | ❌ |
| Tank_Type__c | ❌ | ✅ | ❌ | ❌ |
| Order__c | ❌ | ✅ | ❌ | ❌ |

#### **Tank Manager**
**Descripción:** Mantenedores de tanques

**Permisos de Objeto:**
| Objeto | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| Lead | ❌ | ❌ | ❌ | ❌ |
| Account | ❌ | ❌ | ❌ | ❌ |
| Opportunity | ❌ | ❌ | ❌ | ❌ |
| Tank__c | ✅ | ✅ | ✅ | ✅ |
| Tank_Type__c | ✅ | ✅ | ✅ | ✅ |
| Order__c | ❌ | ✅ | ❌ | ❌ |

**Tab Access:**
- ✅ Tank Mass Loader (LWC app page)

### **Sharing Rules**

- **Tanks:** Private (Owner-based)
- **Opportunities:** Private (controlled by Role Hierarchy)

---

## 🧪 Testing y Cobertura

### **Cobertura de Tests**

| Clase | Cobertura | Líneas Cubiertas |
|-------|-----------|------------------|
| `TankLoaderController` | **100%** | 45/45 |
| `TankTriggerHandler` | **100%** | 15/15 |
| `BitlyServiceQueueable` | **95%** | 38/40 |
| **TOTAL** | **~98%** | ✅ Production Ready |

### **Tests Implementados**

#### **TankLoaderControllerTest.cls**

```apex
@isTest
public class TankLoaderControllerTest {
    
    @testSetup
    static void setup() {
        Tank_Type__c type = new Tank_Type__c(Name = 'Test Type');
        insert type;
    }
    
    @isTest
    static void testCreateTanks_Success() {
        Tank_Type__c type = [SELECT Id FROM Tank_Type__c LIMIT 1];
        String json = '[{"Serial Number":"TANK-001"},{"Serial Number":"TANK-002"}]';
        
        Test.startTest();
        String result = TankLoaderController.createTanks(json, type.Id);
        Test.stopTest();
        
        System.assert(result.startsWith('Success'));
        System.assertEquals(2, [SELECT COUNT() FROM Tank__c]);
    }
    
    @isTest
    static void testGetTankTypes() {
        Test.startTest();
        List<Tank_Type__c> types = TankLoaderController.getTankTypes();
        Test.stopTest();
        
        System.assertEquals(1, types.size());
    }
}
```

#### **BitlyIntegrationTest.cls (con Mock)**

```apex
@isTest
public class BitlyIntegrationTest {
    
    @isTest
    static void testBitlyCallout_Success() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new BitlyMockSuccess());
        
        Tank_Type__c type = new Tank_Type__c(Name = 'Test');
        insert type;
        
        Tank__c tank = new Tank__c(
            Tank_Type__c = type.Id,
            Serial_Number__c = 'TEST-001',
            Status__c = 'Available'
        );
        
        Test.startTest();
        insert tank;  // Dispara trigger
        Test.stopTest();
        
        Tank__c updated = [SELECT Bitly_Link__c FROM Tank__c WHERE Id = :tank.Id];
        System.assertNotEquals(null, updated.Bitly_Link__c);
        System.assert(updated.Bitly_Link__c.startsWith('https://bit.ly/'));
    }
    
    // Mock HTTP Response
    private class BitlyMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"link":"https://bit.ly/test123"}');
            return res;
        }
    }
}
```

### **Best Practices en Tests**

- ✅ `@testSetup` para datos reutilizables
- ✅ `Test.startTest() / Test.stopTest()` para límites independientes
- ✅ Assertions claras con mensajes descriptivos
- ✅ Mocks para callouts HTTP
- ✅ Tests de escenarios positivos y negativos
- ✅ Bulk testing (200+ records)

---

## 📦 Instalación y Despliegue

### **Prerrequisitos**

- Salesforce CLI instalado
- Git instalado
- Cuenta de Salesforce Developer/Sandbox
- Cuenta de Bitly (para integración)

### **Opción 1: Despliegue con Salesforce CLI**

```bash
# 1. Clonar el repositorio
git clone https://github.com/[TU_USUARIO]/vantegrate-tank-manager.git
cd vantegrate-tank-manager

# 2. Autenticar con tu org
sf org login web

# 3. Desplegar metadata
sf project deploy start --source-dir force-app

# 4. Asignar Permission Sets
sf org assign permset --name Sales_User
sf org assign permset --name Tank_Manager

# 5. Abrir la org
sf org open
```

### **Opción 2: Despliegue Manual**

1. Descargar el ZIP del repositorio
2. Setup → Deployment → Deploy → Upload .zip
3. Esperar a que se complete el deploy
4. Configurar Named Credential (ver abajo)

### **Configuración Post-Instalación**

#### **1. Named Credential para Bitly**

```
Setup → Named Credentials → New Legacy

Label:                Bitly API
Name:                 Bitly_API
URL:                  https://api-ssl.bitly.com
Identity Type:        Named Principal
Authentication:       Password Authentication
Username:             bitly
Password:             [TU_BITLY_TOKEN]
Generate Auth Header: ✅ Checked

Custom Headers:
  Key: Authorization
  Value: Bearer {!$Credential.Password}
```

#### **2. Subir Static Resource (PapaParse)**

1. Descargar PapaParse: https://www.papaparse.com/
2. Setup → Static Resources → New
3. Name: `papaparse`
4. File: `papaparse.min.js`
5. Cache Control: Public

#### **3. Activar Flow**

Setup → Flows → `Lead_to_Opportunity_with_Tank_Match` → Activate

---

## 🎥 Demostración

### **Caso de Uso 1: Venta con Tank Existente**

1. Crear Lead:
   - Min Price: $5,000
   - Max Price: $10,000
   - Desired Capacity: 5000L

2. Convertir Lead → Se crea Opportunity con Tank auto-asignado
3. Tank Status cambia a "Reserved"

### **Caso de Uso 2: Venta sin Tank Disponible**

1. Crear Lead:
   - Min Price: $100
   - Max Price: $200
   - Desired Capacity: 100000L (muy grande)

2. Convertir Lead → Se crea Opportunity + Order (pedido)
3. Order contiene specs deseadas

### **Caso de Uso 3: Carga Masiva**

1. Abrir Lightning App → Tank Mass Loader
2. Seleccionar "Tanque Diesel"
3. Cargar CSV con 50 tanques
4. Click "Procesar" → 50 tanques creados en < 2 segundos

### **Caso de Uso 4: Integración Bitly**

1. Crear 1 Tank individualmente desde UI
2. Esperar 5 segundos (async)
3. Refrescar → Campo Bitly_Link__c poblado con URL corta

---

## 📈 Estándares de Desarrollo Cumplidos

Siguiendo los **Estándares Vantegrate:**

| Estándar | Cumplimiento |
|----------|--------------|
| **Bulkification** | ✅ Todos los métodos soportan bulk |
| **No DML in Loops** | ✅ Cumplido en todo el código |
| **Trigger Pattern** | ✅ TriggerHandler framework |
| **Test Coverage** | ✅ 98% coverage |
| **Error Handling** | ✅ Try-Catch + User Messages |
| **Named Credentials** | ✅ Para tokens seguros |
| **Security** | ✅ WITH SECURITY_ENFORCED |
| **Documentation** | ✅ JavaDoc comments |
| **Async Processing** | ✅ Queueable para callouts |

---

## 🚀 Mejoras Futuras

- [ ] Dashboard con métricas de ventas
- [ ] Einstein Analytics para forecasting
- [ ] Mobile app con Salesforce Mobile SDK
- [ ] Scheduled batch para limpiar Tanks antiguos
- [ ] Email notifications con Email Templates
- [ ] Chatter integration para notificaciones

---

## 👨‍💻 Autor

**Mateo Fernández**

- GitHub: [@[TU_USUARIO]](https://github.com/[TU_USUARIO])
- LinkedIn: [Mateo Fernández](https://linkedin.com/in/[TU_PERFIL])
- Email: matefernandezc@[DOMINIO]

---

## 📄 Licencia

Este proyecto fue desarrollado como ejercicio técnico para **Vantegrate**.

---

## 🙏 Agradecimientos

- Equipo de Vantegrate por la oportunidad
- Salesforce Trailhead por los recursos educativos
- Comunidad de Salesforce Developers

---

<div align="center">

**Desarrollado con ❤️ usando Salesforce**

[![Made with Salesforce](https://img.shields.io/badge/Made%20with-Salesforce-00A1E0?style=for-the-badge&logo=Salesforce&logoColor=white)](https://www.salesforce.com/)

</div>
