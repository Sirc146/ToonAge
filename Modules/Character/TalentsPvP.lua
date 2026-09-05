-- ToonAge/Modules/TalentsPvP.lua
-- PvP Talent Advisor — modern C_Traits API approach.
-- Reads the live talent tree structure, overlays PvP recommendations,
-- shows why/alternative explanations, PvE vs PvP comparison.
--
-- Architecture:
--   • Reads tree from C_Traits.GetTreeNodes / GetNodeInfo / GetEntryInfo
--   • Renders as a scrollable node list grouped by panel tabs
--   • Panels: Class Tree | Spec Tree | Hero Talents | PvP Talents
--   • Each node shows: icon, name, recommended/active state, why text
--   • Bottom bar: level-scaled "next talent" advisor
--
-- Accessed via the existing Talents module "PvP" build type button,
-- or directly via /ta pvp.

local TA   = ToonAge
local U    = TA.Utils
local TAPI = TA.TalentsAPI
local PVPD  = nil  -- resolved in Init (TA.Data.TalentsPvP)
local PVPMD = nil  -- resolved in Init (TA.Data.PvPMatchups)

local TalentsPvP = {}
TA:RegisterModule("TalentsPvP", TalentsPvP)

-- ── State ─────────────────────────────────────────────────────────────────────
TalentsPvP.frames      = {}
TalentsPvP.activePanel = "spec"   -- "class" | "spec" | "hero" | "pvp"
TalentsPvP.treeCache   = nil      -- cached tree node data
TalentsPvP.specID      = nil

-- ── Constants ─────────────────────────────────────────────────────────────────
local PANEL_TABS = {
    { key = "class",    label = "Class Tree" },
    { key = "spec",     label = "Spec Tree" },
    { key = "hero",     label = "Hero Talents" },
    { key = "pvp",      label = "PvP Talents" },
    { key = "matchups", label = "Matchups" },
}

-- WoW class token -> display name, used for the Matchups panel. Uses the
-- localized name where available (LOCALIZED_CLASS_NAMES_MALE) so the panel
-- reads naturally in any client locale, falling back to the raw token.
local function ClassDisplayName(classToken)
    local names = LOCALIZED_CLASS_NAMES_MALE
    return (names and names[classToken]) or classToken
end

-- Class-colored text helper for the Matchups panel, using Blizzard's own
-- RAID_CLASS_COLORS table (falls back to plain gold if unavailable).
local function ColorizeClass(classToken)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local label = ClassDisplayName(classToken)
    if c and c.colorStr then
        return "|c" .. c.colorStr .. label .. "|r"
    end
    return COL_GOLD .. label .. CLOSE
end

local COL_GOLD   = "|cFFFFD100"
local COL_GREEN  = "|cFF4AFF7A"
local COL_ORANGE = "|cFFFF9A1A"
local COL_GREY   = "|cFF888780"
local COL_RED    = "|cFFFF4444"
local COL_BLUE   = "|cFF4AAFFF"
local CLOSE      = "|r"

local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- ── Tree reading via C_Traits (modern API) ────────────────────────────────────

--- Get the active config and ALL tree IDs for the current character.
--- A config can expose more than one tree (e.g. a combined class/spec tree
--- plus a separate hero-talent subtree) — reading only treeIDs[1] silently
--- drops any nodes that live in the others.
local function GetActiveTreeInfo()
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
        return nil, nil
    end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil, nil end

    local treeIDs = nil
    if C_Traits and C_Traits.GetConfigInfo then
        local info = C_Traits.GetConfigInfo(configID)
        if info and info.treeIDs and #info.treeIDs > 0 then
            treeIDs = info.treeIDs
        end
    end
    return configID, treeIDs
end

