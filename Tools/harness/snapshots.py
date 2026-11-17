#!/usr/bin/env python3
"""
Write Tools/fixtures/api/{forever,retail,tbc}.lua.

The Forever and Retail catalogs are the names this repo's TOC files call,
plus the engine and the in-game self-test's API list, with the probe
overrides applied last. Blizzard's Forever UI source for build 70938 was
not available here, so a non-probe entry is source=wiki and UNVERIFIED.
Nothing in this file is copied from that source.

    python Tools/harness/snapshots.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

HARNESS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = HARNESS_DIR.parent
ROOT = TOOLS_DIR.parent
OUT_DIR = TOOLS_DIR / "fixtures" / "api"

sys.path.insert(0, str(TOOLS_DIR))
from gen_api_manifest import BARE_GLOBALS  # noqa: E402
from harness.wowsim import lua_quote, toc_entries  # noqa: E402

NS_CALL = re.compile(r"\bC_([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)")
# Blizzard UI objects that are not C_* namespaces. Addon tables (TA, UI) are
# not in this list, so a mention of those is not recorded as a client API.
UI_ROOT_CALL = re.compile(r"\b(Menu|Settings)\.([A-Za-z_][A-Za-z0-9_]*)")
EVENT_CALL = re.compile(
    r"Register(?:Unit)?Event\(\s*[\"']([A-Z][A-Z0-9_]+)[\"']"
)

# Probe 2026-09-28, Forever 1.60.1 build 70009, interface 16001.
# These names were confirmed MISSING. Do not add to this list from memory.
FOREVER_PROBE_MISSING = (
    "GetNumSkillLines",
    "GetSkillLineInfo",
    "UnitAttackBothHands",
    "UnitDefense",
    "UnitRangedAttack",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetTalentInfo",
    "GetItemInfo",
    "GetSpellInfo",
    "GetItemStats",
    "GetSpellCooldown",
    "GetItemInfoInstant",
    "PickupContainerItem",
    "GetSpecialization",
    "UnitAura",
    "GetPVPRankInfo",
    "UnitPVPRank",
)
FOREVER_PROBE_MISSING_EVENTS = (
    "HONOR_CURRENCY_UPDATE",
    "PLAYER_PET_CHANGED",
)

# Probe 2026-09-28, Retail 12.1.0 build 69933, interface 120100.
RETAIL_PROBE_MISSING = (
    "GetSpellInfo",
    "UnitAura",
    "PickupContainerItem",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetPVPRankInfo",
    "UnitPVPRank",
)
RETAIL_PROBE_PRESENT = (
    "GetItemInfoInstant",
    "GetSpecialization",
    "C_AssistedCombat",
    "CreateFramePool",
)

# Names the self-test resolves. Kept here so a string-built path
# (C_ .. "Heirloom....") still lands in the snapshot.
HARNESS_APIS = (
    "C_Timer.After",
    "C_Timer.NewTicker",
    "CreateFrame",
    "BackdropTemplateMixin",
    "UISpecialFrames",
    "GetProfessions",
    "GetProfessionInfo",
    "PickupContainerItem",
    "EquipCursorItem",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetSpecialization",
    "GetSpecializationInfo",
    "C_ClassTalents.GetActiveConfigID",
    "C_Traits.GetConfigInfo",
    "C_TooltipInfo.GetHyperlink",
    "C_SpellBook.GetNumSpellBookSkillLines",
    "C_Item.GetItemStats",
    "GetActionInfo",
    "C_Spell.GetSpellSubtext",
    "issecretvalue",
    "CreateFramePool",
    "EnumerateFrames",
    "UpdateAddOnMemoryUsage",
    "GetAddOnMemoryUsage",
    "C_AddOns.GetAddOnMetadata",
    "Settings.RegisterCanvasLayoutCategory",
    "Menu.ModifyMenu",
    "UIDropDownMenu_AddButton",
    "C_AssistedCombat.GetNextCastSpell",
    "C_Heirloom.GetHeirloomItemIDs",
    "C_Heirloom.PlayerHasHeirloom",
    "C_Heirloom.GetHeirloomInfo",
    "C_Heirloom.GetHeirloomMaxUpgradeLevel",
    "C_Heirloom.CreateHeirloom",
    "C_UnitAuras.GetBuffDataByIndex",
    "UnitAura",
    "GetItemInfoInstant",
    "C_Item.GetItemInfoInstant",
    "GetSpellInfo",
    "C_Spell.GetSpellInfo",
    "GetPVPRankInfo",
    "UnitPVPRank",
    "GetPVPLifetimeStats",
    "GetPVPSessionStats",
    "C_Container.PickupContainerItem",
    "LE_EXPANSION_LEVEL_CURRENT",
)

# Widgets and Lua-side helpers the fake client can actually implement.
# Installed only when the snapshot says the name is present.
ENGINE = (
    "CreateFrame",
    "C_Timer.After",
    "C_Timer.NewTicker",
    "GetBuildInfo",
    "GetTime",
    "time",
    "date",
    "UnitName",
    "GetRealmName",
    "UnitLevel",
    "UnitClass",
    "UnitRace",
    "InCombatLockdown",
    "debugstack",
    "hooksecurefunc",
    "geterrorhandler",
    "seterrorhandler",
    "IsAddOnLoaded",
    "GetAddOnInfo",
    "GetAddOnMetadata",
    "C_AddOns.GetAddOnMetadata",
    "C_AddOns.IsAddOnLoaded",
    "C_AddOns.GetAddOnInfo",
    "issecretvalue",
    "CreateFramePool",
    "EnumerateFrames",
    "UpdateAddOnMemoryUsage",
    "GetAddOnMemoryUsage",
    "Mixin",
    "wipe",
    "strsplit",
    "strjoin",
    "strtrim",
    "strmatch",
    "tContains",
    "CopyTable",
    "format",
    "tinsert",
    "tremove",
    "debugprofilestop",
    "UnitPower",
    "UnitPowerMax",
    "GetUnitChargedPowerPoints",
    "UIDropDownMenu_AddButton",
)

ENGINE_TABLES = (
    "SlashCmdList",
    "UISpecialFrames",
    "BackdropTemplateMixin",
    "C_AssistedCombat",
    "StaticPopupDialogs",
)
ENGINE_FRAMES = (
    "UIParent",
    "GameTooltip",
    "Minimap",
)
ENGINE_STRINGS = ("STANDARD_TEXT_FONT",)
ENGINE_NUMBERS = ("WOW_PROJECT_ID", "LE_EXPANSION_LEVEL_CURRENT")

# Closed set from the historical TBC boot prelude. Extra present names would
# change `if API then` branches that test_tbc_boot.py already runs.
TBC_FUNCTIONS = (
    "debugstack",
    "GetBuildInfo",
    "CreateFrame",
    "C_Timer.After",
    "C_Timer.NewTicker",
    "UnitName",
    "GetRealmName",
    "UnitLevel",
    "UnitClass",
    "UnitRace",
    "GetTime",
    "InCombatLockdown",
    "time",
    "date",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetTalentInfo",
    "GetNumSpellTabs",
    "GetSpellTabInfo",
    "GetSpellBookItemName",
    "GetSpellBookItemInfo",
    "IsPassiveSpell",
    "GetActionInfo",
    "GetSpellInfo",
    "GetShapeshiftFormInfo",
    "GetNumShapeshiftForms",
    "GetInventoryItemLink",
    "GetItemInfo",
    "GetContainerNumSlots",
    "GetContainerItemLink",
    "GetContainerItemID",
    "GetContainerItemInfo",
    "GetCombatRating",
    "GetCombatRatingBonus",
    "GetExpertise",
    "GetDodgeChance",
    "GetParryChance",
    "GetBlockChance",
    "GetSpellBonusDamage",
    "GetSpellCritChance",
    "GetInventoryItemsForSlot",
    "IsAddOnLoaded",
    "GetAddOnInfo",
    "hooksecurefunc",
    "geterrorhandler",
    "seterrorhandler",
)

# Boot and refresh events Init.lua registers for every client, plus the
# self-test's safe list. A name not in a snapshot is rejected by RegisterEvent
# on Forever and Retail (the TBC prelude accepted every name).
BOOT_EVENTS = (
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LOGOUT",
    "PLAYER_LEVEL_UP",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "TRAIT_CONFIG_UPDATED",
    "SKILL_LINES_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE",
    "GROUP_ROSTER_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PET_STABLE_UPDATE",
    "UNIT_PET",
    "CHAT_MSG_SYSTEM",
    "GET_ITEM_INFO_RECEIVED",
    "QUEST_ACCEPTED",
    "ENCOUNTER_START",
    "ENCOUNTER_END",
    "UNIT_ENTERED_VEHICLE",
    "UNIT_EXITED_VEHICLE",
    "PET_BATTLE_OPENING_START",
    "PET_BATTLE_OVER",
    "PLAYER_XP_UPDATE",
    "UNIT_STATS",
    "SPELLS_CHANGED",
)

# Present on Forever and Retail even when no call site was scanned: the
# offline client needs them to boot a TOC. Handlers live in engine.lua.
# Names that only have a handler (EnumerateFrames, CreateFramePool, ...)
# stay missing until a TOC calls them or a probe says present.
ALWAYS = {
    "CreateFrame", "C_Timer.After", "C_Timer.NewTicker", "GetBuildInfo",
    "GetTime", "time", "date", "UnitName", "GetRealmName", "UnitLevel",
    "UnitClass", "UnitRace", "InCombatLockdown", "debugstack",
    "hooksecurefunc", "geterrorhandler", "seterrorhandler",
    "IsAddOnLoaded", "GetAddOnInfo", "GetAddOnMetadata",
    "Mixin", "wipe", "strsplit", "strjoin", "strtrim", "strmatch",
    "tContains", "CopyTable", "format", "tinsert", "tremove",
    "SlashCmdList", "UISpecialFrames", "BackdropTemplateMixin",
    "UIParent", "GameTooltip", "Minimap", "STANDARD_TEXT_FONT", "WOW_PROJECT_ID",
    "StaticPopupDialogs",
}

KIND = {}
for _name in ENGINE_TABLES:
    KIND[_name] = "table"
for _name in ENGINE_FRAMES:
    KIND[_name] = "frame"
for _name in ENGINE_STRINGS:
    KIND[_name] = "string"
for _name in ENGINE_NUMBERS:
    KIND[_name] = "number"


def _strip_comments(text):
    return "\n".join(re.sub(r"--.*$", "", line) for line in text.splitlines())


def scan_toc(toc_name):
    calls = set()
    events = set(BOOT_EVENTS)
    extra_bare = list(BARE_GLOBALS) + list(ENGINE) + [
        "GetProfessions", "GetProfessionInfo", "GetSpecializationInfo",
        "GetActionInfo", "EquipCursorItem", "UIDropDownMenu_AddButton",
        "debugprofilestop", "UnitPower", "UnitPowerMax",
        "GetUnitChargedPowerPoints", "CreateFramePool", "EnumerateFrames",
        "UpdateAddOnMemoryUsage", "GetAddOnMemoryUsage",
        "UnitExists", "UnitXP", "UnitXPMax", "UnitGroupRolesAssigned",
        "GetXPExhaustion", "IsResting", "GetMaxPlayerLevel",
        "GetWeeklyQuestResetTime", "IsInRaid", "IsInGroup",
        "CreateColor", "IsInInstance",
    ]
    # Longest first would not matter; these are whole identifiers.
    bare = re.compile(r"(?<![\w.:])(" + "|".join(sorted(set(extra_bare), key=len, reverse=True)) + r")\s*\(")
    for kind, rel in toc_entries(toc_name):
        if kind != "lua":
            continue
        if rel.endswith("ApiManifest.lua"):
            continue
        path = ROOT / rel
        if not path.is_file():
            continue
        code = _strip_comments(path.read_text(encoding="utf-8", errors="replace"))
        for match in NS_CALL.finditer(code):
            calls.add("C_%s.%s" % (match.group(1), match.group(2)))
        for match in UI_ROOT_CALL.finditer(code):
            calls.add("%s.%s" % (match.group(1), match.group(2)))
        for match in bare.finditer(code):
            calls.add(match.group(1))
        for match in EVENT_CALL.finditer(code):
            events.add(match.group(1))
    return calls, events


def _entry(status, source, build, kind="function"):
    return {
        "status": status,
        "source": source,
        "build": build,
        "unverified": source != "probe",
        "kind": kind,
    }


def _emit_map(mapping, indented=True):
    pad = "        " if indented else "    "
    lines = []
    for name in sorted(mapping):
        entry = mapping[name]
        fields = [
            "status = %s" % lua_quote(entry["status"]),
            "source = %s" % lua_quote(entry["source"]),
            "build = %s" % lua_quote(entry["build"]),
            "unverified = %s" % ("true" if entry["unverified"] else "false"),
        ]
        if "kind" in entry:
            fields.append("kind = %s" % lua_quote(entry["kind"]))
        lines.append("%s[%s] = { %s }," % (pad, lua_quote(name), ", ".join(fields)))
    return "\n".join(lines)


def _header(text):
    return "\n".join("-- " + line if line else "--" for line in text.strip("\n").splitlines())


def write_forever(calls, events):
    seed = "70938"
    probe_build = "70009"
    apis = {}
    names = set(calls) | set(HARNESS_APIS) | set(ENGINE) | set(ALWAYS) | set(ENGINE_NUMBERS)
    for name in names:
        kind = KIND.get(name, "function")
        if name == "LE_EXPANSION_LEVEL_CURRENT":
            status = "missing"
        elif name in calls or name in ALWAYS:
            status = "present"
        else:
            status = "missing"
        apis[name] = _entry(status, "wiki", seed, kind)
    for name in FOREVER_PROBE_MISSING:
        kind = apis.get(name, {}).get("kind", "function")
        apis[name] = _entry("missing", "probe", probe_build, kind)
    # The Forever self-test requires GetActionInfo. The 70009 probe did not
    # list it, and the current TOC has no direct call for the scanner to see,
    # so it would otherwise stay missing and the suite would fail on our
    # omission. Wiki + UNVERIFIED, not probe.
    if "GetActionInfo" in apis and apis["GetActionInfo"]["source"] != "probe":
        apis["GetActionInfo"] = _entry("present", "wiki", seed, "function")
    # CreateFramePool is not a probe result. Forever's talent grid comments
    # that this client does not have it, and the Forever TOC does not call it.
    if "CreateFramePool" in apis and apis["CreateFramePool"]["source"] != "probe":
        apis["CreateFramePool"] = _entry("missing", "wiki", seed, "function")
    event_map = {}
    for name in events | set(FOREVER_PROBE_MISSING_EVENTS):
        event_map[name] = {
            "status": "present",
            "source": "wiki",
            "build": seed,
            "unverified": True,
        }
    for name in FOREVER_PROBE_MISSING_EVENTS:
        event_map[name] = {
            "status": "missing",
            "source": "probe",
            "build": probe_build,
            "unverified": False,
        }
    body = _header("""
