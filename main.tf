# ===========================================================================
# Capstone Phase 2 — Public entry point + first real external API call
# Region: us-east-1 (AWS Academy Learner Lab)
#
# Builds on Phase 1:
#   - Lambda runs under LabRole (data source, not created)
#   - Reads the NewsAPI key from Secrets Manager at runtime
#   - Calls NewsAPI once and transforms the result
#   - API Gateway (HTTP API) puts a public HTTPS URL in front of the function
# ===========================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- Reuse the existing LabRole (never create a role) ----------------------
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# --- The secret CONTAINER. Value is set out of band (CLI/console). ---------
resource "aws_secretsmanager_secret" "newsapi_key" {
  name        = var.secret_name
  description = "NewsAPI key. Value set out of band, never in code."
}

# --- Package the handler from source ---------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/build/lambda.zip"
}

# --- The Lambda function ---------------------------------------------------
resource "aws_lambda_function" "phase2" {
  function_name    = var.function_name
  role             = data.aws_iam_role.lab_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 20
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SECRET_NAME   = aws_secretsmanager_secret.newsapi_key.name
      DEFAULT_TOPIC = var.default_topic
    }
  }
}

# --- API Gateway (HTTP API): the public front door -------------------------
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.function_name}-api"
  protocol_type = "HTTP"
}

# Connect the API to the Lambda (proxy integration)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.phase2.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route: GET /news  ->  the Lambda
resource "aws_apigatewayv2_route" "news_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /news"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Auto-deploy stage so the URL is live immediately
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowInvokeFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.phase2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
