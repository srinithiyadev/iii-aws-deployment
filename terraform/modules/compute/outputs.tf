output "api_gateway_public_ip"       { value = aws_instance.api_gateway.public_ip }
output "api_gateway_private_ip"      { value = aws_instance.api_gateway.private_ip }
output "caller_worker_private_ip"    { value = aws_instance.caller_worker.private_ip }
output "inference_worker_private_ip" { value = aws_instance.inference_worker.private_ip }
