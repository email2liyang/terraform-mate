fmt:
	terraform fmt
init:
	terraform init
plan:
	terraform plan
apply:
	terraform apply -auto-approve
destroy:
	terraform destroy -auto-approve
clean:
	rm -fR .terraform terraform.tfstate terraform.tfstate.backup
# make hostPubIp=52.64.210.178 ssh
ssh:
	ssh -i ~/.ssh/id-psn-ap-southeast-2.pem ec2-user@${hostPubIp}
