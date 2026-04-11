--[[
    Navigator → Saga HUD Integration
    File: saga_nav_integration.lua

    This file shows exactly what to add to Saga HUD 4.2 so the DU Starmap
    Navigator can send waypoints to Saga and optionally auto-engage its autopilot.

    The Navigator PB and your Saga control seat must share a databank.
    (The same physical databank you use for Arch HUD works fine — just link it
    to the Saga seat too.)

    The Navigator writes two keys to that databank:
        nav_saga_dest   →   NAME|::pos{0,0,x,y,z}
        autofly         →   "1" or "0"

    Saga's system_update.lua polls those keys every tick, converts the pos to
    world coordinates, sets it as the autopilot target, and optionally engages
    autopilot when autofly = "1".

    ─── SETUP ──────────────────────────────────────────────────────────────────
    1.  Link a databank to both your Navigator PB (slot 4 = navdatabank) AND your
        Saga control seat.
    2.  Open SagaAP_src/src/events/system_update.lua
    3.  Add the TWO BLOCKS below to the file as described.
    4.  Rebuild Saga and deploy the new version to your seat.

    ─── IF YOU HAVE SagaHUD-CG (custom version) ────────────────────────────────
    Apply the same two blocks to the equivalent system_update.lua in that repo.
    The global names (AutoPilot, resetAP, convertToWorldCoordinates, links) are
    identical in both versions.
    ─────────────────────────────────────────────────────────────────────────────
--]]


-- ═══════════════════════════════════════════════════════════════════════════
-- BLOCK 1 — Paste these two lines near the TOP of system_update.lua,
--            OUTSIDE any function (module-level).
-- ═══════════════════════════════════════════════════════════════════════════

local _navDb        = nil   -- Navigator shared databank, found at first tick
local _navDbScanned = false -- only scan links.databanks once


-- ═══════════════════════════════════════════════════════════════════════════
-- BLOCK 2 — Paste this entire block INSIDE onSystemUpdate(), right after the
--            opening line:
--
--              if (links.core ~= nil and construct ~= nil) then
--
--            Place it before the Nav:update() / HUD:update() calls.
-- ═══════════════════════════════════════════════════════════════════════════

--[[ NAVIGATOR INTEGRATION — paste inside onSystemUpdate(), after the core/construct check

        -- Navigator: find shared databank once at startup
        if not _navDbScanned then
            _navDbScanned = true
            for _, db in ipairs(links.databanks) do
                local ok = pcall(function() db.getStringValue("nav_saga_dest") end)
                if ok then _navDb = db; break end
            end
        end

        -- Navigator: poll for incoming waypoint
        if _navDb ~= nil then
            local ok, raw = pcall(function() return _navDb.getStringValue("nav_saga_dest") end)
            if ok and raw ~= nil and raw ~= "" then
                -- Clear immediately so it fires only once
                _navDb.setStringValue("nav_saga_dest", "")

                local sep = string.find(raw, "|")
                if sep then
                    local name   = string.sub(raw, 1, sep - 1)
                    local posStr = string.sub(raw, sep + 1)
                    if name ~= "" and string.find(posStr, "::pos") then
                        local target = convertToWorldCoordinates(posStr)
                        if target ~= nil then
                            resetAP()
                            AutoPilot:setTarget(target)
                            system.print("[NAV] Target: " .. name)

                            -- Auto-engage if AutoFly is on in Navigator
                            local afOk, afVal = pcall(function()
                                return _navDb.getStringValue("autofly")
                            end)
                            if afOk and afVal == "1" and not AutoPilot.enabled then
                                AutoPilot:toggleState(true)
                            end
                        end
                    end
                end
            end
        end

END OF NAVIGATOR INTEGRATION ]]
