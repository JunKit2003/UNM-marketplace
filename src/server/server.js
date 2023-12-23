const express = require('express');
const { config } = require('dotenv');
const { parsed } = config();
const appRoutes = require('./routes/routes.js');
const cors = require('cors');
const session = require('express-session');

const app = express();

// Parsing JSON bodies (as sent by API clients)
app.use(express.json());


app.use(cors({
    origin: 'http://localhost:8000',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  }));

// Session configuration
app.use(session({
  secret: 'your-secret-key', // replace with your secret key
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // use secure: true for HTTPS, false for HTTP
}));

app.use('/api', appRoutes);


app.listen(parsed.PORT_SERVER, () => {
    console.log(`Server started on http://${parsed.HOST}:${parsed.PORT_SERVER}`);
});