--- Read all nodes from every tree in treeIDs, categorized by subTreeID / type.
--- Returns: { class={}, spec={}, hero={} } where each is an array of node info tables
local function ReadTreeNodes(configID, treeIDs)
    if not C_Traits or not treeIDs or #treeIDs == 0 then return nil end

    local result = { class = {}, spec = {}, hero = {} }
    local seen = {}  -- de-dupe nodeIDs that might appear in more than one tree

    for _, treeID in ipairs(treeIDs) do
      local allNodeIDs = C_Traits.GetTreeNodes(treeID)
      if allNodeIDs then
        for _, nodeID in ipairs(allNodeIDs) do
          if not seen[nodeID] then
            seen[nodeID] = true
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if nodeInfo and nodeInfo.ID and nodeInfo.ID ~= 0 then
            -- Read entry info for name/icon
            local entryIDs = nodeInfo.entryIDs
            local entries = {}
            if entryIDs then
                for _, entryID in ipairs(entryIDs) do
                    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                    if entryInfo then
                        local defInfo = entryInfo.definitionID
                            and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        local spellName, spellIcon
                        if defInfo and defInfo.spellID then
                            spellName = C_Spell.GetSpellName(defInfo.spellID)
                            local spellInfo = C_Spell.GetSpellInfo(defInfo.spellID)
                            spellIcon = spellInfo and spellInfo.iconID
                        end
                        table.insert(entries, {
                            entryID      = entryID,
                            definitionID = entryInfo.definitionID,
                            spellID      = defInfo and defInfo.spellID,
                            name         = (defInfo and defInfo.overrideName)
                                           or spellName
                                           or "Unknown",
                            icon         = (defInfo and defInfo.overrideIcon)
                                           or spellIcon
                                           or 134400,
                        })
                    end
                end
            end

            local node = {
                nodeID       = nodeID,
                posX         = nodeInfo.posX or 0,
                posY         = nodeInfo.posY or 0,
                isActive     = (nodeInfo.activeRank and nodeInfo.activeRank > 0),
                activeRank   = nodeInfo.activeRank or 0,
                maxRanks     = nodeInfo.maxRanks or 1,
                isChoice     = (#entries > 1),
                activeEntry  = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID,
                subTreeID    = nodeInfo.subTreeID,
                entries      = entries,
                -- Determine panel category
                -- subTreeID > 0 indicates hero talent subtree
                -- Otherwise we use posY ranges: class nodes are top, spec nodes bottom
                -- This heuristic works for all current talent trees
            }

            -- Categorize
            if nodeInfo.subTreeID and nodeInfo.subTreeID > 0 then
                table.insert(result.hero, node)
            elseif nodeInfo.isClassNode then
                table.insert(result.class, node)
            else
                table.insert(result.spec, node)
            end
            end -- if nodeInfo and nodeInfo.ID ~= 0
          end -- if not seen[nodeID]
        end -- for nodeID in allNodeIDs
      end -- if allNodeIDs
    end -- for treeID in treeIDs

    -- Sort each panel by Y position (top to bottom) then X (left to right)
    local function SortNodes(a, b)
        if a.posY ~= b.posY then return a.posY < b.posY end
        return a.posX < b.posX
    end
    table.sort(result.class, SortNodes)
    table.sort(result.spec,  SortNodes)
    table.sort(result.hero,  SortNodes)

    return result
end

--- Get active PvP talent spell IDs
local function GetActivePvPTalents()
    if not C_SpecializationInfo or not C_SpecializationInfo.GetAllSelectedPvpTalentIDs then
        return {}
    end
    local ok, ids = pcall(C_SpecializationInfo.GetAllSelectedPvpTalentIDs)
    if ok and ids then return ids end
    return {}
end

--- Get available PvP talents for current spec
local function GetAvailablePvPTalents()
    if not C_SpecializationInfo or not C_SpecializationInfo.GetPvpTalentSlotInfo then
        return {}
    end
    local talents = {}
    for slot = 1, 3 do
        local ok, slotInfo = pcall(C_SpecializationInfo.GetPvpTalentSlotInfo, slot)
        if ok and slotInfo and slotInfo.availableTalentIDs then
            for _, talentID in ipairs(slotInfo.availableTalentIDs) do
                local tok, info = pcall(C_PvP.GetPvpTalentInfoByID or C_SpecializationInfo.GetPvpTalentInfoByID, talentID)
                if tok and info then
                    table.insert(talents, {
                        talentID = talentID,
                        spellID  = info.spellID,
                        name     = info.name or C_Spell.GetSpellName(info.spellID) or "?",
                        icon     = info.icon or (C_Spell.GetSpellInfo(info.spellID) and C_Spell.GetSpellInfo(info.spellID).iconID) or 134400,
                        slot     = slot,
                        selected = info.selected or false,
                    })
                end
            end
        end
    end
    return talents
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- RENDERING
-- ═══════════════════════════════════════════════════════════════════════════════

function TalentsPvP:Render(content, sidebar, startY)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    PVPD  = TA.Data.TalentsPvP    -- resolve reference
    PVPMD = TA.Data.PvPMatchups   -- resolve reference

    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID, specName = GetSpecializationInfo(specIndex)
    if not specID then return end
    self.specID = specID

    local configID, treeIDs = GetActiveTreeInfo()

    -- Read tree if not cached or spec changed
    if configID and treeIDs then
        self.treeCache = ReadTreeNodes(configID, treeIDs)
    end

    local padL = 10
    -- startY is passed by Talents.lua when embedded below its own header +
    -- build-type row (shares the same content frame); default to -10 for
    -- the standalone /ta pvp entry point where nothing is drawn above it.
    local y    = startY or -10
    local w    = content:GetWidth() - 20

    local function Track(f) table.insert(self.frames, f); return f end

    -- ── Header ────────────────────────────────────────────────────────────
    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    hdr:SetText(COL_GOLD .. "PVP TALENT ADVISOR" .. CLOSE .. "  " .. COL_GREY .. specName .. CLOSE)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 20

    -- Hero spec recommendation
    local pvpData = PVPD and PVPD:GetForSpec(specID)
    if pvpData and pvpData.heroSpec then
        local heroLbl = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        heroLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        heroLbl:SetText(COL_BLUE .. "Recommended Hero: " .. CLOSE .. COL_GOLD .. pvpData.heroSpec .. CLOSE)
        heroLbl:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        y = y - 18
    end

    -- Separator
    local sep = Track(content:CreateTexture(nil, "ARTWORK"))
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
    sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    sep:SetColorTexture(0.55, 0.40, 0.08, 0.3)
    y = y - 16

    -- ── Panel tab bar ─────────────────────────────────────────────────────
    local tabW = math.floor(w / #PANEL_TABS) - 2
    local tx   = padL
    for _, tab in ipairs(PANEL_TABS) do
        local active = (self.activePanel == tab.key)
        local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
        btn:SetSize(tabW, 24)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", tx, y)
        btn:SetBackdrop(BD)
        if active then
            btn:SetBackdropColor(0.12, 0.09, 0.00, 1)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        else
            btn:SetBackdropColor(0.04, 0.04, 0.04, 1)
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
        end
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        lbl:SetText(tab.label)
        lbl:SetTextColor(active and 1 or 0.5, active and 0.82 or 0.4, active and 0 or 0.2, 1)
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        btn:SetScript("OnClick", function()
            self.activePanel = tab.key
            -- Must re-pass startY (captured as an upvalue from this Render call)
            -- or it defaults to -10, redrawing this entire panel — header, hero
            -- recommendation, and tab bar included — back at the top of the
            -- content frame, on top of Talents.lua's own header/build-type row
            -- that's still sitting there above it. That was the exact overlap
            -- bug reported when clicking between Class/Spec/Hero/PvP Talent tabs.
            self:Render(content, sidebar, startY)
        end)
        Track(btn)
        tx = tx + tabW + 3
    end
    y = y - 32

    -- ── Panel content ─────────────────────────────────────────────────────
    if self.activePanel == "pvp" then
        y = self:RenderPvPTalentPanel(content, y, w, padL, pvpData)
    elseif self.activePanel == "matchups" then
        y = self:RenderMatchupsPanel(content, y, w, padL, specID)
    elseif self.treeCache then
        local nodes = self.treeCache[self.activePanel]
        if nodes and #nodes > 0 then
            y = self:RenderTreePanel(content, y, w, padL, nodes, pvpData)
        else
            local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
            nodata:SetFont(STANDARD_TEXT_FONT, 10)
            nodata:SetText(COL_GREY .. "No tree data available. Open your talent frame first to load tree info." .. CLOSE)
            nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            nodata:SetWidth(w)
            y = y - 30
        end
    else
        local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        nodata:SetFont(STANDARD_TEXT_FONT, 10)
        nodata:SetText(COL_GREY .. "C_Traits data unavailable. Open talent frame (N) once to populate." .. CLOSE)
        nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        nodata:SetWidth(w)
        y = y - 30
    end

    -- ── Level-scaled next talent advisor (bottom) ─────────────────────────
    y = y - 8
    y = self:RenderLevelAdvisor(content, y, w, padL, pvpData)

    -- ── Import string button ──────────────────────────────────────────────
    if pvpData then
        local importStr = PVPD:GetImportString(specID)
        if importStr then
            y = y - 10
            local cpBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
            cpBtn:SetSize(200, 26)
            cpBtn:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            cpBtn:SetBackdrop(BD)
            cpBtn:SetBackdropColor(0.10, 0.08, 0.00, 1)
            cpBtn:SetBackdropBorderColor(1, 0.82, 0, 0.6)
            Track(cpBtn)
            local cpLbl = cpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cpLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            cpLbl:SetText("Copy PvP Import String")
            cpLbl:SetTextColor(1, 0.82, 0, 1)
            cpLbl:SetAllPoints(cpBtn)
            cpLbl:SetJustifyH("CENTER")
            cpBtn:SetScript("OnClick", function()
                local Talents = TA:GetModule("Talents")
                if Talents and Talents.OpenSafeCopyFrame then
                    Talents:OpenSafeCopyFrame("PvP Build", importStr)
                elseif CopyToClipboard then
                    CopyToClipboard(importStr)
                    TA:Raw(TA.LOG.OUTPUT, COL_GREEN .. "[TA]" .. CLOSE .. " PvP talent string copied to clipboard.")
                end
            end)
            y = y - 32
        end
    end

    content:SetHeight(math.abs(y) + 20)
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- TREE PANEL RENDERING
-- ═══════════════════════════════════════════════════════════════════════════════

--- Renders a list of talent nodes with PvP recommendation overlay
function TalentsPvP:RenderTreePanel(content, startY, w, padL, nodes, pvpData)
    local y = startY
    local function Track(f) table.insert(self.frames, f); return f end

    local NODE_H     = 52
    local ICON_SIZE  = 28
    local MAX_SHOWN  = 40  -- cap for performance

    local shown = 0
    for _, node in ipairs(nodes) do
        if shown >= MAX_SHOWN then break end

        -- Skip nodes with no entries (gates, etc.)
        if not node.entries or #node.entries == 0 then
            -- skip
        else
            shown = shown + 1

            -- Determine recommendation status from PvP data.
            -- IMPORTANT: PvP data is authored by spellID, not nodeID. Real talent-tree
            -- nodeIDs can only be captured from a live client (C_Traits), so the data
            -- file can't ship them pre-populated — every spec's `nodes` table used to
            -- be keyed by a placeholder [0] that node.nodeID (always a real, non-zero
            -- Blizzard ID in-game) could never match, silently disabling the entire
            -- "Why/Take this" overlay for every spec. Matching against each entry's
            -- spellID instead works immediately, since spell IDs are the same for
            -- everyone and can be sourced from Wowhead/icy-veins ahead of time.
            local pvpInfo = nil
            if pvpData and pvpData.nodes then
                for _, e in ipairs(node.entries) do
                    if e.spellID and pvpData.nodes[e.spellID] then
                        pvpInfo = pvpData.nodes[e.spellID]
                        break
                    end
                end
            end
            local isRecommended = (pvpInfo ~= nil)
            local isActive = node.isActive

            -- Node card
            local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
            card:SetSize(w, NODE_H)
            card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            card:SetBackdrop(BD)

            -- Color based on state
            if isRecommended and isActive then
                -- Correct choice active
                card:SetBackdropColor(0.02, 0.06, 0.02, 1)
                card:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.6)
            elseif isRecommended and not isActive then
                -- Recommended but not taken
                card:SetBackdropColor(0.06, 0.04, 0.00, 1)
                card:SetBackdropBorderColor(1, 0.82, 0, 0.7)
            elseif isActive then
                -- Active but not specifically recommended (neutral)
                card:SetBackdropColor(0.04, 0.04, 0.04, 1)
                card:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.4)
            else
                -- Inactive, not recommended
                card:SetBackdropColor(0.03, 0.03, 0.03, 0.7)
                card:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.3)
            end
            Track(card)

            -- Icon (first entry or active entry)
            local displayEntry = node.entries[1]
            if node.isChoice and node.activeEntry then
                for _, e in ipairs(node.entries) do
                    if e.entryID == node.activeEntry then
                        displayEntry = e; break
                    end
                end
            end

            local icon = card:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -((NODE_H - ICON_SIZE) / 2))
            icon:SetTexture(displayEntry.icon or 134400)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not isActive then icon:SetDesaturated(true); icon:SetAlpha(0.6) end

            -- Name
            local nameTxt = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameTxt:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            local nameStr = displayEntry.name or "?"
            if node.isChoice then
                -- Show both choices
                local names = {}
                for _, e in ipairs(node.entries) do
                    local prefix = (e.entryID == node.activeEntry) and COL_GREEN or COL_GREY
                    table.insert(names, prefix .. (e.name or "?") .. CLOSE)
                end
                nameStr = table.concat(names, " / ")
            end
            nameTxt:SetText(nameStr)
            nameTxt:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + ICON_SIZE + 8, -6)
            nameTxt:SetWidth(w - ICON_SIZE - 50)
            nameTxt:SetWordWrap(false)

            -- Status badge (right side)
            local badge = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            badge:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            badge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -6)
            if isRecommended and isActive then
                badge:SetText(COL_GREEN .. "✓ PvP" .. CLOSE)
            elseif isRecommended then
                badge:SetText(COL_ORANGE .. "← Take" .. CLOSE)
            elseif isActive then
                badge:SetText(COL_GREY .. "Active" .. CLOSE)
            else
                badge:SetText("")
            end

            -- Why / Alt text (below name)
            if pvpInfo then
                local whyTxt = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                whyTxt:SetFont(STANDARD_TEXT_FONT, 9)
                whyTxt:SetText(COL_GOLD .. "Why: " .. CLOSE .. (pvpInfo.why or ""))
                whyTxt:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + ICON_SIZE + 8, -22)
                whyTxt:SetWidth(w - ICON_SIZE - 60)
                whyTxt:SetWordWrap(true)
                whyTxt:SetTextColor(0.72, 0.68, 0.52, 1)

                -- PvE comparison note
                if pvpInfo.pveNote then
                    local pveLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    pveLbl:SetFont(STANDARD_TEXT_FONT, 8)
                    pveLbl:SetText(COL_BLUE .. "PvE: " .. CLOSE .. pvpInfo.pveNote)
                    pveLbl:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8 + ICON_SIZE + 8, 4)
                    pveLbl:SetWidth(w - ICON_SIZE - 60)
                    pveLbl:SetWordWrap(false)
                    pveLbl:SetTextColor(0.45, 0.60, 0.80, 0.85)
                end
            elseif isActive and node.isChoice then
                -- Show a hint that this is an active choice node
                local activeLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                activeLbl:SetFont(STANDARD_TEXT_FONT, 8)
                activeLbl:SetText(COL_GREY .. "Active choice — no specific PvP recommendation yet." .. CLOSE)
                activeLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + ICON_SIZE + 8, -22)
            end

            y = y - NODE_H - 2
        end
    end

    return y
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- PVP TALENT PANEL (the 3 PvP talent slots)
-- ═══════════════════════════════════════════════════════════════════════════════

