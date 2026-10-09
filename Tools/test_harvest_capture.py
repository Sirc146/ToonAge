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

L.execute("""
LAYOUT_LOG = {}
ToonAge.modules.DataHarvester:Render({}, nil)
ToonAge.Harvester:ClearCharacter()
""")
lay = [L.eval("LAYOUT_LOG")[i] for i in range(1, len(L.eval("LAYOUT_LOG")) + 1)]
check("reset offers a per-character clear and a full clear",
      ("Clear this character" in "\n".join(lay)) and ("Clear store" in "\n".join(lay)))
check("clear this character drops only that character",
      (L.eval("ToonAge.db.harvest.captures[KEY]"),
       L.eval("ToonAge.db.harvest.captures[HUNT].probe.text")),
      (None, "hunt-probe"))
L.execute("ToonAge.Harvester:Clear()")
check("clear store drops every character",
      L.eval("ToonAge.db.harvest"), None)

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
