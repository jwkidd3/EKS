#!/bin/bash
# create-shared-user.sh - Create shared AWS user for student access

echo "Creating shared AWS user for student access..."

# Create IAM user for students
aws iam create-user --user-name eks-training-student

# Create access keys
KEYS=$(aws iam create-access-key --user-name eks-training-student --output text --query 'AccessKey.[AccessKeyId,SecretAccessKey]')
ACCESS_KEY=$(echo $KEYS | cut -d' ' -f1)
SECRET_KEY=$(echo $KEYS | cut -d' ' -f2)

echo "Created access keys:"
echo "AWS_ACCESS_KEY_ID: $ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY: $SECRET_KEY"

# Attach EKS policy to user
aws iam attach-user-policy --user-name eks-training-student --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-user-policy --user-name eks-training-student --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

# Get user ARN
USER_ARN=$(aws iam get-user --user-name eks-training-student --query 'User.Arn' --output text)

# Add this user to cluster with admin access
eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn "$USER_ARN" \
  --group system:masters \
  --username training-student

# Create simple setup script for students
cat << EOF > student-setup.sh
#!/bin/bash
# Student setup - run this in your Cloud9 environment

export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-2"

aws eks update-kubeconfig --region us-east-2 --name training-cluster
kubectl get nodes

echo "Setup complete! You now have access to the training cluster."
EOF

chmod +x student-setup.sh

echo ""
echo "Share the student-setup.sh file with all students"
echo "They just run: ./student-setup.sh"