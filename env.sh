#!/bin/bash

# env.sh - Virtual environment setup script

echo "Setting up Python virtual environment..."

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Installing basic dependencies..."
    pip install flask flask-sqlalchemy python-dotenv boto3 bcrypt psycopg2-binary requests
fi

echo "Virtual environment setup completed!"
echo ""
echo "To activate the virtual environment manually, run:"
echo "source venv/bin/activate"
echo ""
echo "Next step: Configure your .env file and run python test.py"
