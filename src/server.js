var createApp = require('./app');
var config = require('./config');

var app = createApp();

app.listen(config.server.port, function () {
  console.log('RNDC webservice escuchando en puerto ' + config.server.port);
});
