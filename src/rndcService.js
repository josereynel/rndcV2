var axios = require('axios');
var config = require('./config');
var db = require('./db');
var logger = require('./logger');

function buildPayload(overrides) {
  var base = {
    acceso: config.rndc.acceso,
    solicitud: config.rndc.solicitud,
    documento: config.rndc.documento
  };
  if (!overrides) {
    return base;
  }
  return {
    acceso: Object.assign({}, base.acceso, overrides.acceso || {}),
    solicitud: Object.assign({}, base.solicitud, overrides.solicitud || {}),
    documento: Object.assign({}, base.documento, overrides.documento || {})
  };
}

function normalizeRows(responseData) {
  if (!responseData) {
    return [];
  }

  if (Array.isArray(responseData)) {
    return responseData;
  }

  if (Array.isArray(responseData.data)) {
    return responseData.data;
  }

  if (Array.isArray(responseData.manifiestos)) {
    return responseData.manifiestos;
  }

  return [];
}

function saveRows(rows) {
  if (!rows.length) {
    return Promise.resolve({ inserted: 0, updated: 0 });
  }

  var inserted = 0;
  var updated = 0;

  return db.withTransaction(function (client) {
    var chain = Promise.resolve();

    rows.forEach(function (item) {
      chain = chain.then(function () {
        var sql = [
          'INSERT INTO data_rndc(',
          ' ingresoidmanifiesto, numnitempresatransporte, fechaexpedicionmanifiesto, numplaca,',
          ' ingresoidremesa, codmunicipiocargueremesa, direccioncargueremesa,',
          ' codmunicipiodescargueremesa, direcciondescargueremesa,',
          ' fechacitacargue, horacitacargue, fechacitadescargue, horacitadescargue,',
          ' latitudcargue, longitudcargue, latituddescargue, longituddescargue, estado',
          ') VALUES(',
          ' $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,',
          " COALESCE($18, 'NUEVO')",
          ') ON CONFLICT(ingresoidmanifiesto) DO UPDATE SET',
          ' numnitempresatransporte = EXCLUDED.numnitempresatransporte,',
          ' fechaexpedicionmanifiesto = EXCLUDED.fechaexpedicionmanifiesto,',
          ' numplaca = EXCLUDED.numplaca,',
          ' ingresoidremesa = EXCLUDED.ingresoidremesa,',
          ' codmunicipiocargueremesa = EXCLUDED.codmunicipiocargueremesa,',
          ' direccioncargueremesa = EXCLUDED.direccioncargueremesa,',
          ' codmunicipiodescargueremesa = EXCLUDED.codmunicipiodescargueremesa,',
          ' direcciondescargueremesa = EXCLUDED.direcciondescargueremesa,',
          ' fechacitacargue = EXCLUDED.fechacitacargue,',
          ' horacitacargue = EXCLUDED.horacitacargue,',
          ' fechacitadescargue = EXCLUDED.fechacitadescargue,',
          ' horacitadescargue = EXCLUDED.horacitadescargue,',
          ' latitudcargue = EXCLUDED.latitudcargue,',
          ' longitudcargue = EXCLUDED.longitudcargue,',
          ' latituddescargue = EXCLUDED.latituddescargue,',
          ' longituddescargue = EXCLUDED.longituddescargue,',
          ' estado = EXCLUDED.estado',
          ' RETURNING (xmax = 0) AS inserted'
        ].join(' ');

        var values = [
          item.ingresoidmanifiesto || item.ingresoIdManifiesto || null,
          item.numnitempresatransporte || null,
          item.fechaexpedicionmanifiesto || null,
          item.numplaca || item.placa || null,
          item.ingresoidremesa || null,
          item.codmunicipiocargueremesa || null,
          item.direccioncargueremesa || null,
          item.codmunicipiodescargueremesa || null,
          item.direcciondescargueremesa || null,
          item.fechacitacargue || null,
          item.horacitacargue || null,
          item.fechacitadescargue || null,
          item.horacitadescargue || null,
          item.latitudcargue || null,
          item.longitudcargue || null,
          item.latituddescargue || null,
          item.longituddescargue || null,
          item.estado || 'NUEVO'
        ];

        return client.query(sql, values).then(function (result) {
          if (result.rows[0] && result.rows[0].inserted) {
            inserted += 1;
          } else {
            updated += 1;
          }
        });
      });
    });

    return chain.then(function () {
      return { inserted: inserted, updated: updated };
    });
  });
}

function syncRNDCSnapshot(options) {
  var payload = buildPayload(options || {});
  var startedAt = new Date();

  return logger.writeLog('Inicio consulta RNDC', payload.solicitud.procesoid, null)
    .then(function () {
      return axios.post(config.rndc.endpoint, payload, {
        timeout: config.rndc.timeoutMs,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    })
    .then(function (response) {
      var rows = normalizeRows(response.data);
      return saveRows(rows).then(function (saved) {
        var detail = 'Consulta RNDC OK. Filas recibidas: ' + rows.length + ', insertadas: ' + saved.inserted + ', actualizadas: ' + saved.updated;
        return logger.writeLog(detail, payload.solicitud.procesoid, null).then(function () {
          return {
            ok: true,
            startedAt: startedAt,
            finishedAt: new Date(),
            rowsReceived: rows.length,
            inserted: saved.inserted,
            updated: saved.updated,
            endpoint: config.rndc.endpoint
          };
        });
      });
    })
    .catch(function (error) {
      var message = error.response && error.response.data
        ? 'Error consulta RNDC: ' + JSON.stringify(error.response.data)
        : 'Error consulta RNDC: ' + error.message;

      return logger.writeLog(message, payload.solicitud.procesoid, null).then(function () {
        throw error;
      });
    });
}

module.exports = {
  syncRNDCSnapshot: syncRNDCSnapshot
};
