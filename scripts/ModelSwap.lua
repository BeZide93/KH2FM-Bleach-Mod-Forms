LUAGUI_NAME = "Bleach Forms (Micro Scan)"
LUAGUI_AUTH = "Gemini"
LUAGUI_DESC = "Scannt 0x9ABDF4 - 0x9ABEB4"

-- ==========================================
-- KONFIGURATION
-- ==========================================

-- 1. Feste Model-Adresse (Sora P_EX100)
local MODEL_ADDR = 0x2A268C0

-- 2. Micro Scan-Bereich (Dein definierter Bereich)
-- Wir starten bei ..F4 (gerade Zahl), damit wir ..E50 auch treffen.
local SCAN_START = 0x9ABDF4 
local SCAN_END   = 0x9ABEB4 

-- 3. Form Definitionen (Priorität: Oben = Wichtiger)
local FORMS = {
    -- 1. Hollow (Slow 3 - ID 195)
    { name = "Hollow", suffix = "_HOLL", id = 195 },

    -- 2. Bankai (Slow 2 - ID 445)
    { name = "Bankai", suffix = "_BANK", id = 445 },

    -- 3. Masked (Reflect Dummy - ID 248)
    { name = "Masked", suffix = "_MASK", id = 248 },

    -- 4. Shikai (Upper Dummy - ID 249)
    { name = "Shikai", suffix = "_SHIK", id = 249 }
}

-- ==========================================
-- SYSTEM VARIABLEN
-- ==========================================

local currentWrittenSuffix = "NONE"
local scanTimer = 0
local activeSuffix = ""
local activeFormName = "Base"

function _OnInit()
    ConsolePrint("Bleach Mod (Micro Scan) gestartet.")
    ConsolePrint("Scan-Bereich: 9ABDF4 - 9ABEB4")
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

    -- Prioritäten-Check
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