function TalentsPvP:RenderPvPTalentPanel(content, startY, w, padL, pvpData)
    local y = startY
    local function Track(f) table.insert(self.frames, f); return f end

    -- Header
    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    hdr:SetText(COL_GOLD .. "PVP TALENT SLOTS" .. CLOSE .. "  " .. COL_GREY .. "(3 active in War Mode / Instanced PvP)" .. CLOSE)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 18

    -- Get active PvP talents
    local activePvP = GetActivePvPTalents()
    local allPvP    = GetAvailablePvPTalents()

    if #allPvP == 0 then
        local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        nodata:SetFont(STANDARD_TEXT_FONT, 10)
        nodata:SetText(COL_GREY .. "PvP talent data unavailable. Enable War Mode or enter instanced PvP." .. CLOSE)
        nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        nodata:SetWidth(w)
        y = y - 24
        return y
    end

    -- Group by slot
    local slots = { {}, {}, {} }
    for _, talent in ipairs(allPvP) do
        local s = talent.slot
        if s >= 1 and s <= 3 then
            table.insert(slots[s], talent)
        end
    end

    for slotIdx = 1, 3 do
        -- Slot header
        local slotHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        slotHdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        slotHdr:SetText(COL_GREY .. "Slot " .. slotIdx .. CLOSE)
        slotHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        y = y - 14

        for _, talent in ipairs(slots[slotIdx]) do
            local isSelected = talent.selected
            local ROW_H = 32

            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(w, ROW_H)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            row:SetBackdrop(BD)
            if isSelected then
                row:SetBackdropColor(0.02, 0.06, 0.02, 1)
                row:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.5)
            else
                row:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
                row:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.2)
            end
            Track(row)

            -- Icon
            local ico = row:CreateTexture(nil, "ARTWORK")
            ico:SetSize(22, 22)
            ico:SetPoint("LEFT", row, "LEFT", 6, 0)
            ico:SetTexture(talent.icon)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not isSelected then ico:SetDesaturated(true); ico:SetAlpha(0.5) end

            -- Name — right edge always reserves room for the "Active" badge
            -- (even on unselected rows) so long talent names can't run under it.
            local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            nameLbl:SetText(talent.name)
            nameLbl:SetTextColor(isSelected and 0.29 or 0.55, isSelected and 1.0 or 0.50, isSelected and 0.48 or 0.40, 1)
            nameLbl:SetPoint("LEFT", row, "LEFT", 34, 0)
            nameLbl:SetPoint("RIGHT", row, "RIGHT", -75, 0)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetWordWrap(false)

            -- Selected badge
            if isSelected then
                local bdg = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                bdg:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
                bdg:SetText(COL_GREEN .. "● Active" .. CLOSE)
                bdg:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            end

            y = y - ROW_H - 1
        end
        y = y - 6
    end

    return y
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MATCHUPS PANEL — favorable/unfavorable class reference card
-- ═══════════════════════════════════════════════════════════════════════════════

