LUAGUI_NAME = "Bleach Forms (New IDs)"
LUAGUI_AUTH = "Gemini"
LUAGUI_DESC = "Scannt 457-461 in 9ABDF4-9ABEB4"

-- ==========================================
-- KONFIGURATION
-- ==========================================

-- 1. Feste Model-Adresse (Sora P_EX100)
local MODEL_ADDR = 0x2A268C0

-- 2. Micro Scan-Bereich
local SCAN_START = 0x9ABDF4 
local SCAN_END   = 0x9ABEB4 

-- 3. Form Definitionen (Priorität: Oben = Wichtiger)
local FORMS = {
    -- 1. Hollow (ID 460)
    { name = "Hollow", suffix = "_HOLL", id = 460 },

    -- 2. Bankai (ID 458)
    { name = "Bankai", suffix = "_BANK", id = 458 },

    -- 3. Masked (ID 459)
    { name = "Masked", suffix = "_MASK", id = 459 },

    -- 4. Shikai (ID 457)
    { name = "Shikai", suffix = "_SHIK", id = 457 },

    -- 5. Mugets (ID 461)
    { name = "Mugets", suffix = "_MUGE", id = 461 }
}

-- ==========================================
-- SYSTEM VARIABLEN
-- ==========================================

local currentWrittenSuffix = "NONE"
local scanTimer = 0
local activeSuffix = ""
local activeFormName = "Base"

function _OnInit()
    ConsolePrint("Bleach Mod (New IDs) gestartet.")
end

function _OnFrame()
    -- 1. Scan Interval (alle 10 Frames)
    scanTimer = scanTimer + 1
    if scanTimer > 10 then
        scanTimer = 0
        ScanForAbilities()
    end

    -- 2. Schreiben (Nur bei Änderung)
    if activeSuffix ~= currentWrittenSuffix then
        WriteModelString(activeSuffix)
        
        if activeSuffix ~= "" then
            ConsolePrint("Wechsel zu: " .. activeFormName .. " (" .. activeSuffix .. ")")
        end
        
        currentWrittenSuffix = activeSuffix
    end
end

-- =====================================================================
-- LOGIK & SCANNER
-- =====================================================================

function ScanForAbilities()
    local foundForm = nil
    local equippedIDs = {}

    -- Micro Scan
    for addr = SCAN_START, SCAN_END, 2 do
        local val = ReadShort(addr)
        
        -- Check: Ist Bit 0x8000 (32768) gesetzt?
        if val > 32768 then
            local rawID = val - 32768
            equippedIDs[rawID] = true
        end
    end

    -- Prioritäten-Check (Hollow > Bankai > Masked > Shikai > Mugetsu)
    for _, form in ipairs(FORMS) do
        if equippedIDs[form.id] then
            foundForm = form
            break 
        end
    end

    -- Ergebnis
    if foundForm then
        activeSuffix = foundForm.suffix
        activeFormName = foundForm.name
    else
        activeSuffix = ""
        activeFormName = "Base"
    end
end

function WriteModelString(suffix)
    local writeAddr = MODEL_ADDR + 7
    
    if suffix == "" then
        WriteByte(writeAddr, 0)
    else
        WriteString(writeAddr, suffix)
        WriteByte(writeAddr + string.len(suffix), 0)
    end
end

function WriteString(addr, str)
    for i = 1, #str do
        WriteByte(addr + i - 1, string.byte(str, i))
    end
end