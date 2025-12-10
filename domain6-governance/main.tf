# Create the organization (only works from the management account)
resource "aws_organizations_organization" "main" {
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
}

# Create member accounts
resource "aws_organizations_account" "member" {
  for_each = { for acct in var.member_accounts : acct.name => acct }

  name      = each.value.name
  email     = each.value.email
  role_name = "OrganizationAccountAccessRole"

  # Prevents accidental closure
  lifecycle {
    prevent_destroy = true
  }
}

# Simple SCP – deny leaving the org + deny root actions
resource "aws_organizations_policy" "deny_critical" {
  name    = "DenyCriticalActions"
  content = data.aws_iam_policy_document.deny_critical.json
}

resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.deny_critical.id
  target_id = aws_organizations_organization.main.roots[0].id
}

data "aws_iam_policy_document" "deny_critical" {
  statement {
    effect = "Deny"
    actions = [
      "organizations:LeaveOrganization",
      "account:Activate*",
      "iam:CreateAccessKey",
      "iam:UpdateLoginProfile"
    ]
    resources = ["*"]
  }
}

# Output the account IDs so you can use them later
output "account_ids" {
  value = {
    management = data.aws_caller_identity.current.account_id
    logging    = aws_organizations_account.member["logging"].id
    security   = aws_organizations_account.member["security"].id
    dev        = aws_organizations_account.member["dev"].id
    prod       = aws_organizations_account.member["prod"].id
  }
}

data "aws_caller_identity" "current" {}
