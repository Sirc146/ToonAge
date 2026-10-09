#!/usr/bin/env python3
"""Per-character harvest captures overwrite; other characters stay.

A second scan of the same character replaces that scan type. Trainer captures
record the NPC. Export defaults to the current character and starts with the
source line. Clear this character leaves everyone else.

Usage:  python3 Tools/test_harvest_capture.py [-v]
"""
import os
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


LOAD = [
    "Core/Caps.lua",
    "Modules/Infrastructure/HarvestFormat.lua",
    "Modules/Infrastructure/Harvester.lua",
    "Modules/Harvest/Domains/Character.lua",
    "Modules/Harvest/Domains/Items.lua",
    "Modules/Harvest/Domains/Racials.lua",
    "Modules/Harvest/Domains/Spellbook.lua",
    "Modules/Harvest/Domains/TraitTree.lua",
    "Modules/Harvest/Domains/Trainer.lua",
    "Modules/Harvest/Packs/Forever.lua",
]


def world():
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(read("Tools/fixtures/harvest_world_forever.lua"))
    for f in LOAD:
        L.execute(read(f))
    L.execute(r"""
ToonAge.db = { harvest = {
    version = 3,
    client = { flavor = "forever", build = "70205", interface = 16001, channel = "unknown" },
    times = {}, items = {}, spells = {}, talents = {}, chars = {}, racials = {},
    talentGeo = {}, counts = {}, trainer = {}, catalog = {},
} }
""")
    return L


def lines_of(L):
    text = L.eval("WINDOWS_LOG[#WINDOWS_LOG].text")
    return text.splitlines()


L = world()
L.execute("""
ToonAge.modules.DataHarvester:Init()
ToonAge.modules.DataHarvester:OnEnterWorld()
ToonAge.modules.DataHarvester:OnEvent('TRAINER_SHOW')
FLUSH()
KEY = ToonAge.Harvester:CharacterKey()
""")
key = L.eval("KEY")
check("capture key is realm, name and class",
      key, "Classic Beta PvE\tEramali\tMAGE")

cap = L.eval("ToonAge.db.harvest.captures[KEY]")
check("spellbook capture stored the current book",
      cap.spellbook.rows["133"].split("\t")[0], "Fireball")
check("spellbook stamp is this run",
      (cap.spellbook.version, cap.spellbook.build, cap.spellbook.level, cap.spellbook.timestamp),
      ("1.60.1", "70205", 18, 1791160000))
check("talent capture stored the spent rank",
      cap.talents.rows["MAGE:T:1112:105795"].split("\t")[5], "5")
check("trainer capture names the NPC, its id and the class",
      (cap.trainer.npcName, cap.trainer.npcID, cap.trainer["class"]),
      ("Aelthalyste", "5490", "MAGE"))
check("trainer rows are this visit",
      cap.trainer.rows["133"].split("\t")[0], "Fireball")
check("every rank is kept, including the ones past the level cap",
      sorted(cap.trainer.rows.keys()), ["133", "3140", "7322", "8400"])
check("each row records its service type",
      (cap.trainer.rows["133"].split("\t")[3], cap.trainer.rows["3140"].split("\t")[3],
       cap.trainer.rows["8400"].split("\t")[3], cap.trainer.rows["7322"].split("\t")[3]),
      ("used", "available", "unavailable", "unavailable"))
check("the read turned all three filters on, then put them back",
      [L.eval("TRAINER_FILTER_SETS")[i] for i in range(1, len(L.eval("TRAINER_FILTER_SETS")) + 1)],
      ["available=1", "unavailable=1", "used=1", "available=1", "unavailable=0", "used=1"])
check("the player's filters are back before the call returns",
      (L.eval("TRAINER_FILTER.available"), L.eval("TRAINER_FILTER.unavailable"), L.eval("TRAINER_FILTER.used")),
      (True, False, True))
check("the status line says the filters were restored",
      "filters=restored" in L.eval("ToonAge.db.harvest.trainerApi"))

