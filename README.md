# 🚀 AWS Infrastructure Automation – Cloud Deployment with SNS, S3, EC2, and RDS

This project demonstrates the automation of a full-stack cloud-native application environment using AWS CLI, Shell scripts, and Python (Boto3 SDK). It showcases the creation and teardown of a multi-resource AWS environment along with automated testing (grading) scripts.

---

## 🔧 Technologies & Tools

- **AWS CLI & Services**: EC2, RDS, S3, SNS, ELB, IAM
- **Shell Scripting**: Environment setup, deployment, teardown
- **Python Boto3 SDK**: Validation and grading automation
- **Node.js / NPM**: SNS integration through app logic
- **Auto-scaling & Load Balancing**
- **PM2**: Node process manager (for app resilience)

---

## 📁 Files Included

- `create-env.sh` – Creates EC2 instances, S3 buckets, SNS topic, RDS, ELB
- `destroy-env.sh` – Cleans up all created AWS resources
- `install-env.sh` – Provisions instances with app dependencies and SNS integration
- `check-env-setup.py` – Validates environment setup and returns a score out of 5
- `check-env-cleanup.py` – Ensures cleanup by validating deletion of all resources

---

## ✅ Project Highlights

- Created and validated AWS SNS topic
- Provisioned ELB, RDS, and S3 buckets
- Integrated JavaScript SDK for SNS notifications
- Built auto-grading logic to verify resource status and scoring
- Automated cloud resource destruction (clean exit)

---

## ⚠️ Notes

This project does **not include AWS screenshots or the live deployment**, but all scripts and logic are provided to replicate the infrastructure in any AWS account (with valid IAM permissions).

---
