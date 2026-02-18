# rndcV2
Registro Nacional de Despachos de Carga.

## Webservice Node.js (v10.18.0)
Este proyecto implementa un servicio RNDC que:

1. Consulta información al webservice del Ministerio cada **20 minutos** (cron).
2. Permite forzar la consulta manual con `POST /sync`.
3. Corre en el **puerto 4001** por defecto.
4. Guarda trazabilidad operativa en `data_rndc_log`.
5. Deja la lógica de seguimiento vehicular en PostgreSQL mediante trigger sobre `gis_gps`.

## Requisitos
- Node.js `>=10.18.0`
- PostgreSQL

## Variables de entorno
- `PORT` (default: `4001`)
- `RNDC_CRON` (default: `*/20 * * * *`)
- `RNDC_ENDPOINT` (default: `https://plc.mintransporte.gov.co/RNDC/WcfRNDCV2.svc`)
- `RNDC_TIMEOUT_MS` (default: `30000`)
- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`

> Las credenciales RNDC se cargan automáticamente desde `acceso.json`.

## Instalación
```bash
npm install
```

## Ejecución
```bash
npm start
```

## Endpoints
### Estado del servicio
```bash
GET /health
```

### Consulta manual RNDC
```bash
POST /sync
Content-Type: application/json
```

Body opcional para sobreescribir campos de `acceso.json`:

```json
{
  "documento": {
    "manifiestos": "todos"
  }
}
```

## Base de datos
1. Ejecutar `db_script.sql` para crear/ajustar tablas y trigger.
2. Verificar que las filas GPS nuevas entren por `gis_gps` con:
   - `gps_vehiculo` (placa)
   - `gps_latitud`
   - `gps_longitud`
   - `gps_tstamp`

El trigger `trg_rndc_eval_from_gps` actualizará automáticamente etapas de cargue/descargue en `data_rndc` y registrará eventos en `data_rndc_log`.

## Notas de integración RNDC
Los manuales RNDC en `docs/` describen variantes de payload/respuesta según proceso. El servicio deja la normalización preparada para:
- arreglos directos,
- `data[]`,
- `manifiestos[]`.

Si el endpoint devuelve otra estructura, ajustar `normalizeRows()` en `src/rndcService.js`.
