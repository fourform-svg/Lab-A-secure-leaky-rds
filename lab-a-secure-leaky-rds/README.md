# Lab A project - "Operation Lockdown"- Remediate a Publicly Exposed RDS (used a fake company name for GitHub)
Deploys: VPC, 2 private subnets, KMS CMK, Secrets Manager, Aurora PostgreSQL (private only), RDS Proxy IAM Auth
Deploy: terraform init && terraform apply -var="db_password=StrongP@ss123!"
Validation: public psql fails; IAM token via proxy succeeds.
Independent: YES - creates everything.


USE CASE: Fintech startup "PayLekkiasap as a fake name) deployed Aurora PostgreSQL with public_access=true for debugging. Pen test flagged it. CTO asks me to remediate without downtime and implement zero hard-coded secrets + automatic rotation.

Business Problem: Public DB, static credentials in code, no encryption key ownership.

Design & Plan:

    VPC: Move DB to private subnets (10.0.2.0/24, 10.0.3.0/24) in 2 AZs. Detach IGW route from DB subnets. Only NAT for Lambda egress.
    Encryption: Create KMS CMK alias/rds/paylekki-prod with rotation enabled. Enable storage encryption + Performance Insights encryption.
    Secrets: Secrets Manager secret encrypted with same CMK. Lambda rotation function every 30 days.
    Access: No direct DB access. App -> RDS Proxy endpoint (IAM Auth enabled). Proxy IAM policy only allows rds-db:connect. Security Groups: App SG -> Proxy SG (5432), Proxy SG -> DB SG (5432) only.
    Compliance: Enable VPC Endpoints for Secrets Manager and KMS so rotation doesn't traverse the internet.


Execution Steps (Terraform):

1. KMS CMK
resource "aws_kms_key" "rds" { enable_key_rotation = true }
# 2. Secrets Manager + Rotation Lambda
resource "aws_secretsmanager_secret" "db" { kms_key_id = aws_kms_key.rds.id }
resource "aws_secretsmanager_secret_rotation" "db" { rotation_lambda_arn = aws_lambda_function.rotator.arn ... }
# 3. RDS Proxy with IAM Auth
resource "aws_db_proxy" "main" {
  auth { iam_auth = "REQUIRED" }
}
# 4. Aurora cluster publicly_accessible = false, storage_encrypted = true, kms_key_id = aws_kms_key.rds.id


Output and solution: Remediated publicly exposed Aurora PostgreSQL by re-architecting to private subnets, KMS CMK encryption, RDS Proxy with IAM authentication, and automated Secrets rotation, eliminating static credentials..
