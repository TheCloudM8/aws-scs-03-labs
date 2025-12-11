variable "root_email" {
  description = "Email for the management (root) account – must be unique"
  type        = string
  default     = "thecloudm8-scs-c03+root@outlook.com"   # ← CHANGE THIS
}

variable "member_accounts" {
  description = "List of member accounts to create"
  type = list(object({
    name  = string
    email = string
  }))
  default = [
    { name = "logging",  email = "thecloudm8-scs-c03+logging@outlook.com" },
    { name = "security", email = "thecloudm8-scs-c03+security@outlook.com" },
    { name = "dev",      email = "thecloudm8-scs-c03+dev@outlook.com" },
    { name = "prod",     email = "thecloudm8-scs-c03+prod@outlook.com" }
  ]
}