# Variables
# Docs: https://www.terraform.io/language/values/variables
variable "host_os" {
  type = string
  default = "linux" # options: linux, windows, macos
}