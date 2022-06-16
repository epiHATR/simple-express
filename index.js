const express = require('express')
const app = express()
const PORT = process.env.PORT || 8000
var os = require("os");

app.get('/', (req, res) => {
  var data = {
    sevice_name: 'Simple Express',
    description: 'Simple nodejs app running with express. Machine name: '+os.hostname()
  }
  res.set('Content-Type', 'application/json');
  res.send(JSON.stringify(data, null, 4))
})

app.listen(PORT, () => {
  console.log("NodeJS express running on port " + PORT)
})