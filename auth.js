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


// Check if email exists (for password reset)
// routes/auth.js - in the check-email route
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body;
    console.log('Check email request received for:', email);
    
    // Check if user exists
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT UserID, Email FROM Users WHERE Email = @email');
    
    console.log('Database query result:', result);
    console.log('Records found:', result.recordset.length);
    
    if (result.recordset.length === 0) {
      console.log('No matching email found in database');
      return res.status(404).json({ 
        exists: false,
        message: 'Email not found in our system' 
      });
    }
    
    console.log('Email found, returning success response');
    res.json({ 
      exists: true,
      userId: result.recordset[0].UserID,
      email: result.recordset[0].Email
    });
  } catch (err) {
    console.error('Error in check-email route:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Reset password
router.post('/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    
    // Hash the new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Update password in database
    await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('newPassword', sql.NVarChar, hashedPassword)
      .query('UPDATE Users SET Password = @newPassword WHERE Email = @email');
    
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});
// Add to auth.js - new endpoint for generating and sending reset code
router.post('/request-reset-code', async (req, res) => {
  try {
    const { email } = req.body;
    console.log('Reset code requested for:', email);
    
    // Check if user exists
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT UserID, Email FROM Users WHERE Email = @email');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ 
        exists: false,
        message: 'Email not found in our system' 
      });
    }
    
    // Generate a 4-digit code
    const resetCode = Math.floor(1000 + Math.random() * 9000).toString();
    const userId = result.recordset[0].UserID;
    
    // Store reset code in the database with expiration time (30 minutes)
    const expiryTime = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes from now
    
    await global.sqlPool.request()
      .input('UserID', sql.Int, userId)
      .input('ResetCode', sql.NVarChar, resetCode)
      .input('ExpiryTime', sql.DateTime, expiryTime)
      .query(`
        UPDATE Users 
        SET ResetCode = @ResetCode, ResetCodeExpiry = @ExpiryTime 
        WHERE UserID = @UserID
      `);
    
    // In a production app, you would send an email with the code
    // For now, we'll just return it in the response (for testing)
    console.log('Reset code generated:', resetCode);
    
    // TODO: Add actual email sending code here
    // sendEmail(email, 'Password Reset Code', `Your password reset code is: ${resetCode}`);
    
    res.json({ 
      success: true, 
      message: 'Reset code sent to your email'
      // Don't include the code in the response in production
      // For testing only:
      , code: resetCode 
    });
  } catch (err) {
    console.error('Error in request-reset-code route:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add endpoint to verify the reset code
router.post('/verify-reset-code', async (req, res) => {
  try {
    const { email, code } = req.body;
    
    // Check if code is valid and not expired
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('code', sql.NVarChar, code)
      .query(`
        SELECT UserID FROM Users 
        WHERE Email = @email 
        AND ResetCode = @code 
        AND ResetCodeExpiry > GETDATE()
      `);
    
    if (result.recordset.length === 0) {
      return res.status(400).json({ 
        valid: false,
        message: 'Invalid or expired code' 
      });
    }
    
    res.json({ 
      valid: true,
      message: 'Code verified successfully' 
    });
  } catch (err) {
    console.error('Error in verify-reset-code route:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update the reset-password endpoint to require a verified code
router.post('/reset-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    
    // Verify the reset code again
    const verifyResult = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('code', sql.NVarChar, code)
      .query(`
        SELECT UserID FROM Users 
        WHERE Email = @email 
        AND ResetCode = @code 
        AND ResetCodeExpiry > GETDATE()
      `);
    
    if (verifyResult.recordset.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid or expired code' 
      });
    }
    
    // Hash the new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Update password and clear reset code
    await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('newPassword', sql.NVarChar, hashedPassword)
      .query(`
        UPDATE Users 
        SET Password = @newPassword, ResetCode = NULL, ResetCodeExpiry = NULL 
        WHERE Email = @email
      `);
    
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (err) {
    console.error('Error in reset-password route:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
