# 30 Viva Questions - Flask AWS Portfolio Project

## Section A: Cloud Computing Fundamentals (Questions 1-10)

**1. What is cloud computing and what are its main characteristics?**
*Answer: Cloud computing is the delivery of computing services over the internet. Main characteristics include: On-demand self-service, broad network access, resource pooling, rapid elasticity, and measured service.*

**2. Explain the difference between IaaS, PaaS, and SaaS with examples.**
*Answer: IaaS (Infrastructure as a Service) - EC2, virtual machines; PaaS (Platform as a Service) - AWS Elastic Beanstalk, Google App Engine; SaaS (Software as a Service) - Gmail, Office 365.*

**3. What are the key benefits of cloud computing for businesses?**
*Answer: Cost reduction, scalability, flexibility, automatic updates, disaster recovery, global accessibility, reduced IT maintenance, and faster deployment.*

**4. What is the difference between public, private, and hybrid clouds?**
*Answer: Public cloud - shared infrastructure (AWS, Azure); Private cloud - dedicated infrastructure for one organization; Hybrid cloud - combination of public and private clouds.*

**5. Explain the concept of elasticity in cloud computing.**
*Answer: Elasticity is the ability to automatically scale resources up or down based on demand, ensuring optimal performance while controlling costs.*

**6. What are the main concerns businesses have when migrating to the cloud?**
*Answer: Security concerns, data privacy, compliance issues, vendor lock-in, internet dependency, and potential downtime during migration.*

**7. How does cloud computing support disaster recovery?**
*Answer: Cloud provides geographically distributed backups, automated backup processes, quick restore capabilities, and redundant infrastructure to ensure business continuity.*

**8. What is the pay-as-you-use model in cloud computing?**
*Answer: A pricing model where customers pay only for the resources they actually consume, similar to utility billing, eliminating upfront capital expenses.*

**9. Explain the concept of multi-tenancy in cloud computing.**
*Answer: Multiple customers sharing the same physical infrastructure while maintaining data isolation and security, maximizing resource utilization.*

**10. What are the different cloud deployment models?**
*Answer: Public cloud (shared resources), private cloud (dedicated resources), hybrid cloud (mix of public/private), and community cloud (shared by specific community).*

## Section B: AWS Core Services and Concepts (Questions 11-20)

**11. What is a VPC in AWS and why is it important?**
*Answer: Virtual Private Cloud - a logically isolated section of AWS cloud where you can launch resources in a virtual network that you define, providing security and control.*

**12. Explain the difference between public and private subnets in AWS.**
*Answer: Public subnets have internet gateway access for internet connectivity; private subnets don't have direct internet access and typically use NAT gateways for outbound traffic.*

**13. What is an Internet Gateway and how does it work?**
*Answer: A horizontally scaled, redundant, and highly available VPC component that allows communication between instances in your VPC and the internet.*

**14. Explain AWS Availability Zones and Regions.**
*Answer: Regions are geographic areas with multiple AZs; Availability Zones are isolated data centers within a region, providing fault tolerance and low latency.*

**15. What is the difference between Security Groups and NACLs in AWS?**
*Answer: Security Groups are stateful firewalls at instance level (allow rules only); NACLs are stateless firewalls at subnet level (allow/deny rules).*

**16. Explain the concept of AWS IAM and its components.**
*Answer: Identity and Access Management - manages users, groups, roles, and policies to control access to AWS resources securely. Components: Users, Groups, Roles, Policies.*

**17. What is the AWS Free Tier and what are its limitations?**
*Answer: Free usage tier for new AWS accounts, offering limited free usage of various services for 12 months, with specific limits on compute, storage, and data transfer.*

**18. Explain the difference between EBS and Instance Store in EC2.**
*Answer: EBS (Elastic Block Store) - persistent, network-attached storage; Instance Store - temporary storage physically attached to the host computer.*

**19. What is Auto Scaling in AWS and why is it used?**
*Answer: Automatically adjusts the number of EC2 instances based on demand, ensuring application availability and cost optimization by scaling up/down as needed.*

**20. Explain the concept of Load Balancing in AWS.**
*Answer: Distributes incoming traffic across multiple targets (EC2 instances) to ensure high availability, fault tolerance, and optimal resource utilization.*

## Section C: Project-Specific Questions (Questions 21-30)

**21. Why did you choose EC2, RDS, and S3 for this portfolio application?**
*Answer: EC2 for scalable compute hosting Flask app, RDS for managed PostgreSQL database with automatic backups, S3 for cost-effective object storage for images/resumes.*

**22. Explain how file uploads work in your application.**
*Answer: Users upload files through Flask forms, files are processed using secure_filename(), uploaded to S3 using boto3 client, and URLs are stored in RDS database.*

**23. What security measures have you implemented in your Flask application?**
*Answer: Password hashing using bcrypt, secure file uploads, session management, SQL injection protection with SQLAlchemy, and AWS IAM for service access.*

**24. How does your application connect to the RDS database?**
*Answer: Using psycopg2-binary driver with SQLAlchemy ORM, connection string built from environment variables (host, port, username, password, database name).*

**25. Explain the purpose of your test.py script.**
*Answer: Validates connectivity to AWS services (RDS and S3), checks environment variables, tests database queries, and verifies S3 bucket access before running the main application.*

**26. What happens when a user registers in your application?**
*Answer: System validates email uniqueness, hashes password with bcrypt, creates User record in RDS database, and redirects to login page with success message.*

**27. How do you handle environment variables in your project?**
*Answer: Using python-dotenv to load variables from .env file, separating database credentials, AWS keys, and app configuration for security and flexibility.*

**28. Explain the database schema used in your project.**
*Answer: Two tables - Users (id, email, hashed password, created_at) and Profiles (user_id foreign key, bio, URLs, projects, file URLs, updated_at).*

**29. What would you do to make this application production-ready?**
*Answer: Add HTTPS, implement proper logging, use Application Load Balancer, enable RDS Multi-AZ, add CloudFront for S3, implement monitoring with CloudWatch.*

**30. How would you handle high traffic and scaling for this application?**
*Answer: Implement Auto Scaling Groups for EC2, use RDS read replicas, implement caching (Redis/ElastiCache), use CDN for static content, and horizontal scaling with load balancers.*

## Additional Tips for Viva Preparation:

1. **Understand the Architecture**: Be able to draw and explain the complete application architecture
2. **Know the AWS Services**: Understand why each service was chosen and its alternatives
3. **Security Focus**: Be prepared to discuss security best practices and implementations
4. **Cost Optimization**: Understand free tier limits and cost optimization strategies
5. **Troubleshooting**: Be ready to explain how to debug common issues
6. **Scalability**: Discuss how the application can be scaled for production use

## Common Follow-up Questions:
- "What if S3 bucket is not accessible?"
- "How would you monitor this application?"
- "What are the costs involved in running this setup?"
- "How would you implement CI/CD for this project?"
- "What other AWS services could enhance this application?"
