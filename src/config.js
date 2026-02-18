var fs = require('fs');
var path = require('path');

function loadLocalAccessConfig() {
  var accessFile = path.join(__dirname, '..', 'acceso.json');
  try {
    var content = fs.readFileSync(accessFile, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    return {};
  }
}

var localConfig = loadLocalAccessConfig();

module.exports = {
  server: {
    port: Number(process.env.PORT || 4001)
  },
  scheduler: {
    cronExpression: process.env.RNDC_CRON || '*/20 * * * *'
  },
  rndc: {
    endpoint: process.env.RNDC_ENDPOINT || 'https://plc.mintransporte.gov.co/RNDC/WcfRNDCV2.svc',
    timeoutMs: Number(process.env.RNDC_TIMEOUT_MS || 30000),
    acceso: localConfig.acceso || {},
    solicitud: localConfig.solicitud || {},
    documento: localConfig.documento || {}
  },
  postgres: {
    host: process.env.PGHOST || '127.0.0.1',
    port: Number(process.env.PGPORT || 5432),
    database: process.env.PGDATABASE || 'postgres',
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || ''
  }
};
