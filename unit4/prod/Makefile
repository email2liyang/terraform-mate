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