--- Renders the current spec's favorable/unfavorable class matchup reference
--- (Warmode/arena/Solo Shuffle framing — "In Warmode it's always PvP").
function TalentsPvP:RenderMatchupsPanel(content, startY, w, padL, specID)
    local y = startY
    local function Track(f) table.insert(self.frames, f); return f end

    local data = PVPMD and PVPMD:GetForSpec(specID)

    local subhdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    subhdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    subhdr:SetText(COL_GREY .. "Who you're strong/weak against in Warmode, arena, and Solo Shuffle — and how to play the weak matchups." .. CLOSE)
    subhdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    subhdr:SetWidth(w)
    subhdr:SetJustifyH("LEFT")
    subhdr:SetWordWrap(true)
    y = y - subhdr:GetStringHeight() - 12

    if not data then
        local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        nodata:SetFont(STANDARD_TEXT_FONT, 10)
        nodata:SetText(COL_GREY .. "No matchup data available for this spec yet." .. CLOSE)
        nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        nodata:SetWidth(w)
        y = y - 24
        return y
    end

    -- ── Favorable ─────────────────────────────────────────────────────────
    if data.favorable and #data.favorable > 0 then
        local favHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        favHdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        favHdr:SetText(COL_GREEN .. "STRONG AGAINST" .. CLOSE)
        favHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        y = y - 18

        local list = {}
        for _, classToken in ipairs(data.favorable) do
            table.insert(list, ColorizeClass(classToken))
        end
        local favLine = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        favLine:SetFont(STANDARD_TEXT_FONT, 10)
        favLine:SetText(table.concat(list, COL_GREY .. "   •   " .. CLOSE))
        favLine:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        favLine:SetWidth(w)
        favLine:SetJustifyH("LEFT")
        favLine:SetWordWrap(true)
        y = y - favLine:GetStringHeight() - 16
    end

    -- ── Unfavorable + counters ───────────────────────────────────────────
    if data.unfavorable and #data.unfavorable > 0 then
        local unfHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        unfHdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        unfHdr:SetText(COL_RED .. "WEAK AGAINST — HOW TO COUNTER" .. CLOSE)
        unfHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        y = y - 20

        for _, entry in ipairs(data.unfavorable) do
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            row:SetBackdrop(BD)
            row:SetBackdropColor(0.07, 0.02, 0.02, 0.6)
            row:SetBackdropBorderColor(1, 0.27, 0.27, 0.3)
            Track(row)

            local classLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            classLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            classLbl:SetText(ColorizeClass(entry.class))
            classLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)

            local tipLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tipLbl:SetFont(STANDARD_TEXT_FONT, 9)
            tipLbl:SetText(COL_ORANGE .. "Counter: " .. CLOSE .. (entry.tip or ""))
            tipLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -22)
            tipLbl:SetWidth(w - 16)
            tipLbl:SetJustifyH("LEFT")
            tipLbl:SetWordWrap(true)

            local rowH = 22 + tipLbl:GetStringHeight() + 10
            row:SetSize(w, rowH)
            y = y - rowH - 6
        end
    end

    return y
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LEVEL-SCALED ADVISOR
-- ═══════════════════════════════════════════════════════════════════════════════

