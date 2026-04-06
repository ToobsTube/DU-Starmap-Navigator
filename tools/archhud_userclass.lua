--[[
    Navigator → Arch HUD Integration
    File: archhud_userclass.lua
    Place this file at: Game Install\autoconf\custom\archhud\userclass.lua

    This module lets the DU Starmap Navigator send waypoints directly to
    Arch HUD via the shared databank — no receiver or extra hardware needed.

    The Navigator writes to databank key "nav_arch_dest" in this format:
        NAME|::pos{0,0,x,y,z}

    This module reads that key every tick, injects the destination into
    Arch HUD as a temporary waypoint (same as typing /::pos), then clears
    the key so it only fires once.

    SETUP:
    1.  Copy this file to:  Game Install\autoconf\custom\archhud\userclass.lua
    2.  Make sure your Navigator PB and Arch HUD share the same databank.
    3.  That's it — no parameter changes needed on either side.
--]]

userBase  = userBase  or {}
userAtlas = userAtlas or {}

function userBase.ExtraOnUpdate()
    -- Poll the databank for a pending Navigator destination
    if dbHud_1 == nil then return end
    local raw = dbHud_1.getStringValue("nav_arch_dest")
    if raw == nil or raw == "" then return end

    -- Clear immediately so we only act once
    dbHud_1.setStringValue("nav_arch_dest", "")

    -- Parse   NAME|::pos{0,0,x,y,z}
    local sep = string.find(raw, "|")
    if not sep then return end
    local name = string.sub(raw, 1, sep - 1)
    local pos  = string.sub(raw, sep + 1)
    if name == "" or not string.find(pos, "::pos") then return end

    -- Inject into Arch HUD as a temporary waypoint (not saved to databank)
    if ATLAS and ATLAS.AddNewLocation then
        -- Convert ::pos{0,0,x,y,z} to a vec3 world position
        local num = " *([+-]?%d+%.?%d*e?[+-]?%d*)"
        local pat = "::pos{" .. num .. "," .. num .. "," .. num .. "," .. num .. "," .. num .. "}"
        local sysId, bodyId, a, b, c = string.match(pos, pat)
        if not sysId then return end
        local worldPos
        if sysId == "0" and bodyId == "0" then
            worldPos = vec3(tonumber(a), tonumber(b), tonumber(c))
        else
            -- Planet-relative coords — delegate to Arch's own parser via chat handler
            -- by temporarily writing as if the player typed /addlocation
            CONTROL.inputTextControl("/addlocation " .. name .. " " .. pos)
            return
        end
        ATLAS.AddNewLocation(name, worldPos, true)
    end
end
