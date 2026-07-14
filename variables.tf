variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "capstone-phase2"
}

variable "secret_name" {
  description = "Name of the Secrets Manager secret holding the NewsAPI key."
  type        = string
  default     = "capstone-newsapi-key"
}

variable "default_topic" {
  description = "Topic to fetch when no ?topic= is given on the URL."
  type        = string
  default     = "technology"
}