# Change a value and scan again. The saved capture must move; the first value goes.
L.execute(r"""
SPELL[133][1] = "Fireball Plus"
NODES[105795].rank = 9
TRAINER[1][1] = "Fireball Plus"
ToonAge.Harvester:SaveCapture("selftest", { marker = "one" })
FIRST = ToonAge.db.harvest.captures[KEY].selftest.marker
ToonAge.modules.DataHarvester:OnEvent('SPELLS_CHANGED')
ToonAge.modules.DataHarvester:OnEvent('TRAIT_CONFIG_UPDATED')
ToonAge.modules.DataHarvester:OnEvent('TRAINER_SHOW')
FLUSH()
ToonAge.Harvester:SaveCapture("selftest", { marker = "two" })
SECOND = ToonAge.db.harvest.captures[KEY].selftest.marker
""")
cap = L.eval("ToonAge.db.harvest.captures[KEY]")
check("self-test first capture was recorded", L.eval("FIRST"), "one")
check("self-test second capture replaced it", L.eval("SECOND"), "two")
check("saved self-test value is the second run", cap.selftest.marker, "two")
check("spellbook capture updated the changed spell",
      cap.spellbook.rows["133"].split("\t")[0], "Fireball Plus")
check("pooled spellbook updated too",
      L.eval("ToonAge.db.harvest.spells['MAGE:133']").split("\t")[0], "Fireball Plus")
check("talent capture updated the changed rank",
      cap.talents.rows["MAGE:T:1112:105795"].split("\t")[5], "9")
check("trainer capture updated the changed service",
      cap.trainer.rows["133"].split("\t")[0], "Fireball Plus")
check("trainer NPC stayed on the new visit",
      (cap.trainer.npcName, cap.trainer.npcID), ("Aelthalyste", "5490"))

# Closing the trainer window (0 services) must not wipe the capture.
L.execute("""
function GetNumTrainerServices() return 0 end
ToonAge.modules.DataHarvester:OnEvent('TRAINER_UPDATE')
FLUSH()
""")
check("a closed trainer window does not wipe the capture",
      L.eval("ToonAge.db.harvest.captures[KEY].trainer.npcName"), "Aelthalyste")
check("closing the window still restores the filters",
      L.eval("TRAINER_FILTER.unavailable"), False)

# A profession visit must not replace the class trainer capture.
L.execute(r"""
function GetNumTrainerServices() return #TRAINER end
TRAINER = { { "Apprentice Mining", "available", 0, 2575 }, { "Smelt Copper", "available", 0, 2657 } }
ToonAge.modules.DataHarvester:OnEvent('TRAINER_SHOW')
FLUSH()
""")
check("a profession visit leaves the class trainer capture",
      L.eval("ToonAge.db.harvest.captures[KEY].trainer.npcName"), "Aelthalyste")
check("a profession visit is not filed on the class",
      L.eval("ToonAge.db.harvest.trainer.MAGE") and "2657" not in list(L.eval("ToonAge.db.harvest.trainer.MAGE").keys()))

# Another character already in the store stays while this one is overwritten.
# Caps caches the resolved UnitName, so the other character is a saved entry,
# the same shape a previous character leaves behind.
L.execute(r"""
HUNT = "Classic Beta PvE\tHuntsman\tHUNTER"
ToonAge.db.harvest.captures[HUNT] = {
    realm = "Classic Beta PvE", name = "Huntsman", class = "HUNTER", className = "Hunter",
    probe = { text = "hunt-probe", version = "1.60.1", build = "70205",
              level = 40, when = "2026-10-01 00:00", timestamp = 1, class = "HUNTER" },
}
ToonAge.Harvester:SaveCapture("selftest", { marker = "three" })
""")
check("hunter key is separate", L.eval("HUNT"), "Classic Beta PvE\tHuntsman\tHUNTER")
check("hunter capture survived the mage's next run",
      L.eval("ToonAge.db.harvest.captures[HUNT].probe.text"), "hunt-probe")