Tools/fixtures/api/forever.lua
Snapshot for the offline Forever client.

Simulated client (GetBuildInfo): 1.60.1, build 70009, interface 16001.
That is the 2026-09-28 in-game probe. WOW_PROJECT_ID is 1 because
Core/Environment.lua records that builds up to 70124 still reported the
Mainline project id; Forever is then told apart by the interface code.
That project-id note is the repo text, not the 2026-09-28 probe, so the
WOW_PROJECT_ID entry stays UNVERIFIED.

Seed build on non-probe rows: 70938. Blizzard's Forever UI source for that
build was not available when this file was written, so those rows are
source=wiki (the names this repository calls, plus the shared engine list).
They are UNVERIFIED. source=ui-source is not used. A later in-game probe
should replace a row with source=probe and unverified=false.

Probe rows (source=probe, build 70009, unverified=false) are only the
names the 2026-09-28 probe confirmed missing. A present row is never
marked probe unless that probe said so.

An API or event absent from this file is nil / rejected. RegisterEvent
throws for an event whose status is not present, which is how
TA:RegisterEvent records an unknown event.
""")
    player = """
    player = {
        name = "Pebble", realm = "Fakeserver", level = 42,
        class = "Mage", class_file = "MAGE", race = "Human", race_file = "Human",
    },"""
    text = (
        body
        + "\nreturn {\n"
        + "    id = \"forever\",\n"
        + "    label = \"WoW Forever 1.60.1\",\n"
        + "    toc = \"ToonAge_Camelot.toc\",\n"
        + "    interface = 16001,\n"
        + "    project_id = 1,\n"
        + "    version = \"1.60.1\",\n"
        + "    build = \"70009\",\n"
        + "    build_date = \"2026-09-28\",\n"
        + "    text_font = \"Fonts\\\\FRIZQT__.TTF\",\n"
        + "    enforce_events = true,\n"
        + player + "\n"
        + "    apis = {\n" + _emit_map(apis) + "\n    },\n"
        + "    events = {\n" + _emit_map(event_map) + "\n    },\n"
        + "}\n"
    )
    path = OUT_DIR / "forever.lua"
    path.write_text(text, encoding="utf-8")
    return path, apis, event_map


def write_retail(calls, events):
    build = "69933"
    apis = {}
    names = (
        set(calls) | set(HARNESS_APIS) | set(ENGINE) | set(ALWAYS)
        | set(ENGINE_NUMBERS) | set(RETAIL_PROBE_PRESENT) | set(RETAIL_PROBE_MISSING)
    )
    for name in names:
        kind = KIND.get(name, "function")
        if name == "LE_EXPANSION_LEVEL_CURRENT":
            status = "missing"
        elif name in calls or name in ALWAYS:
            status = "present"
        else:
            status = "missing"
        apis[name] = _entry(status, "wiki", build, kind)
    for name in RETAIL_PROBE_MISSING:
        kind = apis.get(name, {}).get("kind", KIND.get(name, "function"))
        apis[name] = _entry("missing", "probe", build, kind)
    for name in RETAIL_PROBE_PRESENT:
        kind = KIND.get(name, "function")
        apis[name] = _entry("present", "probe", build, kind)
    # The probe named the C_AssistedCombat namespace, not each method.
    # GetNextCastSpell stays wiki/UNVERIFIED even though the namespace is probe-present.
    if "C_AssistedCombat.GetNextCastSpell" in apis and apis["C_AssistedCombat.GetNextCastSpell"]["source"] != "probe":
        apis["C_AssistedCombat.GetNextCastSpell"] = _entry("present", "wiki", build, "function")
    event_map = {}
    for name in set(events) | set(FOREVER_PROBE_MISSING_EVENTS):
        event_map[name] = {
            "status": "present",
            "source": "wiki",
            "build": build,
            "unverified": True,
        }
    # The Forever probe does not certify these on Retail. They are not in the
    # Retail absent list either, so they stay wiki and UNVERIFIED, present
    # because Retail code and the boot list can register the usual currency
    # and pet events. They are not probe-confirmed.
    body = _header("""
