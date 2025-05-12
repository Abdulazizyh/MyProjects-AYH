// routes/notes.js
const express = require('express');
const router = express.Router();
const sql = require('mssql');

// Get all notes for the authenticated user
router.get('/', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .query(`
        SELECT 
          NoteID as id,
          Title as title,
          Body as body,
          TextColor as textColor,
          FontFamily as fontFamily,
          FontSize as fontSize,
          CreatedAt as createdAt,
          UpdatedAt as updatedAt
        FROM Notes 
        WHERE UserID = @userId 
        ORDER BY CreatedAt DESC
      `);
    
    res.json(result.recordset); // Make sure the result is correctly returned as JSON
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



// Get a single note by ID
// Get a single note by ID
router.get('/:id', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query(`
        SELECT 
          NoteID as id,
          Title as title,
          Body as body,
          TextColor as textColor,
          FontFamily as fontFamily,
          FontSize as fontSize,
          CreatedAt as createdAt,
          UpdatedAt as updatedAt
        FROM Notes 
        WHERE NoteID = @noteId AND UserID = @userId
      `);
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Note not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


// Create a new note
// In your backend API (routes/notes.js):
router.post('/', async (req, res) => {
  try {
    const { title, body, textColor, fontFamily, fontSize } = req.body;

    // Validate required fields
    if (!title || !body) {
      return res.status(400).json({ message: 'Title and body are required' });
    }

    // Ensure textColor is within SQL Server INT range
    const validTextColor = Math.max(-2147483648, Math.min(2147483647, textColor || 0xFF000000));

    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .input('title', sql.NVarChar, title)
      .input('body', sql.NVarChar, body)
      .input('textColor', sql.Int, validTextColor)
      .input('fontFamily', sql.NVarChar, fontFamily || 'Default')
      .input('fontSize', sql.Float, fontSize || 16.0)
      .query(`
        INSERT INTO Notes (UserID, Title, Body, TextColor, FontFamily, FontSize)
        VALUES (@userId, @title, @body, @textColor, @fontFamily, @fontSize);

        SELECT 
          NoteID as id,
          Title as title,
          Body as body,
          TextColor as textColor,
          FontFamily as fontFamily,
          FontSize as fontSize,
          CreatedAt as createdAt,
          UpdatedAt as updatedAt
        FROM Notes 
        WHERE NoteID = SCOPE_IDENTITY();
      `);

    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



// Update a note
router.put('/:id', async (req, res) => {
  try {
    const { title, body, textColor, fontFamily, fontSize } = req.body;
    
    // First check if note exists and belongs to user
    const checkResult = await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Notes WHERE NoteID = @noteId AND UserID = @userId');
    
    if (checkResult.recordset.length === 0) {
      return res.status(404).json({ message: 'Note not found or not authorized' });
    }
    
    // Update the note
    const updateResult = await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .input('title', sql.NVarChar, title)
      .input('body', sql.NVarChar, body)
      .input('textColor', sql.Int, textColor)
      .input('fontFamily', sql.NVarChar, fontFamily)
      .input('fontSize', sql.Float, fontSize)
      .query(`
        UPDATE Notes
        SET 
          Title = @title, 
          Body = @body,
          TextColor = @textColor,
          FontFamily = @fontFamily,
          FontSize = @fontSize,
          UpdatedAt = GETDATE()
        WHERE NoteID = @noteId AND UserID = @userId;
        
        SELECT 
          NoteID as id,
          Title as title,
          Body as body,
          TextColor as textColor,
          FontFamily as fontFamily,
          FontSize as fontSize,
          CreatedAt as createdAt,
          UpdatedAt as updatedAt
        FROM Notes 
        WHERE NoteID = @noteId;
      `);
    
    res.json(updateResult.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete a note
router.delete('/:id', async (req, res) => {
  try {
    // First check if note exists and belongs to user
    const checkResult = await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Notes WHERE NoteID = @noteId AND UserID = @userId');
    
    if (checkResult.recordset.length === 0) {
      return res.status(404).json({ message: 'Note not found or not authorized' });
    }
    
    await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('DELETE FROM Notes WHERE NoteID = @noteId AND UserID = @userId');
    
    res.json({ message: 'Note deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Search notes
router.get('/search/:query', async (req, res) => {
  try {
    const searchQuery = req.params.query;
    
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .input('searchTerm', sql.NVarChar, `%${searchQuery}%`)
      .query(`
        SELECT 
          NoteID as id,
          Title as title,
          Body as body,
          TextColor as textColor,
          FontFamily as fontFamily,
          FontSize as fontSize,
          CreatedAt as createdAt,
          UpdatedAt as updatedAt
        FROM Notes 
        WHERE UserID = @userId 
        AND (Title LIKE @searchTerm OR Body LIKE @searchTerm)
        ORDER BY CreatedAt DESC
      `);
    
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


module.exports = router;