check("mage self-test is the newest value",
      L.eval("ToonAge.db.harvest.captures[KEY].selftest.marker"), "three")

L.execute("WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:Export('trainer', 1)")
body = lines_of(L)
check("trainer export starts with this character",
      body[0].startswith("-- source Eramali · Mage · level 18 · build 70205 · captured "))
check("trainer export names the NPC",
      body[1], "-- trainer Aelthalyste · id 5490 · class MAGE")
check("trainer export is this character's updated row",
      any(x.startswith("133\t") and "Fireball Plus" in x for x in body))
check("trainer export does not include the hunter",
      all("Huntsman" not in x for x in body))

L.execute("WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:Export('spells', 1, 'all')")
all_body = "\n".join(lines_of(L))
check("all-characters export includes the mage source line",
      "-- source Eramali · Mage · level 18 · build 70205 · captured " in all_body)
# Hunter has no spellbook capture, only a probe, so the spell export is mage-only.
check("all-characters spell export has the updated spell", "Fireball Plus" in all_body)

L.execute("WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:RunProbes()")
probe = "\n".join(lines_of(L))
check("probe export starts with the source line",
      probe.startswith("-- source Eramali · Mage · level 18 · build 70205 · captured "))
check("probe capture replaced the scratch marker slot's sibling and stored text",
      type(L.eval("ToonAge.db.harvest.captures[KEY].probe.text")) is str
      and "Client" in L.eval("ToonAge.db.harvest.captures[KEY].probe.text"))

L.execute("WINDOWS_LOG = {}; ToonAge.Harvester:ExportCapture('probe', 'all', 0)")
both = "\n".join(lines_of(L))
check("all probe exports include both characters",
      ("-- source Eramali · Mage · " in both) and ("-- source Huntsman · Hunter · " in both))
check("hunter probe text is in the all-characters export", "hunt-probe" in both)

chat = "\n".join(L.eval("CHAT_LOG")[i] for i in range(1, len(L.eval("CHAT_LOG")) + 1))
check("trainer capture toasts the NPC and the spell count",
      "Harvest: trainer saved (Aelthalyste, 4 spells)" in chat)
check("login full scan toasts once", "Harvest: scan saved (Eramali)" in chat)
check("skills capture replaced this character's entry",
      L.eval("ToonAge.db.harvest.captures[KEY].skills.rows['1']").split("\t")[0], "Skill1")
check("professions capture stored the client rows",
      L.eval("ToonAge.db.harvest.captures[KEY].professions.rows['107']").split("\t")[0], "Prof7")
check("heirlooms capture says this client has none",
      L.eval("ToonAge.db.harvest.captures[KEY].heirlooms.note"), "not on this client")
check("catalog capture is this character's ranked pass",
      "Rank 1" in L.eval("ToonAge.db.harvest.captures[KEY].catalog.rows['133']"))

# A second spellbook event inside 10 seconds waits; it still runs once the window ends.
L.execute(r"""
GT = 5000
function GetTime() return GT end
CHAT_LOG = {}
TIMERS = {}
ToonAge.modules.DataHarvester:OnEvent('SPELLS_CHANGED')
FIRST_TOASTS = #CHAT_LOG
QUEUED = #TIMERS
SPELL[133][1] = "Fireball Later"
GT = 5000
ToonAge.modules.DataHarvester:OnEvent('SPELLS_CHANGED')
SECOND_QUEUED = #TIMERS
BEFORE = ToonAge.db.harvest.captures[KEY].spellbook.rows['133']
FLUSH()
AFTER = ToonAge.db.harvest.captures[KEY].spellbook.rows['133']
""")
check("the first spellbook event in a window saves immediately", L.eval("FIRST_TOASTS") >= 1)
check("a second spellbook event inside 10 seconds is queued", L.eval("SECOND_QUEUED") > L.eval("QUEUED"))
check("the queued spellbook scan is the later book",
      L.eval("AFTER").split("\t")[0], "Fireball Later")

