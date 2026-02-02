LUAGUI_NAME = "Bleach Forms (Hardcoded)"
LUAGUI_AUTH = "Gemini"
LUAGUI_DESC = "Checks fixed addresses for Slow2/3 (No Scan)"

-- ==========================================
-- FESTE ADRESSEN (STEAM)
-- ==========================================

local MODEL_ADDR = 0x2A268C0

-- 1. SLOW 3 (ID 195) -> HOLLOW FORM (_HOLL)
-- Adresse aus deinem Screenshot: ...exe + 9ABE6E
local ADDR_HOLL = 0x9ABE6E 
local VAL_HOLL  = 32963    -- 195 + 32768 (Equipped)

-- 2. SLOW 2 (ID 445) -> BANKAI FORM (_BANK)
-- Adresse aus deinem Screenshot: ...exe + 9ABE50
local ADDR_BANK = 0x9ABE50 
local VAL_BANK  = 33213    -- 445 + 32768 (Equipped)

-- 3. REFLECT DUMMY (ID 248) -> MASKED FORM (_MASK)
-- Noch unbekannt! Suche in CE nach 248 (2 Bytes)
local ADDR_MASK = 0x000000 -- <--- HIER ADRESSE EINTRAGEN
local VAL_MASK  = 33016    -- 248 + 32768

-- 4. UPPER DUMMY (ID 249) -> SHIKAI FORM (_SHIK)
-- Noch unbekannt! Suche in CE nach 249 (2 Bytes)
local ADDR_SHIK = 0x000000 -- <--- HIER ADRESSE EINTRAGEN
local VAL_SHIK  = 33017    -- 249 + 32768

-- ==========================================

local currentWrittenSuffix = "NONE"

function _OnInit()
    ConsolePrint("Bleach Hardcoded Mod gestartet.")
    ConsolePrint("Hollow Addr: " .. string.format("%X", ADDR_HOLL))
    ConsolePrint("Bankai Addr: " .. string.format("%X", ADDR_BANK))
end

function _OnFrame()
    local targetSuffix = ""
    local activeForm = "Base"

    -- LOGIK & PRIORITÄT (Oben gewinnt)
    
    -- 1. HOLLOW (Slow 3)
    if IsEquipped(ADDR_HOLL, VAL_HOLL) then
        targetSuffix = "_HOLL"
        activeForm = "Hollow"

    -- 2. BANKAI (Slow 2)
    elseif IsEquipped(ADDR_BANK, VAL_BANK) then
        targetSuffix = "_BANK"
        activeForm = "Bankai"

    -- 3. MASKED (Reflect Dummy) - Nur wenn Adresse eingetragen
    elseif ADDR_MASK ~= 0 and IsEquipped(ADDR_MASK, VAL_MASK) then
        targetSuffix = "_MASK"
        activeForm = "Masked"

    -- 4. SHIKAI (Upper Dummy) - Nur wenn Adresse eingetragen
    elseif ADDR_SHIK ~= 0 and IsEquipped(ADDR_SHIK, VAL_SHIK) then
        targetSuffix = "_SHIK"
        activeForm = "Shikai"
    end

    -- SCHREIBEN
    if targetSuffix ~= currentWrittenSuffix then
        WriteModelString(targetSuffix)
        ConsolePrint("Wechsel zu: " .. activeForm .. " (" .. (targetSuffix == "" and "Base" or targetSuffix) .. ")")
        currentWrittenSuffix = targetSuffix
    end
end

-- =====================================================================
-- HILFSFUNKTIONEN
-- =====================================================================

function IsEquipped(addr, targetVal)
    -- Sicherstellen, dass Adresse gültig ist
    if addr == 0 then return false end
    
    -- Wert lesen
    local val = ReadShort(addr)
    
    -- Prüfen (Exakter Match auf "Equipped Value")
    if val == targetVal then
        return true
    end
    return false
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