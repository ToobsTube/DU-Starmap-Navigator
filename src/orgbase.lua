-- ================================================================
-- NAVIGATOR ORG BASE v1.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (programming board):
--   Slot 1: screen     (Screen Unit - optional)
--   Slot 2: databank   (Databank)
--   Slot 3: receiver   (Receiver - set to channel NavOrg)
--   Slot 4: emitter    (Emitter)
--
-- CHANNEL: NavOrg
-- This is the org-wide master waypoint repository.
-- Personal base stations sync up/down through it.
-- Ships can also connect here directly via orgsync command.
--
-- CHAT COMMANDS:
--   help                add / del / list / clear / confirm
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z = s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if x then return {w=tonumber(w),b=tonumber(b),x=tonumber(x),y=tonumber(y),z=tonumber(z)} end
  return nil
end

function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end

function SetStatus(msg, dur)
  StatusMsg    = msg
  StatusExpiry = os.clock() + (dur or 5)
  system.print("[ORG] " .. msg)
end


--[[@
slot=-1
event=onStart()
args=
]]
local VERSION   = "v1.0.0"
OrgChannel      = "NavOrg"
WaypointList    = {}
StatusMsg       = ""
StatusExpiry    = 0
ScrollWP        = 0
SelectedWP      = ""
ClearConfirm    = false
SyncReceived    = 0
SendQueue       = {}
SendIndex       = 1
Sending         = false

function LoadData()
  if not databank then WaypointList={} return end
  local raw = databank.getStringValue("waypoints")
  WaypointList = (raw~=nil and raw~="") and json.decode(raw) or {}
end

function SaveData()
  if not databank then return end
  databank.setStringValue("waypoints", json.encode(WaypointList))
end

