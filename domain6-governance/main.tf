# Read existing organization
data "aws_organizations_organization" "main" {}

# 15-second sleep so the brand-new org is fully visible
resource "time_sleep" "wait_15_seconds" {
  create_duration = "15s"
}

# Create the 4 member accounts
resource "aws_organizations_account" "member" {
  for_each = { for acct in var.member_accounts : acct.name => acct }

  name      = each.value.name
  email     = each.value.email
  role_name = "OrganizationAccountAccessRole"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [time_sleep.wait_15_seconds]
}

# Deny-critical SCP
resource "aws_organizations_policy" "deny_critical" {
  name    = "DenyCriticalActions"
  content = data.aws_iam_policy_document.deny_critical.json

  depends_on = [time_sleep.wait_15_seconds]
}

# Attach SCP to org root
resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.deny_critical.id
  target_id = data.aws_organizations_organization.main.roots[0].id

  depends_on = [time_sleep.wait_15_seconds]
}

# Deny-critical policy content
data "aws_iam_policy_document" "deny_critical" {
  statement {
    effect = "Deny"
    actions = [
      "organizations:LeaveOrganization",
      "account:CloseAccount",
      "account:Activate*",
      "iam:CreateAccessKey",
      "iam:UpdateLoginProfile"
    ]
    resources = ["*"]
  }
}

# Current account ID (management account)
data "aws_caller_identity" "current" {}

# Outputs
output "organization_id" {
  value = data.aws_organizations_organization.main.id
}

output "account_ids" {
  value = {
    management = data.aws_caller_identity.current.account_id
    logging    = aws_organizations_account.member["logging"].id
    security   = aws_organizations_account.member["security"].id
    dev        = aws_organizations_account.member["dev"].id
    prod       = aws_organizations_account.member["prod"].id
  }
}
