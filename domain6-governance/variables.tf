variable "root_email" {
  description = "Email for the management (root) account – must be unique"
  type        = string
  default     = "your-real-email+root@gmail.com"   # ← CHANGE THIS
}

variable "member_accounts" {
  description = "List of member accounts to create"
  type = list(object({
    name  = string
    email = string
  }))
  default = [
    { name = "logging",  email = "your-real-email+logging@gmail.com" },
    { name = "security", email = "your-real-email+security@gmail.com" },
    { name = "dev",      email = "your-real-email+dev@gmail.com" },
    { name = "prod",     email = "your-real-email+prod@gmail.com" }
  ]
}