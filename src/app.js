var express = require('express');
var cron = require('node-cron');
var config = require('./config');
var rndcService = require('./rndcService');

function createApp() {
  var app = express();
  app.use(express.json({ limit: '1mb' }));

  var schedulerState = {
    running: false,
    lastSuccessAt: null,
    lastError: null
  };

  function runSync(trigger, options) {
    schedulerState.running = true;
    return rndcService.syncRNDCSnapshot(options)
      .then(function (result) {
        schedulerState.running = false;
        schedulerState.lastSuccessAt = result.finishedAt;
        schedulerState.lastError = null;
        return {
          trigger: trigger,
          result: result
        };
      })
      .catch(function (error) {
        schedulerState.running = false;
        schedulerState.lastError = error.message;
        throw error;
      });
  }

  cron.schedule(config.scheduler.cronExpression, function () {
    runSync('cron').catch(function (error) {
      console.error('[RNDC][CRON]', error.message);
    });
  });

  app.get('/health', function (req, res) {
    res.json({
      ok: true,
      scheduler: schedulerState,
      cron: config.scheduler.cronExpression
    });
  });

  app.post('/sync', function (req, res) {
    runSync('manual', req.body || {})
      .then(function (payload) {
        res.json(payload);
      })
      .catch(function (error) {
        res.status(500).json({
          ok: false,
          error: error.message
        });
      });
  });

  return app;
}

module.exports = createApp;
