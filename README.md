# terraform-aviatrix-aws-firenet-eip-replace

### Description
This module helps users swap out the EIP assigned to a firenet instance's egress interface for a specified one.

It assumes you have already deployed the firenet instance(s). E.g. through the [firenet module](https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-firenet).

### Additional information
- The Aviatrix Terraform provider does not track the egress elastic IP after the initial creation. Because of this, changing it will not cause Terraform state drift.
- The Aviatrix controller will not become aware of the new elastic IP. Because of this, it will not attempt to delete it on deletion of the firenet instance in the future.
- This module will not deallocate the new EIP upon execuitng a `destroy`. It will only remove the association with the firenet instance.
- The controller to firenet instance communication (vendor integration and monitoring) will take place either on the LAN or Management interface. As such, changing the egress EIP will not interfere with normal operations.

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | >=1.0 | >=7.0 | >= 3.0.0

### Steps

1. Create a new EIP allocation through the AWS console or Terraform. We will need the allocation ID later on. This will become the new egress IP of the Firenet (NGFW) instance. In this example we use a data source to select an EIP allocation previously created through the AWS console.
```hcl
data "aws_eip" "new_eip" {
  public_ip = "18.193.25.243"
}
```

2. Gather the association ID of the current EIP association by adding the module and output below. We need to refer the module to the firenet instance that was created previously, for example through the [firenet module](https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-firenet). This returns a list of all created firenet instances as an output. Use the list index to specify which instance you want to select. Change \<module_name\> to whatever name you have given the firenet module. We will also provide the new EIP allocation ID while we're at it.
```hcl
module "replace_firenet_1_eip" {
  source = "/mnt/c/Users/Dennis/repositories/Modules/terraform-aviatrix-aws-firenet-eip-replace"

  step             = 1
  firenet_instance = module.<module_name>.aviatrix_firewall_instance[0]
  new_ip_alloc     = data.aws_eip.new_eip.id
}

output "original_association_id" {
  value = module.replace_firenet_1_eip.association_id
}
```

3. Change `step = 1` in the module to `step = 2`. This will enable a resoure in the module against which we will import the original EIP association.

4. Now that we have the original EIP association id, we can import that against a resource in the module. On the cli use the import command, or if you're running through a CI/CD pipeline and on Terraform 1.5+, use the [import statement](https://developer.hashicorp.com/terraform/language/import). Change \<module_name\> to whatever name you have given the module. In the above example we used "replace_firenet_1_eip"

```terraform import module.<module_name>.aws_eip_association.original_association[0] <original_association id>```

The original association ID we gathered from the output we have created above.

5. Run a `terraform plan`. There should be no changes. This step is to validate that the import was succesful.

6. Change `step = 2` in the module to `step = 3` and execute a `terraform plan`, review it and the execute `terraform apply`. This will remove the original EIP association.

7. Change `step = 3` in the module to `step = 4` and execute a `terraform plan`, review it and the execute `terraform apply`. This will create the association with the new EIP.

8. (Optional) The old EIP is now deallocated. You can chose to release it now or at any time in the future to prevent charges. DO NOT REUSE IT FOR OTHER PURPOSES. The controller is still aware of this EIP as the original EIP it launched the Firenet instance with and will attempt to clean it up if you ever delete the firenet instances.

### Variables
The following variables are required:

key | value
:--- | :---
new_ip_alloc | The EIP allocation to be assigned to the Firenet instance
firenet_instance | The firenet instance resource
step | The current step in the migration process as descibed above.

### Outputs
This module will return the following outputs:

key | description
:---|:---
association_id | The association ID of the originally assigned EIP.