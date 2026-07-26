#!/usr/bin/env python3
"""
ToonAge -- Shared Blizzard Game Data API helper
=========================================================
OAuth client-credentials auth + rate-limited GET, shared by every
fetch_wow_*.py script in this Tools/ folder so the auth/throttling logic
lives in exactly one place instead of being copy-pasted per script.

Setup
-----
  pip install requests

  Set your client credentials as environment variables (do NOT hardcode
  them anywhere or commit them):

      # PowerShell
      $env:BLIZZARD_CLIENT_ID     = "your-client-id"
      $env:BLIZZARD_CLIENT_SECRET = "your-client-secret"

      # bash
      export BLIZZARD_CLIENT_ID="your-client-id"
      export BLIZZARD_CLIENT_SECRET="your-client-secret"

Rate limiting
-------------
Blizzard's API allows 36,000 requests/hour at up to 100 requests/second.
This module throttles both independently -- a per-request delay keeps the
per-second rate under the 100/sec cap, and a separate hourly counter pauses
once 36,000 requests land in a rolling hour -- and backs off on 429s, per
the API Terms of Use ("You may not use the Blizzard Developer APIs
Excessively").
"""

import argparse
import os
import time

import requests

REGION    = "us"
LOCALE    = "en_US"
OAUTH_URL = "https://oauth.battle.net/token"
API_BASE  = f"https://{REGION}.api.blizzard.com"
STATIC_NAMESPACE = f"static-{REGION}"

MIN_INTERVAL = 0.02   # ~50 req/sec, safely under Blizzard's 100/sec cap

# The per-request MIN_INTERVAL above only bounds the per-second rate (50 <
# 100/sec). Sustained at that rate it's 180,000 requests/hour -- 5x over
# Blizzard's separate 36,000/hour quota -- so a long crawl needs its own
# hourly gate independent of the per-second one.
HOURLY_LIMIT = 36000
_hour_window_start = time.monotonic()
_hour_request_count = 0


def get_access_token(client_id, client_secret):
    r = requests.post(
        OAUTH_URL,
        data={"grant_type": "client_credentials"},
        auth=(client_id, client_secret),
        timeout=15,
    )
    r.raise_for_status()
    return r.json()["access_token"]


_last_request_time = 0.0

def _throttle_hourly():
    global _hour_window_start, _hour_request_count
    elapsed = time.monotonic() - _hour_window_start
    if elapsed >= 3600:
        _hour_window_start = time.monotonic()
        _hour_request_count = 0
        return
    if _hour_request_count >= HOURLY_LIMIT:
        wait = 3600 - elapsed
        print(f"  [hourly cap] {_hour_request_count} requests this hour, sleeping {wait:.0f}s")
        time.sleep(wait)
        _hour_window_start = time.monotonic()
        _hour_request_count = 0


def api_get(path, token, params=None, namespace=None):
    global _last_request_time, _hour_request_count
    params = dict(params or {})
    params.setdefault("namespace", namespace or STATIC_NAMESPACE)
    params.setdefault("locale", LOCALE)

    _throttle_hourly()
    wait = MIN_INTERVAL - (time.monotonic() - _last_request_time)
    if wait > 0:
        time.sleep(wait)

    backoff = 1.0
    for attempt in range(6):
        _last_request_time = time.monotonic()
        _hour_request_count += 1
        r = requests.get(
            f"{API_BASE}{path}",
            headers={"Authorization": f"Bearer {token}"},
            params=params,
            timeout=15,
        )
        if r.status_code == 429:
            retry_after = float(r.headers.get("Retry-After", backoff))
            print(f"  [429] rate limited, backing off {retry_after:.1f}s")
            time.sleep(retry_after)
            backoff *= 2
            continue
        if r.status_code >= 500:
            print(f"  [{r.status_code}] server error, retrying in {backoff:.1f}s")
            time.sleep(backoff)
            backoff *= 2
            continue
        r.raise_for_status()
        return r.json()

    raise RuntimeError(f"Giving up on {path} after repeated failures")


def add_credential_args(parser: argparse.ArgumentParser):
    """Adds the standard --client-id/--client-secret args (env-var backed) to a script's parser."""
    parser.add_argument("--client-id", default=os.environ.get("BLIZZARD_CLIENT_ID"))
    parser.add_argument("--client-secret", default=os.environ.get("BLIZZARD_CLIENT_SECRET"))


def require_credentials(args):
    if not args.client_id or not args.client_secret:
        raise SystemExit(
            "[ERR] Missing credentials. Set BLIZZARD_CLIENT_ID / BLIZZARD_CLIENT_SECRET"
            " or pass --client-id/--client-secret."
        )