function AddWP(name, posStr)
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then
      SetStatus("'"..name.."' already exists.")
      return false
    end
  end
  table.insert(WaypointList, {n=name, c=posStr})
  table.sort(WaypointList, function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData()
  SetStatus("Added: "..name)
  return true
end

function DelWP(name)
  for i,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then
      table.remove(WaypointList, i)
      if SelectedWP==wp.n then SelectedWP="" end
      SaveData()
      SetStatus("Deleted: "..name)
      return true
    end
  end
  SetStatus("Not found: "..name)
  return false
end

function StartSend()
  SendQueue = {}
  for _,wp in ipairs(WaypointList) do table.insert(SendQueue, wp) end
  SendIndex = 1
  Sending   = true
  emitter.send(OrgChannel, "<SyncCount>"..#SendQueue)
  unit.setTimer("send_tick", 0.3)
  SetStatus("Sending "..#SendQueue.." org WPs")
end

-- ── Screen builder ────────────────────────────────────────────
function DrawScreen()
  if not screen then return end
  screen.setRenderScript(BuildScreenScript())
end

function BuildScreenScript()
  local wpEnc = json.encode(WaypointList):gsub('"', "@@@")
  local S = {}

  S[1] = string.format([[
local json=require('dkjson')
local Cell=32
local ScrW,ScrH=1024,576
local ScrollWP=%d
local SelWP=%q
local StatusMsg=%q
local _w=%q
local WP=json.decode(_w:gsub("@@@",'"')) or {}
]], ScrollWP, SelectedWP, StatusMsg, wpEnc)

  S[2] = [[
local Lbg =createLayer()
local Lpnl=createLayer()
local Lln =createLayer()
local Lbtn=createLayer()
local Lsel=createLayer()
local Ltxt=createLayer()
local Ltit=createLayer()
local Lst =createLayer()
local cx,cy=getCursor()
local pr=getCursorPressed()
local Out=""
local fTxt=loadFont("Montserrat-Light",18)
local fTit=loadFont("Montserrat-Light",22)
local fSm =loadFont("Montserrat-Light",13)

setDefaultFillColor(Ltxt,Shape_Text,0.82,0.82,0.82,1)
setDefaultFillColor(Ltit,Shape_Text,1.0, 0.56,0.0, 1)
setDefaultFillColor(Lsel,Shape_Text,1.0, 0.70,0.0, 1)
setDefaultFillColor(Lst, Shape_Text,1.0, 0.78,0.2, 1)
setDefaultStrokeColor(Lln,Shape_Line,0.40,0.25,0.05,0.7)
setDefaultStrokeWidth(Lln,Shape_Line,1)
setDefaultFillColor(Lbtn, Shape_BoxRounded,0.28,0.14,0.0, 0.9)
setDefaultStrokeColor(Lbtn,Shape_BoxRounded,0.70,0.45,0.10,1.0)
setDefaultStrokeWidth(Lbtn,Shape_BoxRounded,1)
setNextFillColor(Lbg,0.02,0.01,0,1)
addBox(Lbg,0,0,ScrW,ScrH)

local function Btn(txt,x,y,w,h,enabled)
  local hov=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not enabled then
    setNextFillColor(Lbtn,0.10,0.07,0.05,0.6)
    setNextStrokeColor(Lbtn,0.30,0.20,0.10,0.5)
    addBoxRounded(Lbtn,x,y,w,h,4)
    setNextFillColor(Ltxt,0.40,0.30,0.20,1)
    setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
    addText(Ltxt,fTxt,txt,x+w/2,y+h/2)
    return false
  elseif hov then
    setNextFillColor(Lbtn,0.60,0.35,0.0,1)
    setNextStrokeColor(Lbtn,1.0,0.70,0.2,1)
    addBoxRounded(Lbtn,x,y,w,h,4)
    setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
    addText(Ltxt,fTxt,txt,x+w/2,y+h/2)
  else
    addBoxRounded(Lbtn,x,y,w,h,4)
    setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
    addText(Ltxt,fTxt,txt,x+w/2,y+h/2)
  end
  return hov and pr
end
]]

  S[3] = [[
-- Header
setNextFillColor(Lpnl,0.12,0.06,0,1)
setNextStrokeColor(Lpnl,0.55,0.35,0.05,0.8)
setNextStrokeWidth(Lpnl,1)
addBox(Lpnl,0,0,ScrW,Cell)
setNextTextAlign(Ltit,AlignH_Left,AlignV_Middle)
addText(Ltit,fTit,"◄ ORG BASE v1.0 ►",8,Cell/2)
setNextTextAlign(Ltit,AlignH_Right,AlignV_Middle)
addText(Ltit,fTit,"ORG WPs: "..#WP,ScrW-8,Cell/2)
addLine(Lln,0,Cell,ScrW,Cell)

-- WP list panel header
setNextFillColor(Lpnl,0.06,0.03,0,0.9)
addBox(Lpnl,0,Cell,Cell*22,Cell)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle)
addText(Ltit,fTit,"ORG WAYPOINTS",Cell*11,Cell+Cell/2)
addLine(Lln,0,Cell*2,Cell*22,Cell*2)
addLine(Lln,Cell*22,Cell,Cell*22,ScrH-Cell)

local visWP=14
local maxSWP=math.max(0,#WP-visWP)
local sCWP=math.max(0,math.min(ScrollWP,maxSWP))
for i=1,visWP do
  local idx=i+sCWP
  if idx>#WP then break end
  local wp=WP[idx]
  local ry=Cell*2+(i-1)*Cell
  local sel=(wp.n==SelWP)
  local hov=(cx>=0 and cx<Cell*22 and cy>=ry and cy<ry+Cell)
  if sel then
    setNextFillColor(Lpnl,0.55,0.28,0,0.22)
    setNextStrokeColor(Lpnl,1.0,0.60,0,0.9)
    setNextStrokeWidth(Lpnl,1)
    addBox(Lpnl,0,ry,Cell*22,Cell)
  elseif hov then
    setNextFillColor(Lpnl,1,1,1,0.04)
    addBox(Lpnl,0,ry,Cell*22,Cell)
  end
  setNextFillColor(Ltxt,0.45,0.35,0.20,1)
  setNextTextAlign(Ltxt,AlignH_Right,AlignV_Middle)
  addText(Ltxt,fSm,idx..".",Cell,ry+Cell/2)
  local L=(sel or hov) and Lsel or Ltxt
  if sel then setNextFillColor(Lsel,1.0,0.70,0.0,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle)
  addText(L,fTxt,wp.n,Cell+6,ry+Cell/2)
  setNextFillColor(Ltxt,0.55,0.50,0.35,1)
  setNextTextAlign(Ltxt,AlignH_Left,AlignV_Middle)
  addText(Ltxt,fSm,wp.c,Cell*9,ry+Cell/2)
  addLine(Lln,0,ry+Cell,Cell*22,ry+Cell)
  if hov and pr then Out=json.encode({"sel",wp.n}) end
end

if #WP>visWP then
  local sbX=Cell*22-6
  local sbYs=Cell*2+2
  local sbH=visWP*Cell-4
  local tH=math.max(16,sbH*(visWP/#WP))
  local tY=sbYs+(sbH-tH)*(sCWP/math.max(1,maxSWP))
  setNextFillColor(Lln,0.28,0.18,0.02,0.5)
  addBox(Lln,sbX,sbYs,5,sbH)
  setNextFillColor(Lln,0.85,0.55,0.10,0.8)
  addBox(Lln,sbX,tY,5,tH)
end

-- Buttons (right panel)
local bX=Cell*23
local bW=ScrW-bX-8
local bH=Cell-6
local bGap=6
local bY=Cell*2+bGap
if Btn("✕  REMOVE SELECTED",bX,bY,bW,bH,SelWP~="") then Out=json.encode({"del",SelWP})   end; bY=bY+bH+bGap
if Btn("⚠  CLEAR ALL",      bX,bY,bW,bH,true)      then Out=json.encode({"clear_all"})   end
]]

  S[4] = [[
-- Footer
addLine(Lln,0,ScrH-Cell,ScrW,ScrH-Cell)
setNextFillColor(Lpnl,0.04,0.02,0,0.95)
addBox(Lpnl,0,ScrH-Cell,ScrW,Cell)
if StatusMsg~="" then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle)
  addText(Lst,fTxt,StatusMsg,ScrW/2,ScrH-Cell/2)
else
  setNextFillColor(Ltxt,0.40,0.35,0.20,1)
  setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
  addText(Ltxt,fSm,"Org channel: NavOrg  |  Base stations and ships sync here  |  Lua chat: help",ScrW/2,ScrH-Cell/2)
end
setOutput(Out)
requestAnimationFrame(1)
]]
  return table.concat(S)
end

-- ── Init ─────────────────────────────────────────────────────
LoadData()
if screen   then screen.activate() end
if receiver then receiver.setChannelList({OrgChannel}) end
unit.setTimer("org_tick", 1)
system.print("=== Org Base "..VERSION.." ===  WPs: "..#WaypointList)
DrawScreen()


--[[@
slot=-1
event=onStop()
args=
]]
if screen then screen.setCenteredText("Org Base") end


--[[@
slot=-1
event=onTimer(tag)
args="org_tick"
]]
if StatusMsg~="" and os.clock()>StatusExpiry then StatusMsg="" end
DrawScreen()


--[[@
slot=-1
event=onTimer(tag)
args="send_tick"
]]
if not Sending then return end
if SendIndex > #SendQueue then
  emitter.send(OrgChannel, "<SyncComplete>")
  Sending = false
  SetStatus("Org send complete: "..(SendIndex-1).." WPs sent")
  return
end
local wp = SendQueue[SendIndex]
local d  = json.encode({n=wp.n, c=wp.c}):gsub('"', "@@@")
emitter.send(OrgChannel, "<SyncWP>"..d)
SendIndex = SendIndex + 1


--[[@
slot=0
event=onMouseUp(x,y)
args=*,*
]]
local raw = screen.getScriptOutput()
if not raw or raw=="" then return end
local ok, data = pcall(json.decode, raw)
if not ok or type(data)~="table" then return end
local act, p1 = data[1], data[2]
if     act=="sel"       then SelectedWP = (SelectedWP==p1 and "" or p1)
elseif act=="del"       then DelWP(p1)
elseif act=="clear_all" then
  if ClearConfirm then
    WaypointList = {}; SaveData()
    ClearConfirm = false
    SetStatus("All org WPs cleared")
  else
    ClearConfirm = true
    SetStatus("Type 'confirm' in Lua chat to clear ALL org waypoints.", 10)
  end
end
DrawScreen()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
-- Base station or ship requesting sync download
if message:find("<RequestSync>", 1, true) then
  local who = message:gsub("<RequestSync>", "")
  system.print("[ORG] Sync request from: "..who)
  StartSend()
  return
end

-- Base station pushing a WP up to org
if message:find("<PushWP>", 1, true) then
  local raw = message:gsub("<PushWP>", ""):gsub("@@@", '"')
  local ok, wp = pcall(json.decode, raw)
  if ok and wp and wp.n and wp.c then
    local found = false
    for i,e in ipairs(WaypointList) do
      if e.n:lower()==wp.n:lower() then WaypointList[i].c=wp.c; found=true; break end
    end
    if not found then table.insert(WaypointList, {n=wp.n, c=wp.c}) end
    table.sort(WaypointList, function(a,b) return a.n:lower()<b.n:lower() end)
    SaveData()
    SetStatus("Received WP: "..wp.n)
  end
  DrawScreen()
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t  = Trim(text)
local lo = t:lower()

if lo=="help" then
  system.print("═══ ORG BASE COMMANDS ═══")
  system.print("add NAME ::pos{..}  add waypoint (coords required)")
  system.print("del NAME            delete waypoint")
  system.print("list                list all org waypoints")
  system.print("clear               clear all (requires confirm)")
  system.print("confirm             confirm a pending clear")
  return
end

local addN, addC = t:match("^[Aa][Dd][Dd]%s+(%S+)%s*(.*)")
if addN then
  addC = Trim(addC)
  if addC=="" then
    SetStatus("Coords required. Use: add NAME ::pos{0,0,x,y,z}")
  elseif ParsePos(addC) then
    AddWP(addN, addC)
  else
    SetStatus("Bad coords format. Use ::pos{0,0,x,y,z}")
  end
  DrawScreen(); return
end

local delN = t:match("^[Dd][Ee][Ll]%s+(.+)")
if delN then DelWP(Trim(delN)); DrawScreen(); return end

if lo=="list" then
  system.print("─── ORG WAYPOINTS ("..#WaypointList..") ───")
  for i,wp in ipairs(WaypointList) do
    system.print(i..".  "..wp.n.."  "..wp.c)
  end
  return
end

if lo=="clear" then
  ClearConfirm = true
  SetStatus("Type 'confirm' to clear ALL org waypoints. Cannot be undone.", 10)
  DrawScreen(); return
end

if lo=="confirm" then
  if ClearConfirm then
    WaypointList = {}; SaveData()
    ClearConfirm = false
    SetStatus("All org waypoints cleared")
    DrawScreen()
  else
    SetStatus("Nothing to confirm.")
  end
  return
end

SetStatus("Unknown command '"..lo.."'  —  type 'help'")
