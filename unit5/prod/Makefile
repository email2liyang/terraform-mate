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

destroy_all:
	cd network/security_groups/ && \
	terraform destroy -auto-approve && \
	cd network/vpc/ && \
	terraform destroy -auto-approve

