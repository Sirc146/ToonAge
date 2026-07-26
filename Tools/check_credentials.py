#!/usr/bin/env python3
"""
ToonAge -- Blizzard API credential check
========================================
Confirms that BLIZZARD_CLIENT_ID / BLIZZARD_CLIENT_SECRET are set and that they
actually authenticate, without running a full crawl and without ever printing
the credentials themselves.

Every other script in Tools/ fails the same way when credentials are wrong --
somewhere in the middle of a long fetch -- so this exists to answer "are they
working?" in two seconds.

Usage
-----
    python Tools/check_credentials.py

Exit codes: 0 = working, 1 = not set, 2 = set but rejected, 3 = network/other.
"""

import os
import sys

try:
    import requests
except ImportError:
    print("[ERR] requests is not installed.  pip install requests")
    sys.exit(3)

from blizzard_api import API_BASE, STATIC_NAMESPACE, get_access_token


def mask(value):
    """Enough to tell two credentials apart, not enough to use one."""
    if not value:
        return "<not set>"
    if len(value) <= 8:
        return "*" * len(value)
    return f"{value[:4]}{'*' * (len(value) - 8)}{value[-4:]}"


def main():
    client_id = os.environ.get("BLIZZARD_CLIENT_ID")
    client_secret = os.environ.get("BLIZZARD_CLIENT_SECRET")

    print("Environment")
    print(f"  BLIZZARD_CLIENT_ID     {mask(client_id)}")
    print(f"  BLIZZARD_CLIENT_SECRET {'<set>' if client_secret else '<not set>'}")
    print()

    if not client_id or not client_secret:
        print("[FAIL] Credentials are not set in this process.")
        print()
        print("  Set them at User scope, then open a NEW shell -- an already-running")
        print("  shell keeps the environment it started with:")
        print()
        print("    [Environment]::SetEnvironmentVariable('BLIZZARD_CLIENT_ID','...','User')")
        print("    [Environment]::SetEnvironmentVariable('BLIZZARD_CLIENT_SECRET','...','User')")
        print()
        print("  Register the client at https://develop.battle.net/ -> API Access.")
        return 1

    print("Requesting an access token ...")
    try:
        token = get_access_token(client_id, client_secret)
    except requests.HTTPError as e:
        status = e.response.status_code if e.response is not None else "?"
        if status in (400, 401, 403):
            print(f"[FAIL] Blizzard rejected these credentials (HTTP {status}).")
            print("       The values are set but wrong, or the client was deleted.")
            return 2
        print(f"[FAIL] OAuth request failed with HTTP {status}.")
        return 3
    except requests.RequestException as e:
        print(f"[FAIL] Could not reach oauth.battle.net: {e}")
        return 3

    print(f"  token acquired ({len(token)} chars)")
    print()

    # A token alone only proves OAuth worked. Spend one real Game Data call to
    # prove the token is actually accepted by the API gateway with the static
    # namespace the fetch scripts use -- that is the combination that matters.
    print("Spending one Game Data call to confirm gateway access ...")
    try:
        r = requests.get(
            f"{API_BASE}/data/wow/token/index",
            headers={"Authorization": f"Bearer {token}"},
            params={"namespace": f"dynamic-{STATIC_NAMESPACE.split('-')[-1]}", "locale": "en_US"},
            timeout=15,
        )
        r.raise_for_status()
    except requests.HTTPError as e:
        status = e.response.status_code if e.response is not None else "?"
        print(f"[FAIL] Token works but the API rejected the call (HTTP {status}).")
        return 2
    except requests.RequestException as e:
        print(f"[FAIL] Could not reach the API gateway: {e}")
        return 3

    print("  gateway OK")
    print()
    print("[OK] Credentials work. Tools/fetch_wow_*.py will authenticate.")
    print()
    print("     Note: the Game Data API returns quest metadata only -- title,")
    print("     description, area, requirements, rewards. It has no x/y")
    print("     coordinates, so this does not help the guide coordinate gap")
    print("     (TODO item 4). Use it for quest/talent metadata refreshes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
