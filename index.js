const express = require('express')
const axios = require('axios')
const dotenv = require('dotenv');
var os = require("os");
var redis = require("redis")

dotenv.config();

// Default Logger
const { createLogger, format, transports } = require('winston');

// for Azure Event Hub
const { EventHubProducerClient } = require("@azure/event-hubs");
const connectionString = process.env.EVENTHUB_NAMESPACE_CONNECTIONSTRING || null
const eventHubName = process.env.EVENTHUB_NAME || null

// for VNET
const WEBSITE_PRIVATE_IP = process.env.WEBSITE_PRIVATE_IP || ''

const app = express()
const PORT = process.env.PORT || 8000
const ENV_NAME = process.env.ENV_NAME || 'development'

// for Azure Caches for Redis
const CACHES_URL = process.env.CACHES_URL || null
const CACHES_KEY = process.env.CACHES_KEY || null
const CACHES_PORT = process.env.CACHES_PORT || 6380

const logger = createLogger({
  level: 'info',
  exitOnError: false,
  format: format.json(),
  transports: [
    new transports.Console(),
    new transports.File({ filename: `/var/logs/simple-express.log` }),
  ]
});

function intervalFunc() {
  logger.info("dummy logs from " + os.hostname() + " at " + new Date())
}

app.get('/', (req, res) => {
  var data = {
    sevice_name: 'Simple Express on ' + ENV_NAME,
    port: PORT,
    description: 'Simple nodejs app running with Express.',
    instance: os.hostname(),
    private_ip: WEBSITE_PRIVATE_IP
  }
  res.set('Content-Type', 'application/json');
  res.send(JSON.stringify(data, null, 4))
})

app.get('/ping', (req, res) => {
  var endpoint = req.query.endpoint

  axios.get(endpoint)
    .then(resp => {
      res.set('Content-Type', 'application/json');
      res.send(JSON.stringify(resp.data, null, 4))
    })
    .catch(err => {
      res.set('Content-Type', 'application/json');
      res.send(JSON.stringify(err, null, 4))
    })
})

app.get("/sender", async (req, res) => {
  var isEventhubDefined = true

  if (connectionString == null) {
    isEventhubDefined = false
  }
  if (eventHubName == null) {
    isEventhubDefined = false
  }
  if (isEventhubDefined) {
    const producer = new EventHubProducerClient(connectionString, eventHubName)
    const batch = await producer.createBatch()
    const sentTime = new Date().toISOString("dd-mm-yyyy")
    batch.tryAdd({ body: "Dummy event sent at " + sentTime })
    await producer.sendBatch(batch)
    var resObj = {
      success: true,
      message: 'An event was sent at ' + sentTime
    }
    res.set('Content-Type', 'application/json');
    res.send(JSON.stringify(resObj), null, 4)
  }
  else {
    var resObj = {
      success: false,
      message: 'No EVENTHUB_NAME or EVENTHUB_NAMESPACE_CONNECTIONSTRING configuration keys defined'
    }
    res.set('Content-Type', 'application/json');
    res.send(JSON.stringify(resObj), null, 4)
  }
})

app.get("/caches/verify", async (req, res) => {
  var isCachesConfigured = true
  var msg = {
    info: {}
  }

  if (CACHES_URL == null || CACHES_KEY == null) {
    isCachesConfigured = false
  }

  if (isCachesConfigured) {
    var cacheConnection = redis.createClient({ url: "rediss://" + CACHES_URL + ":" + CACHES_PORT, password: CACHES_KEY })

    try {
      await cacheConnection.connect()
      msg.error = false
      msg.message = "Azure Caches for Redis is configured successfully"
      msg.info.url = CACHES_URL
      msg.info.port = CACHES_PORT
    }
    catch (err) {
      msg.error = true
      msg.message = err.message
    }
  }
  else {
    msg = {
      error: true,
      message: 'Set CACHES_URL & CACHES_KEY in application setting to use Azure Caches for Redis'
    }
  }

  res.set('Content-Type', 'application/json');
  res.send(JSON.stringify(msg, null, 4))
})

app.get("/caches/create", async (req, res) => {
  if (CACHES_URL != null && CACHES_KEY != null) {
    var cacheConnection = redis.createClient({ url: "rediss://" + CACHES_URL + ":" + CACHES_PORT, password: CACHES_KEY })
    await cacheConnection.connect()
    for (let index = 0; index < 20; index++) {
      var keyData = `Index_${index}`
      var valueData = `The index ${index} ${new Date().toISOString()}`

      await cacheConnection.set(keyData, valueData)
      logger.info(`Key Index_${index} has been created on Azure Caches for Redis`)
    }
    msg = {
      error: false,
      message: 'Index_0 to Index_19 keys has been created on Azure Caches for Redis'
    }
    res.set('Content-Type', 'application/json');
    res.send(JSON.stringify(msg, null, 4))
  }
})

app.get("/caches/list", async (req, res) => {
  if (CACHES_URL != null && CACHES_KEY != null) {
    var cacheConnection = redis.createClient({ url: "rediss://" + CACHES_URL + ":" + CACHES_PORT, password: CACHES_KEY })
    await cacheConnection.connect()
    data = []
    for (let index = 0; index < 20; index++) {
      value = await cacheConnection.get(`Index_${index}`)
      if (value) {
        data.push({
          key: `Index_${index}`,
          value: value 
        })
      }
    }
    msg = {
      error: false,
      message: 'Keys has been retrieved successfully',
      data: data
    }
    res.set('Content-Type', 'application/json');
    res.send(JSON.stringify(msg, null, 4))
  }
})

app.listen(PORT, () => {
  setInterval(intervalFunc, 3000);
  logger.info("NodeJS express running on port " + PORT)
})