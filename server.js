// server.js - Main entry point for the application
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const sql = require('mssql');
const authRoutes = require('./routes/auth');
const noteRoutes = require('./routes/notes');
const reminderRoutes = require('./routes/reminders');
const statisticsRoutes = require('./routes/statistics');
const { authenticateToken } = require('./middleware/auth');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// SQL Server Connection Configuration
const sqlConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  server: process.env.DB_SERVER,
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  },
  options: {
    encrypt: true, // for azure
    trustServerCertificate: true // change to false for production
  }
};

// Global SQL pool that will be used in routes
global.sqlPool = new sql.ConnectionPool(sqlConfig);

// Connect to SQL Server
global.sqlPool.connect()
  .then(() => {
    console.log('Connected to SQL Server');
  })
  .catch(err => {
    console.error('SQL Server connection error:', err);
  });

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/notes', authenticateToken, noteRoutes);
app.use('/api/reminders', authenticateToken, reminderRoutes);
app.use('/api/statistics', authenticateToken, statisticsRoutes);

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Handle graceful shutdown and close SQL connection
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing SQL connection pool');
  await global.sqlPool.close();
  process.exit(0);
});