-- ================================================================
-- DATABANK INSPECTOR
-- Reads all keys from a linked databank and displays them on screen.
-- Useful for inspecting what another HUD stores in its databank.
--
-- SLOT CONNECTIONS:
--   Slot 0: screen    (Screen Unit)
--   Slot 1: databank  (Databank — link the HUD's databank here)
--
-- USAGE:
--   Just turn it on. Screen shows all keys and their values.
--   Type a key name in Lua chat to search/filter.
--   Type "clear" to reset the filter.
-- ================================================================

--[[@
slot=-5
event=onStart()
]]
ScreenScript=[[
local json=require('dkjson')
local input=json.decode(getInput()) or {}
local KEYS   = input.keys   or {}
local FILTER = input.filter or ""
local PAGE   = input.page   or 1

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
local info=(FILTER~="" and "filter: "..FILTER.."  |  " or "").."total: "..#KEYS.." keys"
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

-- Rows
local rowY=C*2
local vis=math.floor((SH-C*3)/C)
local startI=(PAGE-1)*vis+1
local endI=math.min(#KEYS,startI+vis-1)
for i=startI,endI do
  local entry=KEYS[i]
  local ry=rowY+(i-startI)*C
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
  local val=entry.v or ""
  if #val>80 then val=val:sub(1,77).."..." end
  setNextFillColor(Lt,0.80,0.80,0.80,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Middle)
  addText(Lt,fS,val,KW+8,ry+C/2)
  -- row divider
  setNextStrokeColor(Lp,0.10,0.22,0.44,0.3) setNextStrokeWidth(Lp,1)
  addLine(Lp,0,ry+C,SW,ry+C)
end

if #KEYS==0 then
  setNextFillColor(Lt,0.35,0.35,0.55,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fH,"Databank is empty or not linked",SW/2,SH/2)
end

-- Footer
local totalPages=math.max(1,math.ceil(#KEYS/vis))
setNextFillColor(Lp,0,0.03,0.12,1) addBox(Lp,0,SH-C,SW,C)
setNextFillColor(Lt,0.40,0.40,0.60,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fS,"Page "..PAGE.." / "..totalPages.."   |   chat: type key name to filter  |  'clear' to reset  |  'next' / 'prev' to page",SW/2,SH-C/2)
requestAnimationFrame(60)
]]


--[[@
slot=-1
event=onStart()
]]
Filter  = ""
Page    = 1
Keys    = {}

function Collect()
  Keys={}
  if not databank then return end
  -- Collect all string keys
  local sk=databank.getKeyList()
  if type(sk)=="string" then
    for k in sk:gmatch("[^,]+") do
      local v=databank.getStringValue(k)
      if Filter=="" or k:lower():find(Filter:lower(),1,true) then
        table.insert(Keys,{k=k,v=tostring(v),t="string"})
      end
    end
  end
  -- Sort keys alphabetically
  table.sort(Keys,function(a,b) return a.k:lower()<b.k:lower() end)
end

function PushScreen()
  if not screen then return end
  local data={}
  data.keys=Keys
  data.filter=Filter
  data.page=Page
  screen.setInput(require('dkjson').encode(data))
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
  local vis=20
  local totalPages=math.max(1,math.ceil(#Keys/vis))
  Page=math.min(totalPages,Page+1); PushScreen()
  system.print("Page "..Page)
elseif lo=="prev" then
  Page=math.max(1,Page-1); PushScreen()
  system.print("Page "..Page)
else
  Filter=t; Page=1; Collect(); PushScreen()
  system.print("Filter: '"..Filter.."'  ("..#Keys.." matches)")
end
