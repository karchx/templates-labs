.PHONY: apply

apply: plan
	tofu apply tfplan

.PHONY: plan

plan:
	tofu plan -out=tfplan
