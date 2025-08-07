#!/bin/bash

# Virtual environment setup script for Flask app

set -e

VENV_NAME="venv"

echo "Setting up Python virtual environment..."

# Check if virtual environment already exists
if [ -d "$VENV_NAME" ]; then
    echo "Virtual environment '$VENV_NAME' already exists."
    read -p "Do you want to recreate it? (y/N): " recreate
    if [[ $recreate =~ ^[Yy]$ ]]; then
        echo "Removing existing virtual environment..."
        rm -rf "$VENV_NAME"
    else
        echo "Using existing virtual environment."
    fi
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_NAME" ]; then
    echo "Creating new virtual environment..."
    python3 -m venv "$VENV_NAME"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

# Upgrade pip in virtual environment
echo "Upgrading pip in virtual environment..."
pip install --upgrade pip

# Install requirements if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies from requirements.txt..."
    pip install -r requirements.txt
else
    echo "No requirements.txt found. Installing basic Flask dependencies..."
    pip install flask flask-sqlalchemy python-dotenv boto3 bcrypt werkzeug psycopg2-binary requests
fi

echo "Virtual environment setup completed successfully!"
echo ""
echo "To activate the virtual environment manually, run:"
echo "source $VENV_NAME/bin/activate"
echo ""
echo "To deactivate when you're done, run:"
echo "deactivate"
echo ""
echo "Environment is currently activated. You can now:"
echo "1. Create your .env file with necessary environment variables"
echo "2. Run 'python3 test.py' to test connectivity"
echo "3. Run 'python3 app.py' to start the application"
