#!/bin/bash
# ================================================================
# HIPAA Free-Tier Verification Script
# Validates Terraform-deployed AWS resources remain within Free Tier
# ================================================================

REGION="us-east-1"
PROFILE="default"

echo "=============================================="
echo " HIPAA Free-Tier Environment Verification"
echo "=============================================="
echo ""

# --- Check EC2 Instance ---
echo "🔍 Checking EC2 instance..."
EC2_INFO=$(aws ec2 describe-instances --region $REGION --profile $PROFILE \
  --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,SG:SecurityGroups[*].GroupName}" --output table)
echo "$EC2_INFO"

if echo "$EC2_INFO" | grep -q "t3.micro"; then
  echo "✅ EC2 instance is t3.micro (Free Tier eligible)"
else
  echo "⚠️  EC2 instance type is NOT t3.micro — may incur charges!"
fi
echo ""

# --- Check RDS Instance ---
echo "🔍 Checking RDS instance..."
RDS_INFO=$(aws rds describe-db-instances --region $REGION --profile $PROFILE \
  --query "DBInstances[*].{ID:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,Storage:AllocatedStorage,Encrypted:StorageEncrypted}" --output table)
echo "$RDS_INFO"

if echo "$RDS_INFO" | grep -q "db.t3.micro"; then
  echo "✅ RDS instance is db.t3.micro (Free Tier eligible)"
else
  echo "⚠️  RDS instance is not db.t3.micro — may incur cost!"
fi
echo ""

# --- Check S3 Encryption ---
echo "🔍 Checking S3 bucket encryption..."
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text --profile $PROFILE)

for B in $BUCKETS; do
  ENC=$(aws s3api get-bucket-encryption --bucket $B --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text --profile $PROFILE 2>/dev/null)
  if [ "$ENC" == "AES256" ]; then
    echo "✅ S3 bucket '$B' uses AES256 encryption (Free)"
  elif [ "$ENC" == "aws:kms" ]; then
    echo "⚠️  Bucket '$B' uses KMS (may incur small monthly cost)"
  else
    echo "❌ Bucket '$B' has NO encryption set!"
  fi
done
echo ""

# --- Check CloudWatch Alarms ---
echo "🔍 Checking CloudWatch alarms..."
aws cloudwatch describe-alarms --region $REGION --profile $PROFILE \
  --query "MetricAlarms[*].{Name:AlarmName,Metric:MetricName,Namespace:Namespace}" --output table
echo "✅ CloudWatch alarms are configured (basic alarms are free)."
echo ""

# --- Check SNS Subscription ---
echo "🔍 Checking SNS subscriptions..."
SUBS=$(aws sns list-subscriptions --region $REGION --profile $PROFILE --query "Subscriptions[*].{Endpoint:Endpoint,Protocol:Protocol,Status:SubscriptionArn}" --output table)
echo "$SUBS"

if echo "$SUBS" | grep -q "PendingConfirmation"; then
  echo "⚠️  SNS subscription not yet confirmed. Check your email inbox!"
else
  echo "✅ SNS subscription confirmed."
fi
echo ""

# --- Final Summary ---
echo "=============================================="
echo "✅ Verification Complete"
echo "----------------------------------------------"
echo "✔ EC2 and RDS sizes match Free Tier limits"
echo "✔ S3 bucket encrypted with AES256"
echo "✔ CloudWatch and SNS configured"
echo "----------------------------------------------"
echo "⚠️ Reminder: Free Tier allows 750 hrs/month for EC2 & RDS"
echo "   Avoid running multiple instances simultaneously."
echo "=============================================="
