default: dummy

dummy:
	echo 'hello terraform'

vpc_apply:
	cd network/vpc/ && \
	terraform init && \
	terraform plan -out=plan.bin && \
	terraform apply -auto-approve plan.bin

security_groups_apply:
	cd network/security_groups/ && \
	terraform init && \
	terraform plan -out=plan.bin && \
	terraform apply -auto-approve plan.bin

ec2_apply:
	cd compute/ec2/ && \
	terraform init && \
	ansible-vault decrypt terraform.tfvars.vault --output=terraform.tfvars && \
	terraform plan -out=plan.bin && \
	terraform apply -auto-approve plan.bin

ec2_destroy:
	cd compute/ec2/ && \
	terraform destroy -auto-approve

security_groups_destroy: ec2_destroy
	cd network/security_groups/ && \
	terraform destroy -auto-approve

vpc_destroy: security_groups_destroy
	cd network/vpc/ && \
	terraform destroy -auto-approve

destroy_all: vpc_destroy
	echo 'destroy done'

ansible_view_inventory:
	cd compute/ec2/ && \
	terraform state pull > terraform.tfstate && \
	terraform-inventory --list | jq . > ansible/inventory/inventory.json && \
	cat ansible/inventory/inventory.json

ansible_install_es:
	cd compute/ec2/ && \
	terraform state pull > terraform.tfstate && \
	ansible-playbook --inventory-file=/usr/local/bin/terraform-inventory ansible/playbooks/ping.yaml


