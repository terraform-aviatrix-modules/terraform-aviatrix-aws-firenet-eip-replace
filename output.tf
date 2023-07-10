output "association_id" {
  value = var.step <= 3 ? data.aws_eip.original_eip[0].association_id : null
}
