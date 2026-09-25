# Lab A project - "Operation Lockdown"- Remediate a Publicly Exposed RDS
Deploys: VPC, 2 private subnets, KMS CMK, Secrets Manager, Aurora PostgreSQL (private only), RDS Proxy IAM Auth
Deploy: terraform init && terraform apply -var="db_password=StrongP@ss123!"
Validation: public psql fails; IAM token via proxy succeeds.
Independent: YES - creates everything.


USE CASE: Fintech startup "PayLekkiasap" deployed Aurora PostgreSQL with public_access=true for debugging. Pen test flagged it. CTO asks me to remediate without downtime and implement zero hard-coded secrets + automatic rotation.

Business Problem: Public DB, static credentials in code, no encryption key ownership.

Design & Plan:

    Enable Database Activity Streams (DAS) on Aurora - Kinesis encrypted with KMS.
    Enable GuardDuty RDS Protection -detects anomalous logins, brute force.
    CloudTrail for management plane (who modified RDS).
    Flow: DAS -> Kinesis Data Stream -> Kinesis Firehose -> S3 (Security Lake OCSF format) + CloudWatch Logs.
    EventBridge Rules:
    Rule 1: GuardDuty finding severity >7 -> Lambda -> SNS to SOC email.
    Rule 2: DAS event where type=READ and table=customers and rowCount>1000 -> SNS.
    Analytics: Security Lake + OpenSearch dashboard forensics.

Execution Steps:

    Deploy Lab A stack first (secure base).
    Enable aws rds start-activity-stream --mode async --kms-key-id xxx
    Create Kinesis -> Firehose -> Security Lake custom source.
    Lambda alert_handler.py: parses GuardDuty JSON, enriches with user identity, sends to SNS.
    Simulate attack: SELECT * FROM customers; from an unapproved IP; show alert in <2 mins.


Output and solution: Built real-time database auditing with Database Activity Streams, GuardDuty RDS Protection, and Security Lake, enabling automated anomaly detection and SOC alerting with < 2 min MTTD.
