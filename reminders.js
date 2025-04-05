// routes/reminders.js
const express = require('express');
const router = express.Router();
const sql = require('mssql');

// Get all reminders for the authenticated user
router.get('/', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Reminders WHERE UserID = @userId ORDER BY DateTime ASC');
    
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get today's reminders
router.get('/today', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .input('today', sql.DateTime2, today)
      .input('tomorrow', sql.DateTime2, tomorrow)
      .query(`
        SELECT * FROM Reminders 
        WHERE UserID = @userId 
        AND DateTime >= @today 
        AND DateTime < @tomorrow 
        ORDER BY DateTime ASC
      `);
    
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get a single reminder by ID
router.get('/:id', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('reminderId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Reminders WHERE ReminderID = @reminderId AND UserID = @userId');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Reminder not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create a new reminder
router.post('/', async (req, res) => {
  try {
    const { title, description, dateTime } = req.body;
    
    const result = await global.sqlPool.request()
      .input('UserID', sql.Int, req.user.id)
      .input('Title', sql.NVarChar, title)
      .input('Description', sql.NVarChar, description)
      .input('DateTime', sql.DateTime2, new Date(dateTime))
      .execute('sp_CreateReminder');
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update a reminder
router.put('/:id', async (req, res) => {
  try {
    const { title, description, dateTime } = req.body;
    
    // First check if reminder exists and belongs to user
    const checkResult = await global.sqlPool.request()
      .input('reminderId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Reminders WHERE ReminderID = @reminderId AND UserID = @userId');
    
    if (checkResult.recordset.length === 0) {
      return res.status(404).json({ message: 'Reminder not found or not authorized' });
    }
    
    // Update the reminder
    const updateResult = await global.sqlPool.request()
      .input('reminderId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .input('title', sql.NVarChar, title)
      .input('description', sql.NVarChar, description)
      .input('dateTime', sql.DateTime2, new Date(dateTime))
      .query(`
        UPDATE Reminders
        SET Title = @title, 
            Description = @description, 
            DateTime = @dateTime
        WHERE ReminderID = @reminderId AND UserID = @userId;
        
        SELECT * FROM Reminders WHERE ReminderID = @reminderId;
      `);
    
    res.json(updateResult.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete a reminder
router.delete('/:id', async (req, res) => {
  try {
    await global.sqlPool.request()
      .input('ReminderID', sql.Int, req.params.id)
      .input('UserID', sql.Int, req.user.id)
      .execute('sp_DeleteReminder');
    
    res.json({ message: 'Reminder removed' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;