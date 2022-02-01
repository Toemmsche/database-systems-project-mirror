const express = require('express')

const app = express();

// serve static files
app.use(express.static('./dist/db-frontend'));

// always redirect to index.html (and pass path)
app.use(function (req, res) {
  res.sendFile('index.html', {root: 'dist/db-frontend'});
});

// listen on heroku port
app.listen(process.env.PORT || 8080);
