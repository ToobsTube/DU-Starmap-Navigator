--[[
    Navigator → Arch HUD Integration
    File: archhud_userclass.lua
    Place this file at: Game Install\autoconf\custom\archhud\userclass.lua

    This module lets the DU Starmap Navigator send waypoints directly to
    Arch HUD as a temporary nav target — no extra hardware needed.
    The Navigator PB and the control seat running Arch HUD must share
    the same databank.

    The Navigator writes to databank key "nav_arch_dest" in this format:
        NAME|::pos{0,0,x,y,z}

    This module reads that key every tick, passes the position to Arch HUD
    as a temporary waypoint (same as typing the ::pos in chat), then clears
    the key so it only fires once.

    SETUP:
    1.  Copy this file to:  Game Install\autoconf\custom\archhud\userclass.lua
    2.  Make sure your Navigator PB and your control seat (Arch HUD) are both
        linked to the same databank.
    3.  That's it — no other changes needed on either side.

    IF YOU ALREADY HAVE A userclass.lua:
    Do NOT replace your existing file — add the Navigator code to it instead.

    1.  Copy the local _navDb variable and the findDb logic into your file.
    2.  Inside your existing ExtraOnStart, add the line:
            _navDb = findDb()
    3.  Inside your existing ExtraOnUpdate, add the nav polling block
        from this file (everything after "if _navDb == nil then return end").
    4.  Your ExtraOnStop and ExtraOnFlush stubs can stay as-is if you
        already have them defined.
--]]

userBase  = userBase  or {}
userAtlas = userAtlas or {}

local _navDb = nil

function userBase.ExtraOnStart()
    -- Arch stores databank slots in dbHud[1], dbHud[2], etc.
    if type(dbHud) == "table" then
        for i = 1, #dbHud do
            local ok, fn = pcall(function() return dbHud[i].getStringValue end)
            if ok and fn ~= nil then
                _navDb = dbHud[i]
                break
            end
        end
    end
end

function userBase.ExtraOnStop()  end
function userBase.ExtraOnFlush() end

function userBase.ExtraOnUpdate()
    if _navDb == nil then return end

    local ok, raw = pcall(function() return _navDb.getStringValue("nav_arch_dest") end)
    if not ok or raw == nil or raw == "" then return end

    -- Clear immediately so it only fires once
    _navDb.setStringValue("nav_arch_dest", "")

    -- Parse NAME|::pos{...}
    local sep = string.find(raw, "|")
    if not sep then return end
    local name = string.sub(raw, 1, sep - 1)
    local pos  = string.sub(raw, sep + 1)
    if name == "" or not string.find(pos, "::pos") then return end

    -- Pass the ::pos string to Arch — sets a temporary nav target
    if CONTROL and CONTROL.inputTextControl then
        CONTROL.inputTextControl(pos)
    end
end
