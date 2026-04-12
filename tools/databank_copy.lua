-- ================================================================
-- DATABANK COPY TOOL
-- Auto-detects any two linked databanks and copies between them.
-- No specific slot names needed — just link two databanks.
--
-- USAGE:
--   1. Link two databanks to any slots, activate PB.
--   2. Type 'copy' to copy DB1 → DB2.
--   3. To restore: type 'restore' to copy DB2 → DB1.
-- ================================================================

--[[@
slot=-1
event=onStart()
args=
]]
DB1=nil; DB2=nil; DB1slot=0; DB2slot=0
local _slots={slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10}
for i,s in ipairs(_slots) do
  if s then
    local ok=pcall(function() s.getKeyList() end)
    if ok then
      if not DB1 then DB1=s; DB1slot=i
      elseif not DB2 then DB2=s; DB2slot=i end
    end
  end
end
if not DB1 or not DB2 then
  system.print("[COPY] ERROR: need 2 databanks linked — found "..(DB1 and "1" or "0").." of 2")
  system.print("[COPY] Link your Navigator databank AND a blank backup databank to this PB.")
else
  local r1=DB1.getKeyList(); local n1=type(r1)=="table" and #r1 or 0
  local r2=DB2.getKeyList(); local n2=type(r2)=="table" and #r2 or 0
  system.print("[COPY] DB1 = slot"..DB1slot.."  ("..n1.." keys)")
  system.print("[COPY] DB2 = slot"..DB2slot.."  ("..n2.." keys)")
  system.print("[COPY] 'copy'    = DB1 → DB2  (backup)")
  system.print("[COPY] 'restore' = DB2 → DB1  (restore)")
  if n1==0 then system.print("[COPY] WARNING: DB1 is empty — are slots connected correctly?") end
  if n2>0 and n1==0 then system.print("[COPY] TIP: your data looks like it may be in DB2 — type 'restore' to flip it to DB1") end
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local cmd=(text or ""):match("^%s*(.-)%s*$"):lower()

ConfirmPending=ConfirmPending or nil  -- "copy" or "restore"

local function DoCopy(src,dst,label)
  local raw=src.getKeyList()
  local list=type(raw)=="table" and raw or {}
  if #list==0 then system.print("[COPY] Source is empty — nothing to copy") return end
  dst.clear()
  local copied=0
  for _,k in ipairs(list) do
    local sv=src.getStringValue(k)
    local iv=src.getIntValue(k)
    local fv=src.getFloatValue(k)
    if sv~=nil and sv~="" then dst.setStringValue(k,sv)
    elseif iv~=nil and iv~=0 then dst.setIntValue(k,iv)
    elseif fv~=nil and fv~=0 then dst.setFloatValue(k,fv)
    else dst.setStringValue(k,sv or "") end
    copied=copied+1
  end
  system.print("[COPY] Done — "..label.."  ("..copied.." keys)")
  ConfirmPending=nil
end

local function WarnIfNeeded(src,dst,direction,cmdName)
  if not DB1 or not DB2 then system.print("[COPY] Need 2 databanks linked first") return end
  local rsrc=src.getKeyList(); local nsrc=type(rsrc)=="table" and #rsrc or 0
  local rdst=dst.getKeyList(); local ndst=type(rdst)=="table" and #rdst or 0
  if nsrc==0 then system.print("[COPY] WARNING: source is empty — nothing to copy") return end
  if ndst>0 then
    system.print("[COPY] WARNING: destination has "..ndst.." keys that will be overwritten!")
    system.print("[COPY] To get an empty DB: use Wipe_Databanks tool, or take it to inventory and right-click → Clear.")
    system.print("[COPY] Type 'yes' to confirm "..direction..", or anything else to cancel.")
    ConfirmPending=cmdName
  else
    DoCopy(src,dst,direction)
  end
end

if cmd=="copy"    then WarnIfNeeded(DB1,DB2,"DB1 → DB2","copy")       end
if cmd=="restore" then WarnIfNeeded(DB2,DB1,"DB2 → DB1","restore")    end
if cmd=="yes" then
  if ConfirmPending=="copy"    then DoCopy(DB1,DB2,"DB1 → DB2 (backup)")
  elseif ConfirmPending=="restore" then DoCopy(DB2,DB1,"DB2 → DB1 (restore)")
  else system.print("[COPY] Nothing pending confirmation") end
end
if cmd=="no" or cmd=="cancel" then ConfirmPending=nil; system.print("[COPY] Cancelled") end
