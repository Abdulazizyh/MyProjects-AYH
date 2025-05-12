const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const sql = require('mssql');
const { authenticateToken } = require('../middleware/auth');

// Register a new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, securityQuestion, securityAnswer } = req.body;
    
    // Check if user already exists
    const userCheck = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT * FROM Users WHERE Email = @email');
    
    if (userCheck.recordset.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Hash password and security answer
    const hashedPassword = await bcrypt.hash(password, 10);
    const hashedSecurityAnswer = await bcrypt.hash(securityAnswer.toLowerCase(), 10);
    
    // Register new user using stored procedure
    const result = await global.sqlPool.request()
      .input('Name', sql.NVarChar, name)
      .input('Email', sql.NVarChar, email)
      .input('Password', sql.NVarChar, hashedPassword)
      .input('SecurityQuestion', sql.NVarChar, securityQuestion)
      .input('SecurityAnswer', sql.NVarChar, hashedSecurityAnswer)
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
        email: newUser.Email,
        securityQuestion: newUser.SecurityQuestion
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
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
        email: user.Email,
        securityQuestion: user.SecurityQuestion
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get security question for a user
router.get('/security-question/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT SecurityQuestion FROM Users WHERE Email = @email');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ securityQuestion: result.recordset[0].SecurityQuestion });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Verify security answer
// Verify security answer with a list of predefined questions
router.post('/verify-security-answer', async (req, res) => {
  try {
    const { email, securityQuestion, securityAnswer } = req.body;
    
    // Query to fetch the user's security question and answer from the database
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('securityQuestion', sql.NVarChar, securityQuestion) // Use the selected question
      .query('SELECT UserID, SecurityAnswer, SecurityQuestion FROM Users WHERE Email = @email AND SecurityQuestion = @securityQuestion');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'User not found or incorrect question' });
    }
    
    const user = result.recordset[0];
    
    // Compare the security answer provided by the user with the stored one (case insensitive)
    const isMatch = await bcrypt.compare(securityAnswer.toLowerCase(), user.SecurityAnswer);
    
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid security answer', verified: false });
    }
    
    // Answer is correct
    res.json({ verified: true, userId: user.UserID });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


// Reset password with security answer
router.post('/reset-password/security', async (req, res) => {
  try {
    const { email, securityAnswer, newPassword } = req.body;
    
    // Verify user exists and get security answer
    const userResult = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT UserID, SecurityAnswer FROM Users WHERE Email = @email');
    
    if (userResult.recordset.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResult.recordset[0];
    
    // Verify security answer
    const isMatch = await bcrypt.compare(securityAnswer.toLowerCase(), user.SecurityAnswer);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid security answer' });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await global.sqlPool.request()
      .input('UserID', sql.Int, user.UserID)
      .input('Password', sql.NVarChar, hashedPassword)
      .query('UPDATE Users SET Password = @Password WHERE UserID = @UserID');
    
    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Reset password with verification code
router.post('/reset-password/code', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    
    // Verify reset code is valid
    const codeResult = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('code', sql.NVarChar, code)
      .query('SELECT * FROM PasswordResetCodes WHERE Email = @email AND Code = @code AND ExpiresAt > GETDATE()');
    
    if (codeResult.recordset.length === 0) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('password', sql.NVarChar, hashedPassword)
      .query('UPDATE Users SET Password = @password WHERE Email = @email');
    
    // Delete used reset code
    await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('DELETE FROM PasswordResetCodes WHERE Email = @email');
    
    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Generate and send reset code
router.post('/request-reset-code', async (req, res) => {
  try {
    const { email } = req.body;
    
    // Verify user exists
    const userResult = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT UserID FROM Users WHERE Email = @email');
    
    if (userResult.recordset.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Generate 4-digit code
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    
    // Store code with expiration (30 minutes)
    await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('code', sql.NVarChar, code)
      .query(`
        DELETE FROM PasswordResetCodes WHERE Email = @email;
        INSERT INTO PasswordResetCodes (Email, Code, ExpiresAt)
        VALUES (@email, @code, DATEADD(MINUTE, 30, GETDATE()))
      `);
    
    // In a production app, send code via email
    // For this demo, return code directly (not secure for production)
    res.json({ success: true, code });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Verify reset code
router.post('/verify-reset-code', async (req, res) => {
  try {
    const { email, code } = req.body;
    
    const result = await global.sqlPool.request()
      .input('email', sql.NVarChar, email)
      .input('code', sql.NVarChar, code)
      .query('SELECT * FROM PasswordResetCodes WHERE Email = @email AND Code = @code AND ExpiresAt > GETDATE()');
    
    if (result.recordset.length === 0) {
      return res.json({ verified: false });
    }
    
    res.json({ verified: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const result = await global.sqlPool.request()
      .input('id', sql.Int, req.user.id)
      .query('SELECT UserID, Name, Email, SecurityQuestion, CreatedAt FROM Users WHERE UserID = @id');
    
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