L.execute(r"""
function InCombatLockdown() return true end
CHAT_LOG = {}
TIMERS = {}
ToonAge.Harvester:StartScan()
QUEUED_FLAG = ToonAge.Harvester._scanQueued
TIMERS_IN_COMBAT = #TIMERS
function InCombatLockdown() return false end
ToonAge.modules.DataHarvester:OnEvent('PLAYER_REGEN_ENABLED')
TIMERS_AFTER = #TIMERS
FLUSH()
DONE = ToonAge.Harvester._scanRunning
""")
check("scan now waits out combat", L.eval("QUEUED_FLAG"), True)
check("scan now does not start a frame while in combat", L.eval("TIMERS_IN_COMBAT"), 0)
check("leaving combat starts the queued scan", L.eval("TIMERS_AFTER") >= 1)
check("the queued scan finishes", L.eval("DONE"), False)
check("combat queue says so",
      "Harvest: scan queued until combat ends" in "\n".join(
          L.eval("CHAT_LOG")[i] for i in range(1, len(L.eval("CHAT_LOG")) + 1)))

L.execute(r"""
ToonAge.db.harvestToast = false
GT = GT + 20
CHAT_LOG = {}
ToonAge.modules.DataHarvester:OnEvent('SKILL_LINES_CHANGED')
QUIET = table.concat(CHAT_LOG, "\n")
ToonAge.db.harvestToast = nil
""")
check("notices off swallows the professions line", "Harvest:" not in L.eval("QUIET"))
check("a skill-line change still saved professions",
      L.eval("ToonAge.db.harvest.captures[KEY].professions ~= nil"), True)

L.execute("""
LAYOUT_LOG = {}
ALL_BUTTONS = {}
ToonAge.modules.DataHarvester:Render({}, nil)
""")
lay = [L.eval("LAYOUT_LOG")[i] for i in range(1, len(L.eval("LAYOUT_LOG")) + 1)]
check("reset offers a per-character clear and a full clear",
      ("Clear this character" in "\n".join(lay)) and ("Clear store" in "\n".join(lay)))
check("both reset buttons use the danger style",
      ("ButtonDanger|Clear this character" in lay) and ("ButtonDanger|Clear store" in lay))
check("the scope switch reads This character · All characters",
      "ButtonRow|This character,All characters|This character · All characters" in lay)
check("the scope switch defaults to this character", "ButtonActive|This character" in lay)
check("scan now is the gold button", "ButtonGold|Scan now" in lay)
check("a trainer this character has visited is counted",
      "DataRow|Trainer ranks (open a class trainer)|4" in lay)
check("last scanned sits on the scan row",
      any(x.startswith("ButtonRow|Scan now,Notices on|") and x.endswith("|Last scanned 12:26 AM") for x in lay))
L.execute("""
for _, b in ipairs(ALL_BUTTONS) do
    if b.label == "All characters" then b.onClick() end
end
""")
check("the switch can show every character", L.eval("ToonAge.modules.DataHarvester:View()"), "all")
L.execute("""
for _, b in ipairs(ALL_BUTTONS) do
    if b.label == "This character" then b.onClick() end
end
""")
check("the switch returns to this character", L.eval("ToonAge.modules.DataHarvester:View()"), "character")
L.execute("""
for _, b in ipairs(LAST_BUTTONS) do
    if b.label == "Clear this character" then b.onClick() end
end
LAYOUT_LOG = {}
ToonAge.modules.DataHarvester:Render({}, nil)
""")
armed = [L.eval("LAYOUT_LOG")[i] for i in range(1, len(L.eval("LAYOUT_LOG")) + 1)]
check("confirmation names this character and class",
      "ButtonDanger|Clear saved data for Eramali (Mage)?" in armed)
