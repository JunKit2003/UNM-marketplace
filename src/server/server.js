const express = require('express');
const { config } = require('dotenv');
const { parsed } = config();
const appRoutes = require('./routes/routes.js')
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: ['Content-Type', 'Authorization']
  }));

app.use('/api', appRoutes);


app.listen(parsed.PORT_SERVER, () => {
    console.log(`Server started on http://${parsed.HOST}:${parsed.PORT_SERVER}`);
});