function TalentsPvP:RenderLevelAdvisor(content, startY, w, padL, pvpData)
    local y = startY
    local function Track(f) table.insert(self.frames, f); return f end

    local playerLevel = UnitLevel("player")
    local maxLevel    = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80

    if playerLevel >= maxLevel then
        -- At max level: show "you have all points" summary
        local maxLbl = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        maxLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        maxLbl:SetText(COL_GREEN .. "Max level reached" .. CLOSE .. " — all talent points available for PvP build.")
        maxLbl:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        maxLbl:SetWidth(w)
        y = y - 18
        return y
    end

    -- Leveling advisor card
    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetSize(w, 80)
    card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    card:SetBackdrop(BD)
    card:SetBackdropColor(0.02, 0.03, 0.06, 1)
    card:SetBackdropBorderColor(0.29, 0.65, 1.00, 0.5)
    Track(card)

    local cardHdr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cardHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    cardHdr:SetText(COL_BLUE .. "NEXT PVP TALENT" .. CLOSE .. "  Level " .. playerLevel .. " / " .. maxLevel)
    cardHdr:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)

    -- Find next talent from level path
    local levelPath = pvpData and pvpData.levelPath
    if levelPath then
        local nextTalent = nil
        local nextLevel  = nil
        for lvl = playerLevel, playerLevel + 20 do
            if levelPath[lvl] then
                nextTalent = levelPath[lvl]
                nextLevel  = lvl
                break
            end
        end

        if nextTalent then
            local advLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            advLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
            if nextLevel == playerLevel then
                advLbl:SetText(COL_GREEN .. "→ Take now: " .. CLOSE .. COL_GOLD .. nextTalent.name .. CLOSE)
            else
                advLbl:SetText(COL_ORANGE .. "At level " .. nextLevel .. ": " .. CLOSE .. nextTalent.name)
            end
            advLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -26)

            local whyLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            whyLbl:SetFont(STANDARD_TEXT_FONT, 9)
            whyLbl:SetText(nextTalent.why or "")
            whyLbl:SetTextColor(0.72, 0.68, 0.52, 1)
            whyLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -42)
            whyLbl:SetWidth(w - 20)
            whyLbl:SetWordWrap(true)

            -- Show upcoming 2-3 more
            local upcoming = {}
            local count = 0
            for lvl = (nextLevel or playerLevel) + 1, playerLevel + 30 do
                if levelPath[lvl] and count < 3 then
                    count = count + 1
                    table.insert(upcoming, "Lvl " .. lvl .. ": " .. levelPath[lvl].name)
                end
            end
            if #upcoming > 0 then
                local upLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                upLbl:SetFont(STANDARD_TEXT_FONT, 8)
                upLbl:SetText(COL_GREY .. "Upcoming: " .. table.concat(upcoming, " → ") .. CLOSE)
                upLbl:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 6)
                upLbl:SetWidth(w - 20)
                upLbl:SetWordWrap(false)
            end
        else
            local noPath = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noPath:SetFont(STANDARD_TEXT_FONT, 9)
            noPath:SetText(COL_GREY .. "No step-by-step PvP leveling path defined for this level range." .. CLOSE)
            noPath:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -28)
        end
    else
        local noData = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noData:SetFont(STANDARD_TEXT_FONT, 9)
        noData:SetText(COL_GREY .. "No PvP level path data available for this spec yet." .. CLOSE)
        noData:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -28)
    end

    y = y - 88
    return y
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INIT & SLASH
-- ═══════════════════════════════════════════════════════════════════════════════

