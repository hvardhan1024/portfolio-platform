# AWS Deployment Guide - Flask Portfolio App

<img width="1141" height="798" alt="image" src="https://github.com/user-attachments/assets/edf98cdf-b300-4d47-8747-55e6afc30a20" />


## Introduction

This project is a Flask-based web application that allows users to create and manage their portfolios. Users can register, login, upload profile images and resumes, and showcase their projects. The application demonstrates the integration of multiple AWS services in a cloud-based architecture.

**Project Features:**
- User registration and authentication
- Profile management with file uploads
- Portfolio showcase functionality
- Responsive web design

## AWS Technologies Used

1. **Amazon EC2** - Virtual server for hosting the Flask application
2. **Amazon RDS (PostgreSQL)** - Managed relational database for storing user data
3. **Amazon S3** - Object storage for profile images and resume files
4. **IAM** - Identity and Access Management for secure AWS access

## Setup Steps

### 1. Create IAM User and Access Keys

**Step 1:** Login to AWS Console
- Go to https://aws.amazon.com
- Click "Sign In to the Console"
- Enter your AWS account credentials

**Step 2:** Navigate to IAM
- In AWS Console, search for "IAM" in the services search bar
- Click on "IAM" service

**Step 3:** Create New User
- Click "Users" in left sidebar
- Click "Create user" button
- Enter username: `flask-app-user`
- Select "Provide user access to the AWS Management Console" if you want console access
- Click "Next"

**Step 4:** Set Permissions
- Select "Attach policies directly"
- Search and select these policies:
  - `AmazonS3FullAccess`
  - `AmazonRDSFullAccess`
  - `AmazonEC2FullAccess`
- Click "Next" then "Create user"

**Step 5:** Create Access Keys
- Click on the created user
- Go to "Security credentials" tab
- Click "Create access key"
- Select "Application running outside AWS"
- Click "Next" and then "Create access key"
- **IMPORTANT:** Copy the Access Key ID and Secret Access Key - you won't see them again!

### 2. Create RDS PostgreSQL Database

**Step 1:** Navigate to RDS
- In AWS Console, search for "RDS"
- Click on "RDS" service

**Step 2:** Create Database
- Click "Create database"
- Select "Standard Create"
- Choose "PostgreSQL" as engine type

**Step 3:** Database Configuration
- Engine Version: Keep default (latest)
- Templates: Select "Free tier"
- DB Instance Identifier: `flask-portfolio-db`
- Master username: `postgres`
- Master password: `postgres`
- Confirm password: `postgres`

**Step 4:** Instance Configuration
- DB Instance Class: `db.t3.micro` (free tier eligible)
- Storage Type: General Purpose SSD (gp2)
- Allocated storage: 20 GB (free tier)

**Step 5:** Connectivity Settings
- Virtual Private Cloud (VPC): Default VPC
- Public access: **Yes** (important for external access)
- VPC Security group: Create new
- Security group name: `rds-flask-sg`

**Step 6:** Database Authentication
- Keep default settings
- Initial database name: `postgres`

**Step 7:** Create Database
- Click "Create database"
- Wait for status to change to "Available" (takes 5-10 minutes)
- Note down the endpoint URL from the database details

### 3. Create S3 Bucket

**Step 1:** Navigate to S3
- In AWS Console, search for "S3"
- Click on "S3" service

**Step 2:** Create Bucket
- Click "Create bucket"
- Bucket name: `flask-portfolio-bucket-yourname123` (must be globally unique)
- Region: Asia Pacific (Mumbai) ap-south-1

**Step 3:** Configure Settings
- Object Ownership: ACLs enabled, Bucket owner preferred
- **Uncheck "Block all public access"** (important for file uploads)
- Check the acknowledgment box
- Keep other settings as default

**Step 4:** Create Bucket
- Click "Create bucket"

### 4. Create EC2 Instance

**Step 1:** Navigate to EC2
- In AWS Console, search for "EC2"
- Click on "EC2" service

**Step 2:** Launch Instance
- Click "Launch instance"
- Name: `flask-portfolio-server`

**Step 3:** Choose AMI
- Select "Ubuntu Server 22.04 LTS (HVM), SSD Volume Type"
- Architecture: 64-bit (x86)

**Step 4:** Choose Instance Type
- Select "t2.micro" (free tier eligible)

**Step 5:** Create Key Pair
- Click "Create new key pair"
- Key pair name: `flask-app-key`
- Key pair type: RSA
- Private key file format: .pem
- Click "Create key pair" and download the file

**Step 6:** Network Settings
- Create security group: `flask-app-sg`
- Description: Security group for Flask app
- Add these rules:
  - SSH (port 22): Source: My IP
  - HTTP (port 80): Source: Anywhere
  - Custom TCP (port 5000): Source: Anywhere

**Step 7:** Configure Storage
- Size: 8 GB (free tier)
- Volume type: gp2

**Step 8:** Launch Instance
- Click "Launch instance"
- Wait for instance state to be "Running"

### 5. Configure Security Groups for RDS

**Step 1:** Go to RDS Security Group
- In EC2 console, click "Security Groups"
- Find the RDS security group (`rds-flask-sg`)
- Click "Edit inbound rules"

**Step 2:** Add Rule
- Type: PostgreSQL
- Port: 5432
- Source: Custom (enter your EC2 security group ID or use 0.0.0.0/0 for simplicity)
- Click "Save rules"

### 6. Connect to EC2 Instance

