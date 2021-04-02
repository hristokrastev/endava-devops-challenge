provider "aws" {
  region                  = "us-east-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.ekscluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.ekscluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eksauth.token
}

resource "aws_security_group" "hhk-sg" {
  name        = "hhk-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.rds_vpc_id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Service"
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Database"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "wordpress"
  }
}
resource "aws_security_group" "hhk-rds-sg" {
  name        = "hhk-rds-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.rds_vpc_id
  ingress {
    description = "Database"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "rds"
  }
}

resource "aws_db_instance" "hhk-rds-db" {
  allocated_storage          = 20
  max_allocated_storage      = 40
  storage_type               = "gp2"
  engine                     = "mysql"
  engine_version             = "5.7"
  instance_class             = "db.t2.micro"
  name                       = "mydb"
  username                   = var.username
  password                   = var.password
  parameter_group_name       = "default.mysql5.7"
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true
  vpc_security_group_ids     = [aws_security_group.hhk-rds-sg.id]
  publicly_accessible        = true
  port                       = 3306
}


resource "aws_iam_role" "IAM-hhk" {
  name               = "hhk-eks-cluster"
  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
"Service": "eks.amazonaws.com",
"Service": "ec2.amazonaws.com"
},
"Action": "sts:AssumeRole"
}
]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "Cluster-Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.IAM-hhk.name
}

resource "aws_iam_role_policy_attachment" "WorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.IAM-hhk.name
}

resource "aws_iam_role_policy_attachment" "EKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.IAM-hhk.name
}

resource "aws_iam_role_policy_attachment" "EC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.IAM-hhk.name
}

resource "aws_eks_cluster" "ekscluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.IAM-hhk.arn
  vpc_config {
    subnet_ids         = ["subnet-0da84b70", "subnet-407f340c"]
    security_group_ids = [aws_security_group.hhk-sg.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.Cluster-Policy,
  ]
  tags = {
    "Name" = " EKS-CLUSTER"
  }
}

resource "aws_eks_node_group" "eks-ng" {
  cluster_name    = aws_eks_cluster.ekscluster.name
  node_group_name = "hhk"
  node_role_arn   = aws_iam_role.IAM-hhk.arn
  subnet_ids      = ["subnet-0da84b70", "subnet-407f340c"]
  instance_types  = ["t2.micro"]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
  depends_on = [
    aws_iam_role_policy_attachment.WorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly,
  ]
}

data "aws_eks_cluster_auth" "eksauth" {
  name = aws_eks_cluster.ekscluster.name
}

resource "kubernetes_service" "hhkkubeservice" {
  metadata {
    name = "wordpress"
    labels = {
      "app" = "wordpress"
    }
  }
  spec {
    selector = {
      "app"  = "wordpress"
      "tier" = "frontend"
    }
    port {
      port      = 80
      node_port = 30001
    }
    type = "LoadBalancer"
  }
  depends_on = [aws_eks_node_group.eks-ng]
  timeouts {
    create = "15m"
  }
}

resource "kubernetes_persistent_volume_claim" "kubepvc" {
  metadata {
    name = "wordpress-pv-claim"
    labels = {
      "app" = "wordpress"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  depends_on = [aws_eks_node_group.eks-ng]
  timeouts {
    create = "15m"
  }
}

resource "kubernetes_deployment" "hhk-kube" {
  metadata {
    name = "wordpress"
    labels = {
      "app" = "wordpress"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app"  = "wordpress"
        "tier" = "frontend"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          "app"  = "wordpress"
          "tier" = "frontend"
        }
      }
      spec {
        container {
          image = "wordpress"
          name  = "wordpress"
          env {
            name  = "WORDPRESS_DB_NAME"
            value = aws_db_instance.hhk-rds-db.name
          }
          env {
            name  = "WORDPRESS_DB_HOST"
            value = aws_db_instance.hhk-rds-db.endpoint
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = aws_db_instance.hhk-rds-db.username
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = aws_db_instance.hhk-rds-db.password
          }
          port {
            container_port = 80
            name           = "wordpress"
          }
          volume_mount {
            name       = "wordpress-ps"
            mount_path = "/var/www/html"
          }
        }
        volume {
          name = "wordpress-ps"
          persistent_volume_claim {
            claim_name = "wordpress-pv-claim"
          }
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.eks-ng]
  timeouts {
    create = "30m"
  }
}