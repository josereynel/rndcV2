var db = require('./db');

function writeLog(message, groupId, ingresoIdRemesa) {
  var insert = 'INSERT INTO data_rndc_log(message, group_id, ingresoidremesa) VALUES ($1, $2, $3)';
  var params = [message, groupId || null, ingresoIdRemesa || null];

  return db.query(insert, params).catch(function (error) {
    // fallback en consola para no romper el flujo principal
    console.error('[RNDC][LOG_ERROR]', error.message);
  });
}

module.exports = {
  writeLog: writeLog
};
