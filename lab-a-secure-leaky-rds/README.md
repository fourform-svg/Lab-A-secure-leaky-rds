# Lab A - Operation Lockdown (STANDALONE)
Deploys: VPC, 2 private subnets, KMS CMK, Secrets Manager, Aurora PostgreSQL (private only), RDS Proxy IAM Auth
Deploy: terraform init && terraform apply -var="db_password=StrongP@ss123!"
Validation: public psql fails, IAM token via proxy succeeds.
Independent: YES - creates everything.
