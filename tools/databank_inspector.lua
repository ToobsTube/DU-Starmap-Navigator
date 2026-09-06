-- ================================================================
-- DATABANK INSPECTOR
-- Reads all keys from a linked databank and displays them on screen.
-- Useful for inspecting what another HUD stores in its databank.
--
-- SLOT CONNECTIONS: link a Screen Unit and the Databank you want to inspect
-- to ANY of the PB's slots, in any order — auto-detected at startup. Check
-- the Lua console after activating for a "[INSP] slot1=..." line confirming
-- what was detected as what.
--
-- USAGE:
--   Just turn it on. Screen shows all keys and their values, PAGE_SIZE per
--   page (a databank can hold hundreds of keys — a Screen Unit's input is
--   capped at 1024 characters, so only the current page is ever sent).
--   Type a key name in Lua chat to search/filter.
--   Type "clear" to reset the filter.
--   Type "next" / "prev" to page through results.
-- ================================================================

--[[@
slot=-5
event=onStart()
]]
ScreenScript=[[
local raw=getInput() or ""
local lines={}; for ln in raw:gmatch("[^\n]+") do table.insert(lines,ln) end
local FILTER=(lines[1] or "F:"):sub(3)
local PAGE=tonumber((lines[2] or "P:1"):sub(3)) or 1
local TOTALP=tonumber((lines[3] or "T:1"):sub(3)) or 1
local TOTALN=tonumber((lines[4] or "N:0"):sub(3)) or 0
local KEYS={}
for i=5,#lines do
  local k,t,v=lines[i]:match("^([^|]*)|([^|]*)|?(.*)")
  if k then table.insert(KEYS,{k=k,t=t,v=v or ""}) end
end

local SW,SH=getResolution()
local C=28
local Lbg=createLayer() local Lp=createLayer() local Lt=createLayer()
local Ls=createLayer()  local Lx=createLayer() local Lh=createLayer()
local fT=loadFont("Montserrat-Light",13)
local fS=loadFont("Montserrat-Light",11)
local fH=loadFont("Montserrat-Light",16)
local fB=loadFont("Montserrat-Light",18)

setDefaultFillColor(Lt,Shape_Text,0.80,0.80,0.80,1)
setDefaultFillColor(Ls,Shape_Text,0.0,0.87,1.0,1)
setDefaultFillColor(Lx,Shape_Text,1.0,0.86,0.0,1)
setDefaultFillColor(Lh,Shape_Text,0.70,0.85,1.0,1)

-- Background
setNextFillColor(Lbg,0,0.005,0.03,1) addBox(Lbg,0,0,SW,SH)

-- Header
setNextFillColor(Lp,0,0.04,0.16,1) addBox(Lp,0,0,SW,C)
setNextTextAlign(Lx,AlignH_Left,AlignV_Middle)
addText(Lx,fB,"DATABANK INSPECTOR",8,C/2)
local info=(FILTER~="" and "filter: "..FILTER.."  |  " or "").."total: "..TOTALN.." keys"
setNextFillColor(Lt,0.45,0.45,0.65,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
addText(Lt,fS,info,SW-8,C/2)

-- Column headers
local KW=math.floor(SW*0.32) local VW=SW-KW-2
local HY=C
setNextFillColor(Lp,0,0.06,0.22,1) addBox(Lp,0,HY,SW,C)
setNextFillColor(Lh,0.5,0.65,1.0,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
addText(Lh,fT,"KEY",8,HY+C/2)
setNextFillColor(Lh,0.5,0.65,1.0,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
addText(Lh,fT,"VALUE",KW+8,HY+C/2)

-- Separator line
setNextStrokeColor(Lp,0.15,0.32,0.62,0.6) setNextStrokeWidth(Lp,1)
addLine(Lp,KW,HY,KW,SH-C)

-- Rows — KEYS already holds just the current page (sliced on the controller
-- side to respect the Screen Unit's 1024-char input limit), so draw them
-- straight through with no further windowing here.
local rowY=C*2
for i=1,#KEYS do
  local entry=KEYS[i]
  local ry=rowY+(i-1)*C
  local isEven=(i%2==0)
  if isEven then
    setNextFillColor(Lp,0,0.02,0.08,0.4) addBox(Lp,0,ry,SW,C)
  end
  -- Key (cyan)
  setNextFillColor(Ls,0.0,0.87,1.0,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Middle)
  addText(Ls,fT,entry.k,8,ry+C/2)
  -- Type badge
  local tc=entry.t=="string" and "S" or entry.t=="number" and "N" or entry.t=="int" and "I" or "?"
  local tr=entry.t=="string" and 0.2 or 0.5
  local tg=entry.t=="number" and 0.7 or entry.t=="int" and 0.9 or 0.3
  local tb=entry.t=="string" and 0.8 or 0.2
  setNextFillColor(Lp,tr,tg,tb,0.7) addBoxRounded(Lp,KW-22,ry+4,18,C-8,3)
  setNextFillColor(Lt,1,1,1,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,tc,KW-13,ry+C/2)
  -- Value
  setNextFillColor(Lt,0.80,0.80,0.80,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Middle)
  addText(Lt,fS,entry.v,KW+8,ry+C/2)
  -- row divider
  setNextStrokeColor(Lp,0.10,0.22,0.44,0.3) setNextStrokeWidth(Lp,1)
  addLine(Lp,0,ry+C,SW,ry+C)
end

if TOTALN==0 then
  setNextFillColor(Lt,0.35,0.35,0.55,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fH,"Databank is empty or not linked",SW/2,SH/2)
end

-- Footer
setNextFillColor(Lp,0,0.03,0.12,1) addBox(Lp,0,SH-C,SW,C)
setNextFillColor(Lt,0.40,0.40,0.60,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fS,"Page "..PAGE.." / "..TOTALP.."   |   chat: type key name to filter  |  'clear' to reset  |  'next' / 'prev' to page",SW/2,SH-C/2)
requestAnimationFrame(60)
]]


--[[@
slot=-1
event=onStart()
]]
-- Slot auto-detect: link Screen and Databank to ANY slot, in any order.
do
  -- Primary check: DU's own type introspection. getElementClass() (confirmed
  -- present on a "Modern Screen xs" via a live field dump, 2026-09-06)
  -- logs a deprecation warning in-game telling scripts to use getClass()
  -- instead — try that first, fall back to the deprecated name for older
  -- game versions that might not have getClass() yet. Either way the
  -- returned string gets a lowercase substring match, robust to exact
  -- naming we haven't seen across other screen/databank variants.
  local function classOf(s)
    local ok,cls=pcall(function() return s.getClass() end)
    if ok and type(cls)=="string" then return cls:lower() end
    ok,cls=pcall(function() return s.getElementClass() end)
    if ok and type(cls)=="string" then return cls:lower() end
    return nil
  end
  local function probe(s)
    if not s then return nil end
    local cls=classOf(s)
    if cls then
      if cls:find("screen")   then return "screen" end
      if cls:find("databank") then return "databank" end
    end
    -- Fallback for class names this doesn't recognize, or if
    -- getElementClass() itself isn't available on some element.
    if pcall(function() return s.getScriptOutput() end)
      or pcall(function() return s.getRenderScript() end)
      or pcall(function() return s.getScriptInput() end) then return "screen" end
    if pcall(function() return s.getKeyList() end) then return "databank" end
    return nil
  end
  local function tryName(s)
    local ok,n=pcall(function() return s.getName() end)
    if ok and n and n~="" then return n end
    return nil
  end
  -- Literal slotN references only — DU's sandbox does not support building
  -- these names dynamically (e.g. _ENV["slot"..i]) and silently fails.
  local raw={slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10}
  for i,s in ipairs(raw) do
    local kind=probe(s)
    if kind=="databank" and not databank then databank=s
    elseif kind=="screen" and not screen then screen=s
    end
  end
  local dbg={}
  for i,s in ipairs(raw) do
    local role=(s==databank and "databank") or (s==screen and "screen") or "unrecognized"
    local nm=tryName(s)
    local cls=(role=="unrecognized") and classOf(s) or nil
    table.insert(dbg,"slot"..i.."="..role..(nm and ("("..nm..")") or "")..(cls and ("[class:"..cls.."]") or ""))
  end
  system.print("[INSP] "..(#dbg>0 and table.concat(dbg,"  ") or "no slots linked"))
end

-- Screen Unit input is capped at 1024 characters, and a databank can easily
-- hold 100+ keys — PAGE_SIZE keeps each page's serialized payload well under
-- that limit regardless of key/value length. Both the key and value strings
-- are also truncated per-row for the same reason.
PAGE_SIZE = 10
KEY_MAX   = 30
VAL_MAX   = 45

Filter  = ""
Page    = 1
Keys    = {}

function Collect()
  Keys={}
  if not databank then system.print("[INSP] ERROR: databank slot is nil — link a databank to this PB") return end
  local raw=databank.getKeyList()
  local list
  if type(raw)=="table" then list=raw
  elseif type(raw)=="string" then list=json.decode(raw) or {}
  else list={} end
  system.print("[INSP] getKeyList type:"..type(raw).." count:"..(type(list)=="table" and #list or 0))
  for _,k in ipairs(list) do
    local match=Filter=="" or tostring(k):lower():find(Filter:lower(),1,true)
    if match then
      local sv=databank.getStringValue(k)
      local iv=databank.getIntValue(k)
      local fv=databank.getFloatValue(k)
      local v,t
      if sv~=nil and sv~="" then v=sv; t="string"
      elseif iv~=nil and iv~=0 then v=tostring(iv); t="int"
      elseif fv~=nil and fv~=0 then v=tostring(fv); t="float"
      else v=sv or ""; t="string" end
      table.insert(Keys,{k=tostring(k),v=v,t=t})
    end
  end
  table.sort(Keys,function(a,b) return a.k:lower()<b.k:lower() end)
end

function PushScreen()
  if not screen then return end
  local totalPages=math.max(1,math.ceil(#Keys/PAGE_SIZE))
  Page=math.max(1,math.min(Page,totalPages))
  local startI=(Page-1)*PAGE_SIZE+1
  local endI=math.min(#Keys,startI+PAGE_SIZE-1)
  local lines={"F:"..Filter:sub(1,40),"P:"..Page,"T:"..totalPages,"N:"..#Keys}
  for i=startI,endI do
    local e=Keys[i]
    local k=e.k:sub(1,KEY_MAX)
    local v=(e.v or ""):gsub("|","¦"):sub(1,VAL_MAX)
    table.insert(lines,k.."|"..(e.t or "?").."|"..v)
  end
  screen.setScriptInput(table.concat(lines,"\n"))
  screen.setRenderScript(ScreenScript)
end

Collect()
if screen then screen.activate() end
system.print("=== Databank Inspector ===  "..#Keys.." keys found")
system.print("Chat: type a key name to filter  |  'clear' to reset  |  'next'/'prev' to page")
PushScreen()


--[[@
slot=-1
event=onStop()
]]
if screen then screen.setCenteredText("Inspector") end


--[[@
slot=-4
event=onInputText(text)
]]
local t=(text or ""):match("^%s*(.-)%s*$")
local lo=t:lower()
if lo=="clear" then
  Filter=""; Page=1; Collect(); PushScreen()
  system.print("Filter cleared  ("..#Keys.." keys)")
elseif lo=="next" then
  local totalPages=math.max(1,math.ceil(#Keys/PAGE_SIZE))
  Page=math.min(totalPages,Page+1); PushScreen()
  system.print("Page "..Page.." / "..totalPages)
elseif lo=="prev" then
  Page=math.max(1,Page-1); PushScreen()
  system.print("Page "..Page)
else
  Filter=t; Page=1; Collect(); PushScreen()
  system.print("Filter: '"..Filter.."'  ("..#Keys.." matches)")
end
