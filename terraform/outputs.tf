output "api_gateway_public_ip" {
  value = module.compute.api_gateway_public_ip
}

output "curl_command" {
  value = <<-EOT
    curl -X POST http://${module.compute.api_gateway_public_ip}:3111/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"messages": [{"role": "user", "content": "hello"}]}'
  EOT
}

output "vm_ips" {
  value = {
    api_gateway      = module.compute.api_gateway_public_ip
    caller_worker    = module.compute.caller_worker_private_ip
    inference_worker = module.compute.inference_worker_private_ip
  }
}
