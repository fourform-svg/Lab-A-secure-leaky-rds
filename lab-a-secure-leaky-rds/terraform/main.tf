
provider "aws" { region = var.region }
resource "aws_vpc" "main" { cidr_block = "10.0.0.0/16" tags = { Name = "lab-a-vpc" } }
resource "aws_subnet" "private_a" { vpc_id = aws_vpc.main.id cidr_block = "10.0.2.0/24" availability_zone = "${var.region}a" }
resource "aws_subnet" "private_b" { vpc_id = aws_vpc.main.id cidr_block = "10.0.3.0/24" availability_zone = "${var.region}b" }
resource "aws_kms_key" "rds" { description = "Lab A CMK" enable_key_rotation = true }
resource "aws_kms_alias" "rds" { name = "alias/rds/lab-a-secure" target_key_id = aws_kms_key.rds.id }
resource "aws_secretsmanager_secret" "db" { name = "lab-a/rds/credentials" kms_key_id = aws_kms_key.rds.id }
resource "aws_secretsmanager_secret_version" "db" { secret_id = aws_secretsmanager_secret.db.id secret_string = jsonencode({username="dbadmin", password=var.db_password}) }
resource "aws_security_group" "db" { vpc_id = aws_vpc.main.id name = "lab-a-db-sg" ingress { from_port=5432 to_port=5432 protocol="tcp" security_groups=[aws_security_group.proxy.id] } egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] } }
resource "aws_security_group" "proxy" { vpc_id = aws_vpc.main.id name = "lab-a-proxy-sg" ingress { from_port=5432 to_port=5432 protocol="tcp" cidr_blocks=["10.0.0.0/16"] } egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] } }
resource "aws_db_subnet_group" "main" { name = "lab-a-subnet-group" subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
resource "aws_rds_cluster" "aurora" { cluster_identifier="lab-a-aurora" engine="aurora-postgresql" engine_version="15.4" master_username="dbadmin" master_password=var.db_password database_name="labadb" db_subnet_group_name=aws_db_subnet_group.main.name vpc_security_group_ids=[aws_security_group.db.id] storage_encrypted=true kms_key_id=aws_kms_key.rds.id skip_final_snapshot=true }
resource "aws_rds_cluster_instance" "inst" { count=1 identifier="lab-a-aurora-${count.index}" cluster_identifier=aws_rds_cluster.aurora.id instance_class="db.t3.medium" engine=aws_rds_cluster.aurora.engine publicly_accessible=false performance_insights_enabled=true performance_insights_kms_key_id=aws_kms_key.rds.id }
resource "aws_db_proxy" "main" { name="lab-a-proxy" engine_family="POSTGRESQL" role_arn=aws_iam_role.proxy.arn vpc_subnet_ids=[aws_subnet.private_a.id, aws_subnet.private_b.id] vpc_security_group_ids=[aws_security_group.proxy.id] auth { auth_scheme="SECRETS" iam_auth="REQUIRED" secret_arn=aws_secretsmanager_secret.db.arn } }
resource "aws_iam_role" "proxy" { name="lab-a-proxy-role" assume_role_policy=jsonencode({Version="2012-10-17", Statement=[{Action="sts:AssumeRole", Effect="Allow", Principal={Service="rds.amazonaws.com"}}]}) }
resource "aws_iam_role_policy" "proxy" { role=aws_iam_role.proxy.id policy=jsonencode({Version="2012-10-17", Statement=[{Effect="Allow", Action=["secretsmanager:GetSecretValue"], Resource=aws_secretsmanager_secret.db.arn}, {Effect="Allow", Action=["kms:Decrypt"], Resource=aws_kms_key.rds.arn}]}) }
output "proxy_endpoint" { value=aws_db_proxy.main.endpoint }
