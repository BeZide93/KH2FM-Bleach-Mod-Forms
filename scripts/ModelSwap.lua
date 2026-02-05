LUAGUI_NAME = "Bleach Forms (New IDs)"
LUAGUI_AUTH = "BeZide"
LUAGUI_DESC = "Scans 457-461 in ability list and swaps model suffix"

-- =========================================================
-- Version checks (Epic / Steam / Steam JP)
-- =========================================================
local epiccheck  = 0x585B61
local stmcheck   = epiccheck + 0x2F8
local stmjpcheck = epiccheck + 0x2A8
local MAGIC      = 0x7265737563697065

local game = 0
local printed = false

-- =========================================================
-- Addresses (set per version once)
-- =========================================================
local SCAN_START = 0
local SCAN_END   = 0

-- List of model addresses to be updated
local TARGET_MODELS = {
    0x2A268C0, -- P_EX100
    0x2A2E840, -- P_EX100_NM
    0x2A3DD20, -- P_EX100_TR
    0x2A3DD80, -- P_EX100_WI
    0x2A49D20, -- P_EX100_WM
    0x2A4E3A0  -- P_EX100_XM
}

local function ResolveGame()
    if game ~= 0 then return true end

    if ReadLong(epiccheck) == MAGIC then
        game = 1
        -- EPIC (adjust if needed)
        SCAN_START = 0x9ABDF4
        SCAN_END   = 0x9ABEB4

        if not printed then
            ConsolePrint(LUAGUI_NAME .. " (EPIC) - Ready")
            printed = true
        end
        return true

    elseif ReadLong(stmcheck) == MAGIC then
        game = 2
        -- STEAM GLOBAL (adjust if needed)
        SCAN_START = 0x9ABDF4
        SCAN_END   = 0x9ABEB4

        if not printed then
            ConsolePrint(LUAGUI_NAME .. " (Steam) - Ready")
            printed = true
        end
        return true

    elseif ReadLong(stmjpcheck) == MAGIC then
        game = 3
        -- STEAM JP (often same as Steam Global, adjust if needed)
        SCAN_START = 0x9ABDF4
        SCAN_END   = 0x9ABEB4

        if not printed then
            ConsolePrint(LUAGUI_NAME .. " (Steam JP) - Ready")
            printed = true
        end
        return true
    end

    return false
end

-- =========================================================
-- Forms (priority: top wins)
-- =========================================================
local FORMS = {
    { name = "Hollow",  suffix = "_HOLL", id = 460 },
    { name = "Bankai",  suffix = "_BANK", id = 458 },
    { name = "Masked",  suffix = "_MASK", id = 459 },
    { name = "Shikai",  suffix = "_SHIK", id = 457 },
    { name = "Mugetsu", suffix = "_MUGE", id = 461 }
}

-- =========================================================
-- State
-- =========================================================
local currentWrittenSuffix = "NONE"
local activeSuffix = ""
local activeFormName = "Base"
local scanTimer = 0

function _OnInit()
    if ENGINE_TYPE == "BACKEND" then
        game = 0
        printed = false
        currentWrittenSuffix = "NONE"
        activeSuffix = ""
        activeFormName = "Base"
        scanTimer = 0
    end
end

function _OnFrame()
    if not ResolveGame() then return end

    -- scan every 10 frames
    scanTimer = scanTimer + 1
    if scanTimer >= 10 then
        scanTimer = 0
        ScanForAbilities()
    end

    -- write only when changed
    if activeSuffix ~= currentWrittenSuffix then
        WriteModelString(activeSuffix)

        if activeSuffix ~= "" then
            ConsolePrint("Wechsel zu: " .. activeFormName .. " (" .. activeSuffix .. ")")
        end

        currentWrittenSuffix = activeSuffix
    end
end

-- =========================================================
-- Scanner
-- =========================================================
function ScanForAbilities()
    -- We don’t need a table; just track which IDs are equipped.
    -- Equipped abilities have bit 0x8000 set (0x8000 | id).
    local equipped457 = false
    local equipped458 = false
    local equipped459 = false
    local equipped460 = false
    local equipped461 = false

    for addr = SCAN_START, SCAN_END, 2 do
        local val = ReadShort(addr)

        -- bit-test instead of "val > 32768"
        if (val & 0x8000) ~= 0 then
            local rawID = val & 0x7FFF

            if rawID == 457 then equipped457 = true
            elseif rawID == 458 then equipped458 = true
            elseif rawID == 459 then equipped459 = true
            elseif rawID == 460 then equipped460 = true
            elseif rawID == 461 then equipped461 = true
            end
        end
    end

    -- Priority: Hollow > Bankai > Masked > Shikai > Mugetsu
    if equipped460 then
        activeSuffix = "_HOLL"; activeFormName = "Hollow"
    elseif equipped458 then
        activeSuffix = "_BANK"; activeFormName = "Bankai"
    elseif equipped459 then
        activeSuffix = "_MASK"; activeFormName = "Masked"
    elseif equipped457 then
        activeSuffix = "_SHIK"; activeFormName = "Shikai"
    elseif equipped461 then
        activeSuffix = "_MUGE"; activeFormName = "Mugetsu"
    else
        activeSuffix = ""; activeFormName = "Base"
    end
end

-- =========================================================
-- Writer
-- =========================================================
function WriteModelString(suffix)
    for _, modelBaseAddr in ipairs(TARGET_MODELS) do
        local writeAddr = modelBaseAddr + 7

        if suffix == "" then
            WriteByte(writeAddr, 0)
        else
            WriteString(writeAddr, suffix)
            WriteByte(writeAddr + #suffix, 0)
        end
    end
end

function WriteString(addr, str)
    for i = 1, #str do
        WriteByte(addr + i - 1, string.byte(str, i))
    end
end