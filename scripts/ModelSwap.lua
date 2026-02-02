LUAGUI_NAME = "Slow 2 -> Magic Form (Fixed Addr)"
LUAGUI_AUTH = "Gemini"
LUAGUI_DESC = "Swap zu _MAGF via Slow 2 (Addr 9ABE50)"

-- ==========================================
-- FESTE ADRESSEN (STEAM)
-- ==========================================

local ABILITY_ADDR = 0x9ABE50   -- Adresse für Slow 2
local MODEL_ADDR   = 0x2A268C0  -- Adresse für P_EX100

-- ID Prüfung
-- 33213 = 0x81BD (ID 445 + Equipped Flag 0x8000)
local EQUIPPED_VALUE = 33213 

-- Zustands-Speicher
local currentWrittenSuffix = "NONE"

function _OnInit()
    ConsolePrint("Model Swap gestartet.")
    ConsolePrint("Ability Addr: " .. string.format("%X", ABILITY_ADDR))
    ConsolePrint("Model Addr:   " .. string.format("%X", MODEL_ADDR))
end

function _OnFrame()
    -- 1. Ability-Status lesen (2 Bytes)
    local val = ReadShort(ABILITY_ADDR)
    
    local targetSuffix = ""

    -- 2. Logik: Ist Slow 2 ausgerüstet?
    if val == EQUIPPED_VALUE then
        targetSuffix = "_MAGF" -- Magic Form Look
    else
        targetSuffix = "" -- Base Look (P_EX100)
    end

    -- 3. Schreiben (Nur bei Änderung)
    if targetSuffix ~= currentWrittenSuffix then
        WriteModelString(targetSuffix)
        
        -- Konsolen-Feedback
        if targetSuffix == "_MAGF" then
            ConsolePrint("Slow 2 AN -> Model: Magic Form")
        elseif currentWrittenSuffix ~= "NONE" then
            ConsolePrint("Slow 2 AUS -> Model: Base")
        end
        
        currentWrittenSuffix = targetSuffix
    end
end

-- =====================================================================
-- HILFSFUNKTIONEN
-- =====================================================================

function WriteModelString(suffix)
    -- Wir schreiben direkt an Adresse + 7 (hinter "P_EX100")
    local writeAddr = MODEL_ADDR + 7
    
    if suffix == "" then
        -- Reset: Null-Byte schreiben (String endet hier)
        WriteByte(writeAddr, 0)
    else
        -- Suffix schreiben
        WriteString(writeAddr, suffix)
        -- Null-Terminator dahinter setzen
        WriteByte(writeAddr + string.len(suffix), 0)
    end
end

function WriteString(addr, str)
    for i = 1, #str do
        WriteByte(addr + i - 1, string.byte(str, i))
    end
end