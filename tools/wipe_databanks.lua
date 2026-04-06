-- Wipe Databanks Tool
-- Links up to 2 databanks (slots: databank1, databank2) and clears both.
-- Usage: paste into a PB, link databanks to slots named databank1 / databank2, activate.

--[[@
slot=-1
event=onStart()
args=
]]
local wiped=0
if databank1 then databank1.clear(); wiped=wiped+1; system.print("Wiped databank1") end
if databank2 then databank2.clear(); wiped=wiped+1; system.print("Wiped databank2") end
if wiped==0 then
  system.print("No databanks found — check slot names are databank1 and databank2")
else
  system.print("Done. Wiped "..wiped.." databank(s).")
end