**Step 1:** Get Connection Details
- In EC2 console, select your instance
- Click "Connect"
- Note the public DNS name

**Step 2:** Connect via SSH (Linux/Mac)
```bash
chmod 400 flask-app-key.pem
ssh -i "flask-app-key.pem" ubuntu@your-ec2-public-dns
```

**Step 3:** Connect via SSH (Windows)
- Use PuTTY or Windows Subsystem for Linux
- Convert .pem to .ppk if using PuTTY

### 7. Setup Application on EC2

**Step 1:** Update System and Clone Repository
```bash
# Update system
sudo apt update -y

# Clone your repository (replace with your repo URL)
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Make scripts executable
chmod +x update.sh env.sh
```

**Step 2:** Run Setup Scripts
```bash
# Install system dependencies
./update.sh

# Setup Python environment
./env.sh

# Activate virtual environment
source venv/bin/activate
```

**Step 3:** Configure Environment Variables
```bash
# Create .env file
nano .env
```

Add the following content (replace with your actual values):
```env
SECRET_KEY=your-super-secret-key-here
FLASK_DEBUG=False
PORT=5000

AWS_ACCESS_KEY_ID=your-access-key-id-here
AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
AWS_REGION=ap-south-1
S3_BUCKET=your-bucket-name-here

DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=postgres

UPLOAD_MAX_SIZE=16777216
```

**Step 4:** Test Connectivity
```bash
# Test AWS services connectivity
python test.py
```

**Step 5:** Run the Application
```bash
# Start the Flask application
python app.py
```

### 8. Access Your Application

**Step 1:** Get Public IP
- In EC2 console, copy your instance's public IP address

**Step 2:** Access via Browser
- Open browser and go to: `http://your-ec2-public-ip:5000`
- You should see your Flask application running

**Step 3:** Test Health Check
- Visit: `http://your-ec2-public-ip:5000/health`
- This will show the status of all AWS services

## Troubleshooting Common Issues

1. **RDS Connection Failed**
   - Check security group allows port 5432 from your EC2
   - Verify RDS endpoint URL is correct
   - Ensure RDS is in "Available" state

2. **S3 Access Denied**
   - Check bucket policy allows public read access
   - Verify IAM user has S3 permissions
   - Ensure access keys are correct

3. **Application Not Accessible**
   - Check EC2 security group allows port 5000
   - Verify Flask app is running on 0.0.0.0:5000
   - Check if any firewall is blocking the port

## Cost Optimization Tips

1. **Stop EC2 when not needed** - Charges apply only when running
2. **Use RDS free tier** - 750 hours per month free
3. **Monitor S3 usage** - First 5GB free per month
4. **Delete resources after testing** - Avoid unnecessary charges

## Testing the Application

### 1. Register a New User
- Go to `/register` endpoint
- Create a new account with email and password
- System will hash password and store in RDS

### 2. Login and Create Profile
- Login with your credentials
- Access dashboard to update your profile
- Add bio, GitHub URL, LinkedIn URL, and projects
- Upload profile image and resume (stored in S3)

### 3. View Portfolio
- Visit `/portfolio/your-email` to see your public portfolio
- Images and files are served from S3

### 4. Health Check
- Visit `/health` endpoint to verify all services are working
- Should show green status for RDS, S3, and EC2

## Security Considerations

1. **Environment Variables**
   - Never commit `.env` file to version control
   - Use strong, unique passwords
   - Rotate access keys regularly

2. **Database Security**
   - Use strong master password
   - Enable encryption at rest (for production)
   - Restrict security group access

3. **S3 Security**
   - Configure bucket policies appropriately
   - Enable versioning for important data
   - Monitor access logs

## Production Deployment Recommendations

1. **Use Application Load Balancer** - For high availability
2. **Enable RDS Multi-AZ** - For database failover
3. **Use CloudFront** - For S3 content delivery
4. **Implement Auto Scaling** - For variable load handling
5. **Use Secrets Manager** - For secure credential management
6. **Enable CloudWatch** - For monitoring and logging

## Cleanup Instructions (After Testing)

To avoid ongoing charges, delete resources in this order:

1. **Terminate EC2 Instance**
   - EC2 Console → Instances → Select instance → Instance State → Terminate

2. **Delete RDS Database**
   - RDS Console → Databases → Select database → Actions → Delete
   - Uncheck "Create final snapshot" for testing

3. **Empty and Delete S3 Bucket**
   - S3 Console → Select bucket → Empty bucket → Delete bucket

4. **Delete IAM User**
   - IAM Console → Users → Select user → Delete

5. **Delete Security Groups**
   - EC2 Console → Security Groups → Delete custom security groups

## Conclusion

This deployment demonstrates a complete full-stack application using core AWS services. The architecture showcases:

- **Scalable compute** with EC2
- **Managed database** with RDS PostgreSQL
- **Object storage** with S3
- **Security management** with IAM

The application successfully integrates these services to provide a functional portfolio management system. Users can register, create profiles, upload files, and showcase their work - all while leveraging AWS cloud infrastructure for reliability and scalability.

## Expected Output

Upon successful deployment, you should see:

1. **Flask Application Running** - Accessible via EC2 public IP on port 5000
2. **User Registration/Login** - Working authentication system
3. **File Uploads** - Images and resumes stored in S3
4. **Database Operations** - User data stored in RDS PostgreSQL
5. **Health Check Page** - Showing all services as operational

The application demonstrates practical cloud computing concepts and AWS service integration, making it an excellent learning project for cloud deployment and DevOps practices.
