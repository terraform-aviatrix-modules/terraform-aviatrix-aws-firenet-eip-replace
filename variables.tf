variable "new_ip_alloc" {
  description = "The EIP allocation to be assigned to the Firenet instance."
  type        = string
}

variable "firenet_instance" {}

variable "step" {
  description = "Step in the migration process."
  type        = number
}
