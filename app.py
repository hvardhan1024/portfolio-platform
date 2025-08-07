from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_sqlalchemy import SQLAlchemy
from werkzeug.utils import secure_filename
import boto3
from botocore.exceptions import ClientError
import os
from dotenv import load_dotenv
from datetime import datetime
from sqlalchemy import text
import bcrypt

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

# Build database URI from separate components
db_host = os.getenv('DB_HOST')
db_port = os.getenv('DB_PORT', '5432')
db_user = os.getenv('DB_USER')
db_password = os.getenv('DB_PASSWORD')
db_name = os.getenv('DB_NAME')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('UPLOAD_MAX_SIZE', 16777216))

db = SQLAlchemy(app)

# S3 client initialization
try:
    aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
    aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
    aws_region = os.getenv('AWS_REGION')
    s3_bucket = os.getenv('S3_BUCKET')

    if aws_access_key_id and aws_secret_access_key:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name=aws_region
        )
        print("S3 client initialized with explicit credentials")
    else:
        s3_client = boto3.client('s3', region_name=aws_region)
        print("S3 client initialized with IAM role")
except Exception as e:
    print(f"Warning: Failed to initialize S3 client: {e}")
    s3_client = None

# Models
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)  # Hashed password
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    profile = db.relationship('Profile', backref='user', uselist=False, cascade='all, delete-orphan')

class Profile(db.Model):
    __tablename__ = 'profiles'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    bio = db.Column(db.Text)
    github_url = db.Column(db.String(200))
    linkedin_url = db.Column(db.String(200))
    projects = db.Column(db.Text)
    image_url = db.Column(db.String(500))
    resume_url = db.Column(db.String(500))
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Helper function to upload files to S3
def upload_to_s3(file, folder):
    if not file or not s3_client:
        flash('S3 client not initialized or no file provided')
        return None

    try:
        timestamp = int(datetime.utcnow().timestamp())
        filename = secure_filename(file.filename)
        s3_key = f"{folder}/{session['user_id']}_{timestamp}_{filename}"

        s3_client.upload_fileobj(
            file,
            s3_bucket,
            s3_key,
            ExtraArgs={'ACL': 'public-read', 'ContentType': file.content_type}
        )
        return f"https://{s3_bucket}.s3.{aws_region}.amazonaws.com/{s3_key}"
    except ClientError as e:
        flash(f"S3 upload failed: {e.response['Error']['Message']}")
        return None
    except Exception as e:
        flash(f"S3 upload error: {str(e)}")
        return None

# Routes
@app.route('/')
def index():
    try:
        users_with_profiles = db.session.query(User).join(Profile).all()
    except Exception as e:
        flash(f"Database query error: {str(e)}")
        users_with_profiles = []
    return render_template('index.html', users=users_with_profiles)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            flash('Email already registered')
            return render_template('register.html')

        # Hash password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        user = User(email=email, password=hashed_password)

        try:
            db.session.add(user)
            db.session.commit()
            flash('Registration successful! Please login.')
            return redirect(url_for('login'))
        except Exception as e:
            db.session.rollback()
            flash(f"Registration failed: {str(e)}")

    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        user = User.query.filter_by(email=email).first()
        if user and bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            session['user_id'] = user.id
            session['user_email'] = user.email
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid email or password')

    return render_template('login.html')

@app.route('/dashboard', methods=['GET', 'POST'])
def dashboard():
    if 'user_id' not in session:
        flash('Please login to access the dashboard')
        return redirect(url_for('login'))

    user = User.query.get(session['user_id'])
    profile = Profile.query.filter_by(user_id=session['user_id']).first()

    if request.method == 'POST':
        bio = request.form.get('bio', '')
        github_url = request.form.get('github_url', '')
        linkedin_url = request.form.get('linkedin_url', '')
        projects = request.form.get('projects', '')

        image_url = profile.image_url if profile else None
        resume_url = profile.resume_url if profile else None

        if 'image' in request.files and request.files['image'].filename:
            image_url = upload_to_s3(request.files['image'], 'images')
            if not image_url:
                return redirect(url_for('dashboard'))

        if 'resume' in request.files and request.files['resume'].filename:
            resume_url = upload_to_s3(request.files['resume'], 'resumes')
            if not resume_url:
                return redirect(url_for('dashboard'))

        try:
            if profile:
                profile.bio = bio
                profile.github_url = github_url
                profile.linkedin_url = linkedin_url
                profile.projects = projects
                if image_url:
                    profile.image_url = image_url
                if resume_url:
                    profile.resume_url = resume_url
                profile.updated_at = datetime.utcnow()
            else:
                profile = Profile(
                    user_id=session['user_id'],
                    bio=bio,
                    github_url=github_url,
                    linkedin_url=linkedin_url,
                    projects=projects,
                    image_url=image_url,
                    resume_url=resume_url
                )
                db.session.add(profile)

            db.session.commit()
            flash('Profile updated successfully!')
        except Exception as e:
            db.session.rollback()
            flash(f"Profile update failed: {str(e)}")

        return redirect(url_for('dashboard'))

    return render_template('dashboard.html', user=user, profile=profile)

@app.route('/portfolio/<email>')
def portfolio(email):
    user = User.query.filter_by(email=email).first()
    if not user:
        flash('Portfolio not found')
        return redirect(url_for('index'))

    profile = Profile.query.filter_by(user_id=user.id).first()
    if not profile:
        flash('Portfolio not found')
        return redirect(url_for('index'))

    projects_list = [p.strip() for p in profile.projects.split(',') if p.strip()] if profile.projects else []

    return render_template('portfolio.html', user=user, profile=profile, projects=projects_list)

@app.route('/logout', methods=['POST'])
def logout():
    session.clear()
    flash('Logged out successfully')
    return redirect(url_for('index'))

@app.route('/health')
def health_check():
    results = {}

    try:
        db.session.execute(text("SELECT 1"))
        db.session.commit()
        results['rds'] = 'RDS is connected and responsive.'
    except Exception as e:
        results['rds'] = f'RDS check failed: {str(e)}'

    try:
        if not s3_client:
            results['s3'] = "S3 client not initialized"
        elif not s3_bucket:
            results['s3'] = "S3 bucket name not configured"
        else:
            s3_client.list_objects_v2(Bucket=s3_bucket, MaxKeys=1)
            results['s3'] = f"S3 bucket '{s3_bucket}' is accessible."
    except ClientError as e:
        results['s3'] = f"S3 access failed: {e.response['Error']['Message']}"
    except Exception as e:
        results['s3'] = f"S3 access failed: {str(e)}"

    try:
        import requests
        instance_id = requests.get("http://169.254.169.254/latest/meta-data/instance-id", timeout=2).text
        az = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone", timeout=2).text
        public_ip = requests.get("http://169.254.169.254/latest/meta-data/public-ipv4", timeout=2).text
        results['ec2'] = f"EC2 instance running (ID: {instance_id}, AZ: {az}, Public IP: {public_ip})"
    except Exception as e:
        results['ec2'] = f"EC2 metadata access failed: {str(e)}"

    print("\n--- Health Check Summary ---")
    for service, status in results.items():
        print(f"{service.upper()}: {status}")

    return "<br>".join(f"<strong>{key.upper()}</strong>: {value}" for key, value in results.items())

# Create tables
with app.app_context():
    try:
        db.create_all()
        print("Database tables created successfully")
    except Exception as e:
        print(f"Failed to create database tables: {e}")

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true')
