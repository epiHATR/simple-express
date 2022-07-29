const express = require('express')
const app = express()
const PORT = process.env.PORT || 8000
var os = require("os");
const { createLogger, format, transports } = require('winston');

const logger = createLogger({
  level: 'info',
  exitOnError: false,
  format: format.json(),
  transports: [
    new transports.Console()
  ]
});

function intervalFunc() {
  logger.info("dummy logs from "+ os.hostname() + " at "+ new Date())
}


app.get('/', (req, res) => {
  var data = {
    sevice_name: 'Simple Express',
    description: 'Simple nodejs app running with express. Machine name: '+os.hostname()
  }
  res.set('Content-Type', 'application/json');
  res.send(JSON.stringify(data, null, 4))
})

app.listen(PORT, () => {
  setInterval(intervalFunc, 1500);
  logger.info("NodeJS express running on port " + PORT)
})