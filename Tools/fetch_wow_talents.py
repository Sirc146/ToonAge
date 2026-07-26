#!/usr/bin/env python3
"""
CharacterAdvisor -- Blizzard Talent Tree Data Fetcher
=======================================================
Pulls real talent-tree structure (nodes, tiers, spell IDs/names) from
Blizzard's official Game Data API for every playable specialization.

This gives you the REAL catalog of what talent options exist per spec.
It does NOT give you a "recommended build" -- picking which nodes are
best for M+/raid/solo is editorial judgment (what Icy Veins/Wowhead sell),
not something Blizzard's data API has an opinion on. Use this to populate
node/spell metadata; get recommended builds via real in-game Export
strings (Talent UI -> Export), same as the quest recorder workflow.

IMPORTANT -- schema is unverified until you check it
------------------------------------------------------
I don't have a live client to confirm exactly how Blizzard links a
talent-tree ID to a spec ID, or the precise shape of node/entry data.
Run the --inspect-* commands below IN ORDER and paste the output back
before trusting --fetch-all's bulk extraction.

Setup
-----
  pip install requests
  (same BLIZZARD_CLIENT_ID / BLIZZARD_CLIENT_SECRET env vars as
   fetch_wow_quests.py -- see that script's docstring for how to set them)

Verification sequence (run these first, in order)
---------------------------------------------------
  python fetch_wow_talents.py --inspect-spec-index
      -> confirms the list of all playable specs + their IDs

  python fetch_wow_talents.py --inspect-spec <SPEC_ID>
      -> fetches /data/wow/playable-specialization/<SPEC_ID>
         Look for how it references its talent tree(s) -- that tells us
         how to map spec -> talentTreeId for the next step.

  python fetch_wow_talents.py --inspect-tree-index
      -> confirms the list of all talent trees + their IDs

  python fetch_wow_talents.py --inspect-tree <TREE_ID> --for-spec <SPEC_ID>
      -> fetches /data/wow/talent-tree/<TREE_ID>/playable-specialization/<SPEC_ID>
         This is the endpoint with the actual nodes/tiers/spell data.

Once the schema is confirmed, --fetch-all attempts to auto-discover each
spec's talentTreeId from the spec detail endpoint. If that field isn't
where this script expects, it will say so explicitly rather than silently
producing wrong data.
"""

import argparse
import json
from pathlib import Path

from blizzard_api import add_credential_args, api_get, get_access_token, require_credentials

from paths import DATA_DIR

# See paths.py. Was a hardcoded personal Desktop path; .rules.md requires
# generated data to land in the repo. Override per-run with --out.
OUTPUT_DIR = DATA_DIR


def fetch_spec_index(token):
    return api_get("/data/wow/playable-specialization/index", token)


def fetch_spec_detail(token, spec_id):
    return api_get(f"/data/wow/playable-specialization/{spec_id}", token)


def fetch_tree_index(token):
    return api_get("/data/wow/talent-tree/index", token)


def fetch_spec_talent_tree(token, tree_id, spec_id):
    return api_get(f"/data/wow/talent-tree/{tree_id}/playable-specialization/{spec_id}", token)


def find_tree_id_in_spec_detail(spec_detail):
    """
    Best-effort search for a talent-tree reference inside a playable-specialization
    response. UNVERIFIED: tries a few plausible field names/shapes; returns None
    (with the caller printing a warning) if nothing matches, rather than guessing.
    """
    for key in ("spec_talent_tree", "talent_tree", "class_talent_tree"):
        val = spec_detail.get(key)
        if isinstance(val, dict) and "id" in val:
            return val["id"], key
        if isinstance(val, dict) and "key" in val and isinstance(val["key"], dict):
            href = val["key"].get("href", "")
            tail = href.rstrip("/").split("/")[-1].split("?")[0]
            if tail.isdigit():
                return int(tail), key
    return None, None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    add_credential_args(ap)
    ap.add_argument("--inspect-spec-index", action="store_true")
    ap.add_argument("--inspect-tree-index", action="store_true")
    ap.add_argument("--inspect-spec", type=int, metavar="SPEC_ID")
    ap.add_argument("--inspect-tree", type=int, metavar="TREE_ID")
    ap.add_argument("--for-spec", type=int, metavar="SPEC_ID",
                     help="Used with --inspect-tree to fetch the combined tree+spec endpoint")
    ap.add_argument("--fetch-all", action="store_true",
                     help="Attempt full extraction for every spec (only after schema is verified)")
    ap.add_argument("--out", default=str(OUTPUT_DIR))
    args = ap.parse_args()

    require_credentials(args)

    print("Requesting access token...")
    token = get_access_token(args.client_id, args.client_secret)

    if args.inspect_spec_index:
        data = fetch_spec_index(token)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    if args.inspect_spec is not None:
        data = fetch_spec_detail(token, args.inspect_spec)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    if args.inspect_tree_index:
        data = fetch_tree_index(token)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    if args.inspect_tree is not None:
        if args.for_spec is None:
            raise SystemExit("--inspect-tree requires --for-spec SPEC_ID too "
                              "(the endpoint needs both IDs)")
        data = fetch_spec_talent_tree(token, args.inspect_tree, args.for_spec)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    if not args.fetch_all:
        print("Nothing to do -- pass one of the --inspect-* flags first (see docstring), "
              "or --fetch-all once the schema is verified.")
        return

    # ── Bulk extraction (only trustworthy after --inspect-* verification) ──
    print("Fetching spec index...")
    spec_index = fetch_spec_index(token)
    specs = spec_index.get("character_specializations", spec_index.get("specializations", []))
    if not specs:
        print("[ERR] Could not find a spec list in the index response under any expected key. "
              "Raw keys present:", list(spec_index.keys()))
        return
    print(f"  {len(specs)} specs in index")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "talent_trees.json"

    results = {}
    errors = 0
    for i, spec_ref in enumerate(specs, 1):
        spec_id = spec_ref.get("id")
        spec_name = spec_ref.get("name", f"spec {spec_id}")
        if not spec_id:
            continue
        try:
            spec_detail = fetch_spec_detail(token, spec_id)
            tree_id, found_via = find_tree_id_in_spec_detail(spec_detail)
            if not tree_id:
                print(f"  [WARN] {spec_name} ({spec_id}): could not find a talent tree "
                      f"reference in the spec detail. Run --inspect-spec {spec_id} "
                      f"and tell me what the real field looks like.")
                errors += 1
                continue
            tree_detail = fetch_spec_talent_tree(token, tree_id, spec_id)
            results[spec_id] = {
                "name": spec_name,
                "tree_id": tree_id,
                "tree_id_found_via": found_via,
                "detail": tree_detail,
            }
        except Exception as e:
            errors += 1
            print(f"  [ERR] {spec_name} ({spec_id}): {e}")

        if i % 5 == 0 or i == len(specs):
            print(f"  {i}/{len(specs)} specs processed ({errors} errors)")

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\nDone. {len(results)} specs extracted, {errors} errors.")
    print(f"Raw talent-tree data -> {out_path}")
    print("This is the full official node/spell catalog per spec -- not a recommended")
    print("build. Cross-reference against real in-game Export strings for the")
    print("actual 'best' picks per content type.")


if __name__ == "__main__":
    main()
