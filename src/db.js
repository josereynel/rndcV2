var Pool = require('pg').Pool;
var config = require('./config');

var pool = new Pool(config.postgres);

function query(sql, params) {
  return pool.query(sql, params || []);
}

function withTransaction(callback) {
  return pool.connect().then(function (client) {
    return client.query('BEGIN')
      .then(function () {
        return callback(client);
      })
      .then(function (result) {
        return client.query('COMMIT').then(function () {
          return result;
        });
      })
      .catch(function (error) {
        return client.query('ROLLBACK').then(function () {
          throw error;
        });
      })
      .finally(function () {
        client.release();
      });
  });
}

module.exports = {
  query: query,
  withTransaction: withTransaction,
  pool: pool
};