function TalentsPvP:Init()
    PVPD = TA.Data.TalentsPvP
end

--- Hide and release every frame this module has drawn into the shared
--- Talents content frame. Talents.lua owns its own frame list and only ever
--- clears that one — it has no way to know this module drew anything on top
--- of it. Without this, switching the outer build-type row away from "PvP"
--- (e.g. to Leveling/Raid/Mythic+) leaves this module's header, hero
--- recommendation, tab bar, and panel content sitting there uncleared,
--- overlapping whatever Talents.lua draws next in the same frame.
function TalentsPvP:Hide()
    for _, f in ipairs(self.frames) do
        if f and f.Hide then f:Hide() end
        if f and f.SetParent then f:SetParent(nil) end
    end
    self.frames = {}
end

function TalentsPvP:OnEvent(event, ...)
    -- Refresh cache on spec/talent changes if PvP view is active
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        self.treeCache = nil
        self.specID    = nil
    end
end

TalentsPvP.SlashCommands = {
    pvp = function(self)
        if TA.UI then
            TA.UI:Show()
            -- Switch to talents tab with PvP view
            local Talents = TA:GetModule("Talents")
            if Talents then
                Talents.viewBuildType = "pvp"
            end
            TA.UI:SetTab("talents")
        end
    end,
}