check("the confirmation has not removed anyone yet",
      (L.eval("ToonAge.db.harvest.captures[KEY].name"),
       L.eval("ToonAge.db.harvest.captures[HUNT].probe.text")),
      ("Eramali", "hunt-probe"))
L.execute("""
for _, b in ipairs(LAST_BUTTONS) do
    if b.label == "Clear saved data for Eramali (Mage)?" then b.onClick() end
end
""")
check("confirming removes only that character",
      (L.eval("ToonAge.db.harvest.captures[KEY]"),
       L.eval("ToonAge.db.harvest.captures[HUNT].probe.text")),
      (None, "hunt-probe"))
L.execute("ToonAge.Harvester:Clear()")
check("clear store drops every character",
      L.eval("ToonAge.db.harvest"), None)

# The setter fires TRAINER_UPDATE before it returns. That event is the same
# read: it must not queue another widen.
Lr = world()
Lr.execute(r"""
local real = SetTrainerServiceTypeFilter
SetTrainerServiceTypeFilter = function(kind, on)
    real(kind, on)
    ToonAge.modules.DataHarvester:OnEvent("TRAINER_UPDATE")
end
ToonAge.modules.DataHarvester:Init()
TIMERS = {}
ToonAge.modules.DataHarvester:OnEvent("TRAINER_SHOW")
KEY = ToonAge.Harvester:CharacterKey()
""")
lr_rows = Lr.eval("ToonAge.db.harvest.captures[KEY].trainer.rows")
check("a filter write's TRAINER_UPDATE does not queue another read", Lr.eval("#TIMERS"), 0)
check("filters are back in that same call",
      (Lr.eval("TRAINER_FILTER.available"), Lr.eval("TRAINER_FILTER.unavailable"), Lr.eval("TRAINER_FILTER.used")),
      (True, False, True))
check("that same call still kept the hidden ranks",
      (lr_rows["8400"].split("\t")[3], lr_rows["7322"].split("\t")[3]),
      ("unavailable", "unavailable"))

# Either function missing: do not touch the filters, and do not invent the
# rows they were hiding.
Ls = world()
Ls.execute(r"""
SetTrainerServiceTypeFilter = nil
ToonAge.modules.DataHarvester:Init()
ToonAge.modules.DataHarvester:OnEvent("TRAINER_SHOW")
FLUSH()
KEY = ToonAge.Harvester:CharacterKey()
""")
ls_rows = Ls.eval("ToonAge.db.harvest.captures[KEY].trainer.rows")
check("without the setter, a hidden rank is left unread", ls_rows["8400"], None)
check("without the setter, the ranks on screen are still recorded",
      (ls_rows["133"].split("\t")[3], ls_rows["3140"].split("\t")[3]), ("used", "available"))
check("without the setter, the unavailable filter stays off",
      Ls.eval("TRAINER_FILTER.unavailable"), False)
check("without the setter, the status line says the step was skipped",
      "filters=skipped" in Ls.eval("ToonAge.db.harvest.trainerApi"))

Lg = world()
Lg.execute(r"""
GetTrainerServiceTypeFilter = nil
SET_CALLS = 0
local real = SetTrainerServiceTypeFilter
SetTrainerServiceTypeFilter = function(kind, on)
    SET_CALLS = SET_CALLS + 1
    return real(kind, on)
end
ToonAge.modules.DataHarvester:Init()
ToonAge.modules.DataHarvester:OnEvent("TRAINER_SHOW")
FLUSH()
KEY = ToonAge.Harvester:CharacterKey()
""")
lg_rows = Lg.eval("ToonAge.db.harvest.captures[KEY].trainer.rows")
check("without the getter, the setter is never called", Lg.eval("SET_CALLS"), 0)
check("without the getter, the hidden rank stays hidden", lg_rows["8400"], None)
check("without the getter, the player's filters are untouched",
      (Lg.eval("TRAINER_FILTER.available"), Lg.eval("TRAINER_FILTER.unavailable"), Lg.eval("TRAINER_FILTER.used")),
      (True, False, True))

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
