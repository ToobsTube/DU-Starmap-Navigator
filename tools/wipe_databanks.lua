-- Wipe Databanks Tool
-- Links any number of databanks and clears all of them.
-- Usage: paste into a PB, link one or more databanks to ANY of the PB's
-- slots, in any order (auto-detected — no fixed slot names needed), activate.

--[[@
slot=-1
event=onStart()
args=
]]
local function isDatabank(s)
  if not s then return false end
  return pcall(function() return s.getKeyList() end)
end
local function tryName(s)
  local ok,n=pcall(function() return s.getName() end)
  if ok and n and n~="" then return n end
  return nil
end
-- Literal slotN references only — DU's sandbox does not support building
-- these names dynamically (e.g. _ENV["slot"..i]) and silently fails.
local raw={slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10}
local wiped=0
for i,s in ipairs(raw) do
  if isDatabank(s) then
    s.clear()
    wiped=wiped+1
    local nm=tryName(s)
    system.print("Wiped slot"..i..(nm and (" ("..nm..")") or ""))
  end
end
if wiped==0 then
  system.print("No databanks found — link one or more databanks to this PB")
else
  system.print("Done. Wiped "..wiped.." databank(s).")
end
