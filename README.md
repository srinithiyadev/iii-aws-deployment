# iii-aws-deployment

deploys the iii quickstart on AWS — 3 VMs, one public API gateway, two private workers.

## architecture

Internet → VM1 (public, iii engine :3111) → VM2 (caller-worker, private) → VM3 (inference-worker, private) → response back

VM2 and VM3 have zero inbound from internet. they connect outbound to VM1 via WebSocket on :49134 only.

## instance types

* VM1 t3.micro — runs iii engine binary only
* VM2 t3.micro — typescript caller-worker
* VM3 t3.micro — python inference-worker + gemma 3 270M

## deploy

cd terraform
cp terraform.tfvars.example terraform.tfvars
edit terraform.tfvars with your SSH key and IP
terraform init
terraform apply

## test

curl -X POST http://API_GATEWAY_PUBLIC_IP:3111/v1/chat/completions -H "Content-Type: application/json" -d '{"messages": [{"role": "user", "content": "hello"}]}'

## redeploy

terraform taint aws_instance.inference_worker
terraform apply

terraform destroy to tear down

## production hardening

- replace SSH with SSM Session Manager
- ALB + WAF in front of VM1
- store model on EBS so it survives redeploys
- push docker images to ECR instead of building on VM
- add API key validation on the HTTP handler

## if model was 100x bigger

gemma 270M is 270MB quantized. 100x means 27B params, 15-20GB GGUF.
t3.xlarge wont fit it — need r6i.4xlarge (CPU) or g5.2xlarge (GPU).
model download goes from 2min to 30min — bake into custom AMI or store on EBS snapshot.
need vLLM with continuous batching for decent throughput.

Srinithiya — May 2026
