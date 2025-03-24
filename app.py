from flask import Flask, request, jsonify
from flask_cors import CORS
import pyodbc
from datetime import datetime
import os
import logging
import socket

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
# Configure CORS to allow requests from any origin
CORS(app, resources={r"/*": {"origins": "*"}})

# Database connection with better error handling
def get_db_connection():
    try:
        logger.info("Attempting to connect to database...")
        conn = pyodbc.connect(
            'DRIVER={ODBC Driver 17 for SQL Server};'
            'SERVER=DESKTOP-C9SA70I;'
            'DATABASE=NotiTechDataBase;'
            'Trusted_Connection=yes;'
            'TrustServerCertificate=yes;'
        )
        logger.info("Database connection successful")
        return conn
    except pyodbc.Error as e:
        logger.error(f"Database connection error: {str(e)}")
        raise

@app.route('/register', methods=['POST'])
def register_user():
    try:
        logger.info("Received registration request")
        data = request.get_json()
        
        if not data:
            logger.warning("No data provided in request")
            return jsonify({'message': 'No data provided'}), 400

        # Extract all required fields
        email = data.get('email')
        password = data.get('password')
        name = data.get('name', '')  # Name is optional with default empty string
        
        logger.info(f"Registration attempt for email: {email}")
        
        # Validate required fields
        if not email:
            logger.warning("Missing email")
            return jsonify({'message': 'Email is required'}), 400
        if not password:
            logger.warning("Missing password")
            return jsonify({'message': 'Password is required'}), 400

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            # Check if email exists
            cursor.execute('SELECT * FROM users WHERE email = ?', (email,))
            if cursor.fetchone():
                logger.warning(f"Email already exists: {email}")
                conn.close()
                return jsonify({'message': 'Email already exists'}), 400

            # Insert new user
            cursor.execute(
                'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
                (name, email, password)
            )
            conn.commit()
            conn.close()
            
            logger.info(f"User registered successfully: {email}")
            return jsonify({
                'message': 'User registered successfully',
                'user_email': email
            }), 201
            
        except pyodbc.Error as e:
            logger.error(f"Database error during registration: {str(e)}")
            return jsonify({'message': 'Database error occurred'}), 500

    except Exception as e:
        logger.error(f"Unexpected error in /register: {str(e)}")
        return jsonify({'message': 'An unexpected error occurred'}), 500

@app.route('/login', methods=['POST'])
def login_user():
    try:
        logger.info("Received login request")
        data = request.get_json()
        
        if not data:
            logger.warning("No data provided in login request")
            return jsonify({'message': 'No data provided'}), 400

        email = data.get('email')
        password = data.get('password')
        
        logger.info(f"Login attempt for email: {email}")

        # Validate required fields
        if not email:
            logger.warning("Missing email in login request")
            return jsonify({'message': 'Email is required'}), 400
        if not password:
            logger.warning("Missing password in login request")
            return jsonify({'message': 'Password is required'}), 400

        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            cursor.execute(
                'SELECT id, email FROM users WHERE email = ? AND password = ?',
                (email, password)
            )
            user = cursor.fetchone()
            conn.close()

            if user:
                logger.info(f"Login successful for user: {email}")
                return jsonify({
                    'message': 'Login successful',
                    'user_id': user[0],
                    'email': user[1]
                }), 200
            else:
                logger.warning(f"Invalid login credentials for: {email}")
                return jsonify({'message': 'Invalid email or password'}), 401
                
        except pyodbc.Error as e:
            logger.error(f"Database error during login: {str(e)}")
            return jsonify({'message': 'Database error occurred'}), 500

    except Exception as e:
        logger.error(f"Unexpected error in /login: {str(e)}")
        return jsonify({'message': 'An unexpected error occurred'}), 500

@app.route('/test', methods=['GET'])
def test_connection():
    """Endpoint to test server connectivity"""
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        return jsonify({
            'message': 'Server is running',
            'hostname': hostname,
            'ip_address': ip_address,
            'status': 'active'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Get network information
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    logger.info(f"Starting server on {ip_address}:5000")
    logger.info(f"To connect from Flutter, use this IP address: {ip_address}")
    
    app.run(host='0.0.0.0', port=5000, debug=True)