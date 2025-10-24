# ⚡ Tank Mass Loader - Lightning Web Component

## Descripción

Componente para carga masiva de tanques desde archivos CSV usando PapaParse.

## Arquitectura

```
Usuario → CSV File → PapaParse (Browser) → JSON → Apex Controller → Bulk Insert
```

## Características

- ✅ Selección de Tank Type via combobox
- ✅ Upload de archivo CSV con drag & drop
- ✅ Parsing client-side con PapaParse
- ✅ Bulk insert en Apex (No DML in loops)
- ✅ Toast notifications para feedback
- ✅ Validación de datos antes de envío

## Formato CSV Esperado

```csv
Serial Number
TANK-001
TANK-002
TANK-003
```

## Uso

1. Navegar a: App Launcher → Tank Mass Loader
2. Seleccionar Tank Type del combobox
3. Subir archivo CSV
4. Click "Procesar y Crear Tanques"
5. Ver toast de éxito con cantidad de tanques creados

## Archivos

- `tankMassLoader.html` - Template con SLDS styling
- `tankMassLoader.js` - Logic + PapaParse integration
- `tankMassLoader.js-meta.xml` - Metadata (exposed targets)

## Dependencies

- Static Resource: `papaparse` (PapaParse library)
- Apex Controller: `TankLoaderController`

## Target Pages

- App Page
- Home Page

