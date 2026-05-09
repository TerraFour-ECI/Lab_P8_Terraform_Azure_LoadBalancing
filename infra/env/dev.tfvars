# =============================================================================
#  Development environment values for Lab #8
# -----------------------------------------------------------------------------
#  Adjust `ssh_public_key` and `allow_ssh_from_cidr` to match the engineer
#  running the lab from their machine. The remaining values match the
#  recorded video and the final report.
# =============================================================================
prefix              = "lab8"
location            = "eastus"
vm_count            = 2
admin_username      = "student"
ssh_public_key      = "C:/Users/<YOUR_USER>/.ssh/id_ed25519.pub"
allow_ssh_from_cidr = "186.154.34.223/32"

tags = {
  owner   = "arsw-team"
  course  = "ARSW"
  env     = "dev"
  expires = "2026-12-31"
}
