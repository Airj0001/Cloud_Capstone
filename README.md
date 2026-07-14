# Capstone Phase 2 — Public Entry Point + First Real API Call

Builds on Phase 1. Adds a public API Gateway URL in front of the Lambda, and the
handler now makes one real call to NewsAPI using a key read from Secrets Manager
at runtime. The result is transformed before being returned. Region: us-east-1.

## What it satisfies
- Public front door: API Gateway (HTTP API) -> opens in a browser
- One real external API call: NewsAPI, from inside the handler
- Key read from Secrets Manager at runtime (nothing hard-coded)
- Result transformed (trimmed to useful fields + article count) then returned

## Files
- `main.tf`      - LabRole data source, secret, Lambda, API Gateway
- `variables.tf` - names + default topic
- `outputs.tf`   - the public URL, role ARN, secret name
- `lambda_src/handler.py` - reads secret, calls NewsAPI, transforms result

## Deploy
```bash
terraform init
terraform plan
terraform apply        # type yes
```

## Set the secret value OUT OF BAND (before calling the URL)
Get a free key from https://newsapi.org, then:
```bash
aws secretsmanager put-secret-value \
  --secret-id capstone-newsapi-key \
  --secret-string "YOUR_NEWSAPI_KEY" \
  --region us-east-1
```

## Call the public URL
`terraform apply` prints `api_url`. Open it in a browser, or use curl:
```bash
curl "https://XXXX.execute-api.us-east-1.amazonaws.com/news"
curl "https://XXXX.execute-api.us-east-1.amazonaws.com/news?topic=bitcoin"
```
You get back JSON with the topic, an article_count, and up to 5 articles.

## Deliverables for submission
1. A screenshot of the URL working (browser or curl) showing the JSON result.
2. This Terraform + Lambda code.

## Clean up
```bash
terraform destroy      # type yes
```

## Notes
- Learner Lab credentials expire when the lab stops; refresh on InvalidClientTokenId.
- If you see a 500 with "ResourceNotFound", the secret value was not set yet -
  run the put-secret-value command above.
