# Centralized Security Services – 100% working version (Dec 2025)

data "aws_organizations_organization" "org" {}
data "aws_caller_identity" "current" {}

# ==================== IAM Identity Center (org-wide SSO) ====================
data "aws_ssoadmin_instances" "sso" {}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  instance_arn     = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  session_duration = "PT12H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_identitystore_group" "org_admins" {
  display_name      = "org-admins"
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}

resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = toset([
    data.aws_caller_identity.current.account_id,   # management
    "945219712532"                                 # ← your security account ID
  ])

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

# ==================== GuardDuty & Security Hub Delegation ====================
resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = "945219712532"
}

resource "aws_securityhub_organization_admin_account" "security" {
  admin_account_id = "945219712532"
}

# ==================== Amazon Security Lake (org-wide) ====================
resource "aws_securitylake_data_lake" "org" {
  configuration {
    region = "us-east-1"
  }
  meta_store_manager_role_arn = aws_iam_role.securitylake.arn
}

resource "aws_iam_role" "securitylake" {
  name = "AWSServiceRoleForAmazonSecurityLake"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "securitylake.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Enable a few common sources (you can add more later)
resource "aws_securitylake_aws_log_source" "route53" {
  source {
    accounts    = ["837844956087", "314969690319", "945219712532", "986778210305", "253627981974"]
    regions     = ["us-east-1"]
    source_name = "ROUTE53"
  }
}

resource "aws_securitylake_aws_log_source" "vpcflow" {
  source {
    accounts    = ["837844956087", "314969690319", "945219712532", "986778210305", "253627981974"]
    regions     = ["us-east-1"]
    source_name = "VPC_FLOW"
  }
}

# ==================== Outputs ====================
output "sso_instance_arn" {
  value = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}

output "security_lake_arn" {
  value = aws_securitylake_data_lake.org.arn
}