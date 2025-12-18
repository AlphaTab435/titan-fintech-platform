# 1. IAM Role for the EKS Cluster (Control Plane)
# Allows EKS to manage AWS resources on your behalf
resource "aws_iam_role" "eks_cluster" {
  name = "titan-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

# Attach required policies to the Control Plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# 2. The EKS Cluster (The Mastermind)
resource "aws_eks_cluster" "main" {
  name     = "titan-fintech-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # It needs to know which Subnets to live in
    subnet_ids = [
      var.public_subnet_id, 
      var.private_subnet_id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# 3. IAM Role for Worker Nodes (The Workers)
resource "aws_iam_role" "eks_nodes" {
  name = "titan-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach policies so Nodes can talk to EKS and pull Docker images
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# 4. Node Group (The EC2 Instances)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "titan-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [var.private_subnet_id] # Workers live in PRIVATE subnet

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"] # Standard for EKS

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}