const express = require('express')
const app = express()
const port = 8080

app.get('/', (req, res) => {
  var ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress 
  console.log("/ called from ", ip)
  console.log("MYSQL_HOST", process.env.MYSQL_HOST)
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
