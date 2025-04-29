// routes/notes.js
const express = require('express');
const router = express.Router();
const sql = require('mssql');

// Get all notes for the authenticated user
router.get('/', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Notes WHERE UserID = @userId ORDER BY CreatedAt DESC');
    
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get a single note by ID
router.get('/:id', async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('noteId', sql.Int, req.params.id)
      .input('userId', sql.Int, req.user.id)
      .query('SELECT * FROM Notes WHERE NoteID = @noteId AND UserID = @userId');
    
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
router.post('/', async (req, res) => {
  try {
    const { title, body } = req.body;
    
    const result = await global.sqlPool.request()
      .input('UserID', sql.Int, req.user.id)
      .input('Title', sql.NVarChar, title)
      .input('Body', sql.NVarChar, body)
      .execute('sp_CreateNote');
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update a note
router.put('/:id', async (req, res) => {
  try {
    const { title, body } = req.body;
    
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
      .query(`
        UPDATE Notes
        SET Title = @title, 
            Body = @body, 
            UpdatedAt = GETDATE()
        WHERE NoteID = @noteId AND UserID = @userId;
        
        SELECT * FROM Notes WHERE NoteID = @noteId;
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
    await global.sqlPool.request()
      .input('NoteID', sql.Int, req.params.id)
      .input('UserID', sql.Int, req.user.id)
      .execute('sp_DeleteNote');
    
    res.json({ message: 'Note removed' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/search/:query', async (req, res) => {
  try {
    const searchQuery = req.params.query;
    
    const result = await global.sqlPool.request()
      .input('userId', sql.Int, req.user.id)
      .input('searchTerm', sql.NVarChar, `%${searchQuery}%`) // Using LIKE query with wildcards
      .query(`
        SELECT * FROM Notes 
        WHERE UserID = @userId 
        AND Title LIKE @searchTerm 
        ORDER BY CreatedAt DESC
      `);
    
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;