Tools/fixtures/api/retail.lua
Snapshot for the offline Retail client.

Simulated client (GetBuildInfo): 12.1.0, build 69933, interface 120100,
WOW_PROJECT_ID 1. Probe date 2026-09-28.

Probe rows (source=probe, unverified=false) are only the names that probe
listed: absent GetSpellInfo, UnitAura, PickupContainerItem, GetNumTalentTabs,
GetTalentTabInfo, GetPVPRankInfo, UnitPVPRank; present GetItemInfoInstant,
GetSpecialization, C_AssistedCombat, CreateFramePool.

Every other row is source=wiki and UNVERIFIED. The build field on those
rows is 69933 because this snapshot is of that client, not because the
probe confirmed the row. C_AssistedCombat.GetNextCastSpell is wiki: the
probe named the namespace, not the method.

An API absent from this file is nil. RegisterEvent throws unless the
event's status is present.
""")
    player = """
    player = {
        name = "Pebble", realm = "Fakeserver", level = 80,
        class = "Mage", class_file = "MAGE", race = "Human", race_file = "Human",
    },"""
    text = (
        body
        + "\nreturn {\n"
        + "    id = \"retail\",\n"
        + "    label = \"Retail 12.1.0\",\n"
        + "    toc = \"ToonAge_Mainline.toc\",\n"
        + "    interface = 120100,\n"
        + "    project_id = 1,\n"
        + "    version = \"12.1.0\",\n"
        + "    build = \"69933\",\n"
        + "    build_date = \"2026-09-28\",\n"
        + "    text_font = \"Fonts\\\\FRIZQT__.TTF\",\n"
        + "    enforce_events = true,\n"
        + player + "\n"
        + "    apis = {\n" + _emit_map(apis) + "\n    },\n"
        + "    events = {\n" + _emit_map(event_map) + "\n    },\n"
        + "}\n"
    )
    path = OUT_DIR / "retail.lua"
    path.write_text(text, encoding="utf-8")
    return path, apis, event_map


def write_tbc():
    build = "00000"
    apis = {}
    for name in TBC_FUNCTIONS:
        apis[name] = _entry("present", "wiki", build, "function")
    apis["WOW_PROJECT_ID"] = _entry("present", "wiki", build, "number")
    apis["UIParent"] = _entry("present", "wiki", build, "frame")
    apis["STANDARD_TEXT_FONT"] = _entry("present", "wiki", build, "string")
    body = _header("""
