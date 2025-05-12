// routes/statistics.js
const express = require('express');
const router = express.Router();
const sql = require('mssql');

// Get statistics for the authenticated user
router.get('/Statistics', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Statistics WHERE UserID = @userId');
    
    if (result.recordset.length === 0) {
      // Create statistics if they don't exist
      await global.sqlPool.request()
        .input('userId', sql.Int, req.user.id)
        .query('INSERT INTO Statistics (UserID) VALUES (@userId)');
      
      const newStats = await global.sqlPool.request()
        .input('userId', sql.Int, req.user.id)
        .query('SELECT * FROM Statistics WHERE UserID = @userId');
      
      return res.json(newStats.recordset[0]);
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Increment app usage count
router.post('/app-usage', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('UserID', sql.Int, req.user.id)
      .execute('sp_IncrementAppUsageCount');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Statistics not found' });
    }
    
    res.json({ 
      success: true, 
      appUsageCount: result.recordset[0].AppUsageCount 
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;