data "aws_eip" "original_eip" {
  count = var.step <= 3 ? 1 : 0

  filter {
    name   = "network-interface-id"
    values = [var.firenet_instance.egress_interface]
  }
}

resource "aws_eip_association" "original_association" {
  count                = var.step == 2 ? 1 : 0
  network_interface_id = data.aws_eip.original_eip[0].network_interface_id
  allocation_id        = data.aws_eip.original_eip[0].id
}

resource "aws_eip_association" "new_association" {
  count                = var.step == 4 ? 1 : 0
  network_interface_id = var.firenet_instance.egress_interface
  allocation_id        = var.new_ip_alloc
}