Tools/fixtures/api/tbc.lua
Closed API list for the TBC boot test.

This is the surface Tools/test_tbc_boot.py used to install by hand:
WOW_PROJECT_ID 5, GetBuildInfo 2.5.6 / 00000 / date / 20506, and the classic
globals that prelude defined. There is no in-game probe behind it. Every
row is source=wiki, build 00000 (the prelude's build string), UNVERIFIED.

Names that are not listed stay nil, including Retail C_* namespaces.
enforce_events is false: that prelude's frame mock accepted every
RegisterEvent, and the boot test depends on that.

Player is the synthetic Tbctest-Tbcrealm mage from the old prelude, not a
real character.
""")
    player = """
    player = {
        name = "Tbctest", realm = "Tbcrealm", level = 65,
        class = "Mage", class_file = "MAGE", race = "Gnome", race_file = "Gnome",
    },"""
    text = (
        body
        + "\nreturn {\n"
        + "    id = \"tbc\",\n"
        + "    label = \"TBC Anniversary stub\",\n"
        + "    toc = \"ToonAge_TBC.toc\",\n"
        + "    interface = 20506,\n"
        + "    project_id = 5,\n"
        + "    version = \"2.5.6\",\n"
        + "    build = \"00000\",\n"
        + "    build_date = \"date\",\n"
        + "    text_font = \"Fonts\\\\FRIZQT__.TTF\",\n"
        + "    enforce_events = false,\n"
        + player + "\n"
        + "    apis = {\n" + _emit_map(apis) + "\n    },\n"
        + "    events = {\n    },\n"
        + "}\n"
    )
    path = OUT_DIR / "tbc.lua"
    path.write_text(text, encoding="utf-8")
    return path, apis


def _summarize(label, apis, events=None):
    sources = {}
    unverified = {}
    groups = [apis]
    if events:
        groups.append(events)
    for group in groups:
        for entry in group.values():
            sources[entry["source"]] = sources.get(entry["source"], 0) + 1
            if entry["unverified"]:
                unverified[entry["source"]] = unverified.get(entry["source"], 0) + 1
    print("%s  entries=%d  by_source=%s  unverified=%s" % (label, sum(sources.values()), sources, unverified))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    forever_calls, forever_events = scan_toc("ToonAge_Camelot.toc")
    retail_calls, retail_events = scan_toc("ToonAge_Mainline.toc")
    path, apis, events = write_forever(forever_calls, forever_events)
    _summarize(path.name, apis, events)
    path, apis, events = write_retail(retail_calls, retail_events)
    _summarize(path.name, apis, events)
    path, apis = write_tbc()
    _summarize(path.name, apis)
    return 0


if __name__ == "__main__":
    sys.exit(main())
