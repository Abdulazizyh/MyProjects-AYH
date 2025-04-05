// routes/auth.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const sql = require('mssql');
const { authenticateToken } = require('../middleware/auth');

// Register a new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Check if user already exists
    const userCheck = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT * FROM Users WHERE Email = @email');
    
    if (userCheck.recordset.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    // Register new user using stored procedure
    const result = await global.sqlPool.request()
      .input('Name', sql.NVarChar, name)
      .input('Email', sql.NVarChar, email)
      .input('Password', sql.NVarChar, hashedPassword)
      .execute('sp_RegisterUser');
    
    const newUser = result.recordset[0];
    
    // Generate token
    const token = jwt.sign(
      { id: newUser.UserID, email: newUser.Email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.status(201).json({
      token,
      user: {
        id: newUser.UserID,
        name: newUser.Name,
        email: newUser.Email
      }
    });
  } catch (err) {
    console.error('Registration error details:', err);
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Check if user exists
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT * FROM Users WHERE Email = @email');
    
    if (result.recordset.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    
    const user = result.recordset[0];
    
    // Validate password
    const isMatch = await bcrypt.compare(password, user.Password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    
    // Update sign-in count
    await global.sqlPool.request()
      .input('UserID', sql.Int, user.UserID)
      .execute('sp_IncrementSignInCount');
    
    // Generate token
    const token = jwt.sign(
      { id: user.UserID, email: user.Email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({
      token,
      user: {
        id: user.UserID,
        name: user.Name,
        email: user.Email
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get current user
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('id', sql.Int, req.user.id)
      .query('SELECT UserID, Name, Email, CreatedAt FROM Users WHERE UserID = @id');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update app usage count
router.post('/app-usage', authenticateToken, async (req, res) => {
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