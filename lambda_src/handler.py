"""
Capstone Phase 2 Lambda
-----------------------
Upgrades Phase 1: now there is a public front door (API Gateway) and the
handler makes ONE real call to NewsAPI.

Flow:
  1. Read the NewsAPI key from Secrets Manager at runtime (nothing hard-coded).
  2. Call NewsAPI for recent headlines on a topic.
  3. Transform the result (keep only the fields we care about, add a count)
     and return it as JSON through API Gateway.

Only the standard library + boto3 are used, so there is nothing to pip-install.
urllib is used instead of requests so no dependencies need packaging.
"""

import json
import os
import urllib.request
import urllib.parse

import boto3

secrets_client = boto3.client("secretsmanager")

SECRET_NAME = os.environ["SECRET_NAME"]
DEFAULT_TOPIC = os.environ.get("DEFAULT_TOPIC", "technology")


def get_api_key():
    """Read the NewsAPI key from Secrets Manager at runtime."""
    resp = secrets_client.get_secret_value(SecretId=SECRET_NAME)
    return resp["SecretString"]


def lambda_handler(event, context):
    # Allow ?topic=bitcoin on the URL; fall back to the default otherwise.
    params = (event.get("queryStringParameters") or {}) if isinstance(event, dict) else {}
    topic = (params or {}).get("topic", DEFAULT_TOPIC)

    try:
        api_key = get_api_key()

        # --- The one real external API call --------------------------------
        query = urllib.parse.urlencode({
            "q": topic,
            "pageSize": 5,
            "language": "en",
            "sortBy": "publishedAt",
            "apiKey": api_key,
        })
        url = f"https://newsapi.org/v2/everything?{query}"
        req = urllib.request.Request(url, headers={"User-Agent": "capstone-phase2"})
        try:
            with urllib.request.urlopen(req, timeout=5) as response:
                raw = json.loads(response.read().decode())
        except urllib.error.URLError:
            return {
                "statusCode": 504,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "news upstream timeout", "topic": topic}),
            }

        # --- Transform the result (do something real with it) --------------
        # Keep only the useful fields instead of returning the raw payload.
        articles = [
            {
                "title": a.get("title"),
                "source": (a.get("source") or {}).get("name"),
                "publishedAt": a.get("publishedAt"),
                "url": a.get("url"),
            }
            for a in raw.get("articles", [])
        ]

        body = {
            "topic": topic,
            "article_count": len(articles),
            "articles": articles,
        }

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body),
        }

    except Exception as exc:
        # Return a clean error instead of a stack trace
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(exc), "topic": topic}),
        }

