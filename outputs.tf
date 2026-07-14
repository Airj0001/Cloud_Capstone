# The public URL to call. Append /news (and optionally ?topic=bitcoin).
output "api_url" {
  description = "Public HTTPS endpoint. Open this + /news in a browser."
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/news"
}

output "lambda_role_arn" {
  description = "Confirms the function runs under LabRole."
  value       = aws_lambda_function.phase2.role
}

output "secret_name" {
  description = "Set this secret's value out of band before calling the URL."
  value       = aws_secretsmanager_secret.newsapi_key.name
}
