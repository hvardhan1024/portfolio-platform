#!/bin/bash

# create_env.sh: Script to create and set up a Python virtual environment for the Flask portfolio application

# Exit on any error
set -e

echo "=== Starting Python Virtual Environment Setup ==="

# Check if python3 and python3-venv are installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is not installed. Run 'sudo apt install python3 python3-venv' first."
    exit 1
fi
if ! command -v python3 -m venv &> /dev/null; then
    echo "❌ Error: python3-venv is not installed. Run 'sudo apt install python3-venv' first."
    exit 1
fi

# Define virtual environment directory
VENV_DIR="venv"

# Check if virtual environment already exists
if [ -d "$VENV_DIR" ]; then
    echo "⚠️ Virtual environment '$VENV_DIR' already exists. Removing and recreating..."
    rm -rf "$VENV_DIR"
fi

# Create virtual environment
echo "🐍 Creating virtual environment in $VENV_DIR..."
python3 -m venv "$VENV_DIR"

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Verify activation
if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ Error: Failed to activate virtual environment"
    exit 1
fi
echo "✅ Virtual environment activated: $VIRTUAL_ENV"

# Update pip in the virtual environment
echo "📦 Updating pip..."
pip install --upgrade pip

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found in the current directory"
    deactivate
    exit 1
fi

# Install Python dependencies from requirements.txt
echo "📦 Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt

# Verify Python dependencies
echo "🔍 Verifying Python dependencies..."
for pkg in Flask Flask-SQLAlchemy psycopg2-binary boto3 python-dotenv bcrypt; do
    if pip show "$pkg" > /dev/null; then
        echo "✅ $pkg is installed"
    else
        echo "❌ Error: $pkg installation failed"
        deactivate
        exit 1
    fi
done

# Deactivate virtual environment
echo "🔄 Deactivating virtual environment..."
deactivate

echo -e "\n=== Setup Summary ==="
echo "✅ Virtual environment created in $VENV_DIR"
echo "✅ Python dependencies installed"
echo "✅ Setup completed successfully!"
echo "To activate the virtual environment, run: source $VENV_DIR/bin/activate"
echo "Then, run 'python3 app.py' to start the Flask application"
