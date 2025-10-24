# 📦 Guía de Instalación Completa

## 🎯 Requisitos Previos
 
- [ ] Salesforce CLI instalado ([Download](https://developer.salesforce.com/tools/sfdxcli))
- [ ] Git instalado
- [ ] Org de Salesforce (Developer, Sandbox, o Scratch Org)
- [ ] Cuenta de Bitly ([Sign Up](https://bitly.com/a/sign_up))

---

## 🚀 Instalación Paso a Paso

### **Paso 1: Clonar el Repositorio**

```bash
git clone https://github.com/matefernandezcc/apex-lwc-integrations.git
cd apex-lwc-integrations
```

### **Paso 2: Autenticar con Salesforce**

```bash
# Opción A: Org existente
sf org login web --alias TankManager

# Opción B: Crear Scratch Org
sf org create scratch --definition-file config/project-scratch-def.json \
  --alias TankManager --set-default --duration-days 30
```

### **Paso 3: Desplegar Metadata**

```bash
# Deploy completo
sf project deploy start --source-dir force-app

# Verificar deploy
sf project deploy report
```

### **Paso 4: Configurar Named Credential**

#### **4.1 - Obtener Token de Bitly**

1. Ir a: https://bitly.com/a/sign_in
2. Login con tu cuenta
3. Settings → Developer Settings → API
4. Generate Access Token
5. Copiar el token (ej: `abc123xyz456...`)

#### **4.2 - Crear Named Credential en Salesforce**

```bash
# Abrir org
sf org open
```

En Salesforce:

```
Setup → Named Credentials → New Legacy Named Credential

┌────────────────────────────────────────────┐
│ Label:            Bitly API                │
│ Name:             Bitly_API                │
│ URL:              https://api-ssl.bitly.com│
│                                            │
│ Identity Type:    Named Principal          │
│ Authentication:   Password Authentication  │
│                                            │
│ Username:         bitly                    │
│ Password:         [PEGAR_TU_TOKEN_AQUI]   │
│                                            │
│ Generate Authorization Header: ✅          │
│                                            │
│ Custom Headers:                            │
│   Key:   Authorization                     │
│   Value: Bearer {!$Credential.Password}    │
└────────────────────────────────────────────┘

Click: Save
```

### **Paso 5: Subir Static Resource (PapaParse)**

#### **5.1 - Descargar PapaParse**

```bash
# Descargar desde CDN
curl -o papaparse.min.js https://cdn.jsdelivr.net/npm/papaparse@5/papaparse.min.js
```

#### **5.2 - Subir a Salesforce**

1. Setup → Static Resources → New
2. **Name:** `papaparse`
3. **File:** Seleccionar `papaparse.min.js`
4. **Cache Control:** Public
5. Click: Save

### **Paso 6: Asignar Permission Sets**

```bash
# Para usuario de ventas
sf org assign permset --name Sales_User --target-org TankManager

# Para usuario de mantenimiento
sf org assign permset --name Tank_Manager --target-org TankManager
```

### **Paso 7: Crear Datos de Prueba**

```bash
# Crear Tank Type
sf data create record --sobject Tank_Type__c --values "Name='Tanque Diesel'" \
  --target-org TankManager

# Crear Tank
sf data create record --sobject Tank__c \
  --values "Tank_Type__c=[ID_DEL_TIPO] Serial_Number__c='TANK-001' Status__c='Available' Price__c=8000 Capacity__c=5000" \
  --target-org TankManager
```

O usar el LWC para carga masiva con `example_tanks.csv`.

### **Paso 8: Activar Flow**

```bash
sf org open
```

En Salesforce:
```
Setup → Flows → "Lead to Opportunity with Tank Match"
Click: Activate
```

### **Paso 9: Verificar Instalación**

#### **9.1 - Test LWC**

1. App Launcher → Tank Mass Loader
2. Seleccionar Tank Type
3. Subir `example_tanks.csv`
4. Click: Procesar
5. ✅ Debería crear 10 tanques

#### **9.2 - Test Bitly Integration**

1. Ir a Tanks tab
2. Click: New
3. Llenar campos obligatorios
4. Save
5. Esperar 5 segundos
6. Refresh
7. ✅ Campo "Bitly Link" debería tener URL corta

#### **9.3 - Test Lead Conversion**

1. Crear Lead con:
   - Min Price: 5000
   - Max Price: 10000
   - Desired Capacity: 5000
2. Convertir Lead
3. ✅ Opportunity debería tener Tank asignado automáticamente

### **Paso 10: Ejecutar Tests**

```bash
# Ejecutar todos los tests
sf apex run test --test-level RunLocalTests --result-format human \
  --target-org TankManager

# Ver cobertura
sf apex get test --test-run-id [ID] --code-coverage --target-org TankManager
```

---

## 🔧 Troubleshooting

### **Error: "Named Credential not found"**

**Solución:**
- Verificar que el nombre sea exactamente `Bitly_API` (case-sensitive)
- Verificar que esté en "Named Credentials" (no "External Credentials")

### **Error: "PapaParse is not defined"**

**Solución:**
- Verificar que el Static Resource se llame exactamente `papaparse`
- Verificar que la línea 6 de `tankMassLoader.js` sea:
  ```javascript
  import PAPA_PARSE_JS from '@salesforce/resourceUrl/papaparse';
  ```

### **Error: "Field is not writeable"**

**Solución:**
- Asignar el Permission Set correcto al usuario
- Verificar Field-Level Security en Setup

### **Error: Tests failing**

**Solución:**
```bash
# Ver logs detallados
sf apex tail log --target-org TankManager

# Ejecutar test específico
sf apex run test --tests TankLoaderControllerTest --target-org TankManager
```

---

## 📊 Verificación de Instalación Exitosa

Checklist:

- [ ] ✅ Deploy exitoso (100% success)
- [ ] ✅ Named Credential configurado
- [ ] ✅ Static Resource subido
- [ ] ✅ Permission Sets asignados
- [ ] ✅ Flow activado
- [ ] ✅ LWC funciona (carga masiva)
- [ ] ✅ Bitly integration funciona
- [ ] ✅ Lead conversion funciona
- [ ] ✅ Tests pasan (>95% coverage)

---

## 🆘 Soporte

Si encuentras problemas:
1. Revisar logs: `sf apex tail log`
2. Verificar debug logs en Setup → Debug Logs
3. Contactar: matefernandezc@[DOMINIO]

---

## 🎉 ¡Instalación Completa!

Tu sistema de gestión de tanques está listo para usar.

**Próximos pasos:**
- Crear más Tank Types
- Importar catálogo de tanques vía CSV
- Crear Leads y probar conversión automática
- Ver Bitly links generados

---

<div align="center">

**¿Necesitas ayuda?**

[Documentación Completa](README.md) | [Reportar Issue](https://github.com/matefernandezcc/apex-lwc-integrations/issues)

</div>

