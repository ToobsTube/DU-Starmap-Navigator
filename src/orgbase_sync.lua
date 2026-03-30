-- ================================================================
-- NAVIGATOR ORG BASE - SYNC PB v2.0.0
-- Dual Universe Navigation System
--
-- PURPOSE: Read-only sync server. Safe to give "use element" to all
-- org members — it NEVER writes to the databank.
-- The screen shows the channel name and org name so any member can
-- configure their ship without asking for help.
--
-- SLOT CONNECTIONS:
--   Slot 1: screen     (Screen Unit)
--   Slot 2: databank   (SHARED databank — same one orgbase_admin uses)
--   Slot 3: receiver   (Receiver)
--   Slot 4: emitter    (Emitter)
--
-- Channel and org name are read from databank (set by Admin PB).
-- No --export fields — nothing for members to tamper with.
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end


--[[@
slot=-1
event=onStart()
args=
]]
local VERSION   = "v2.0.0"
OrgChannel      = "NavOrg"   -- fallback; overridden by databank
OrgName         = "Org"      -- fallback; overridden by databank
WaypointList    = {}
RouteList       = {}
SendQueue       = {}
SendIndex       = 1
Sending         = false
RequestCount    = 0
LastRequester   = "---"

function LoadData()
  if not databank then WaypointList={};RouteList={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  WaypointList = jd("waypoints") or {}
  RouteList    = jd("routes")    or {}
  local ch=databank.getStringValue("org_channel")
  if ch and ch~="" then OrgChannel=ch end
  local nm=databank.getStringValue("org_name")
  if nm and nm~="" then OrgName=nm end
end

function StartSend(requester)
  LoadData()
  SendQueue={}
  -- First packet: org name so the ship knows where to file this data
  for _,wp in ipairs(WaypointList) do
    table.insert(SendQueue,{type="wp",   data={n=wp.n,c=wp.c}})
  end
  for _,r in ipairs(RouteList) do
    table.insert(SendQueue,{type="route",data={n=r.n,pts=r.pts}})
  end
  SendIndex=1; Sending=true
  RequestCount=RequestCount+1; LastRequester=requester
  -- Send org name first so ships know which bucket to file under
  emitter.send(OrgChannel,"<OrgName>"..OrgName)
  emitter.send(OrgChannel,"<SyncCount>"..#SendQueue)
  unit.setTimer("send_tick",0.3)
  system.print("[ORG-SYNC] Serving "..#SendQueue.." items to: "..requester)
  DrawScreen()
end

-- ── Screen ────────────────────────────────────────────────────
function DrawScreen()
  if not screen then return end
  screen.setRenderScript(BuildScreenScript())
end

function BuildScreenScript()
  local S={}
  S[1]=string.format([[
local OrgChannel=%q
local OrgName=%q
local WPCount=%d
local RTCount=%d
local ReqCount=%d
local LastReq=%q
local IsSending=%s
local VERSION=%q
]],
    OrgChannel, OrgName,
    #WaypointList, #RouteList,
    RequestCount, LastRequester,
    tostring(Sending), VERSION)

  S[2]=[[
local Lbg=createLayer() local Lpnl=createLayer() local Lln=createLayer()
local Ltxt=createLayer() local Ltit=createLayer() local Lch=createLayer()
local Lst=createLayer()
local fBig=loadFont("Montserrat-Light",36) local fTit=loadFont("Montserrat-Light",22)
local fTxt=loadFont("Montserrat-Light",18) local fSm=loadFont("Montserrat-Light",14)
local ScrW,ScrH=1024,576
setDefaultFillColor(Ltxt,Shape_Text,0.82,0.82,0.82,1)
setDefaultFillColor(Ltit,Shape_Text,1.0,0.56,0.0,1)
setDefaultFillColor(Lch, Shape_Text,0.0,0.87,1.0,1)
setDefaultFillColor(Lst, Shape_Text,1.0,0.78,0.2,1)
setDefaultStrokeColor(Lln,Shape_Line,0.40,0.25,0.05,0.5)
setDefaultStrokeWidth(Lln,Shape_Line,1)
-- Background
setNextFillColor(Lbg,0.02,0.01,0,1) addBox(Lbg,0,0,ScrW,ScrH)
-- Header bar
setNextFillColor(Lpnl,0.12,0.06,0,1) setNextStrokeColor(Lpnl,0.55,0.35,0.05,0.9)
setNextStrokeWidth(Lpnl,2) addBox(Lpnl,0,0,ScrW,48)
setNextTextAlign(Ltit,AlignH_Left,AlignV_Middle)
addText(Ltit,fTit,"◄ ORG BASE  [ SYNC ]  "..OrgName.." ►",12,24)
setNextTextAlign(Ltit,AlignH_Right,AlignV_Middle) addText(Ltit,fTit,VERSION,ScrW-12,24)
addLine(Lln,0,48,ScrW,48)
-- Central channel display
setNextFillColor(Lpnl,0,0.03,0.06,0.85) setNextStrokeColor(Lpnl,0.0,0.50,0.80,0.6)
setNextStrokeWidth(Lpnl,1) addBoxRounded(Lpnl,60,72,ScrW-120,138,8)
setNextFillColor(Ltxt,0.55,0.50,0.35,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fTxt,"SET THIS CHANNEL ON YOUR SHIP OR BASE STATION",ScrW/2,106)
setNextTextAlign(Lch,AlignH_Center,AlignV_Middle) addText(Lch,fBig,OrgChannel,ScrW/2,172)
addLine(Lln,60,228,ScrW-60,228)
-- Stats row
local col1=ScrW*0.20 local col2=ScrW*0.45 local col3=ScrW*0.70 local rowY=290
setNextFillColor(Ltxt,0.45,0.40,0.25,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"WAYPOINTS",col1,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(WPCount),col1,rowY+14)
setNextFillColor(Ltxt,0.45,0.40,0.25,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"ROUTES",col2,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(RTCount),col2,rowY+14)
setNextFillColor(Ltxt,0.45,0.40,0.25,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"SYNCS SERVED",col3,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(ReqCount),col3,rowY+14)
-- Last requester / sending status
local statusY=390
if IsSending then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle)
  addText(Lst,fTxt,"⟳  Syncing to: "..LastReq,ScrW/2,statusY)
else
  setNextFillColor(Ltxt,0.40,0.35,0.20,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
  addText(Ltxt,fSm,"Last sync: "..LastReq,ScrW/2,statusY)
end
-- Footer
addLine(Lln,0,ScrH-40,ScrW,ScrH-40)
setNextFillColor(Lpnl,0.04,0.02,0,0.95) addBox(Lpnl,0,ScrH-40,ScrW,40)
setNextFillColor(Ltxt,0.40,0.30,0.12,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"Read-only sync server  |  Channel managed by Org Admin PB",ScrW/2,ScrH-20)
requestAnimationFrame(1)
]]
  return table.concat(S)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
if screen   then screen.activate() end
if receiver then receiver.setChannelList({OrgChannel}) end
unit.setTimer("heartbeat",30)
system.print("=== Org Sync "..VERSION.." ===  "..OrgName.."  ch:"..OrgChannel)
system.print("WPs:"..#WaypointList.."  Routes:"..#RouteList)
DrawScreen()


--[[@
slot=-1
event=onStop()
args=
]]
system.print("[ORG-SYNC] Stopped. Served: "..tostring(RequestCount))
if screen then screen.setCenteredText("Org Sync") end


--[[@
slot=-1
event=onTimer(tag)
args="send_tick"
]]
if not Sending then return end
if SendIndex>#SendQueue then
  emitter.send(OrgChannel,"<SyncComplete>")
  Sending=false
  system.print("[ORG-SYNC] Done ("..#SendQueue.." items)")
  DrawScreen(); return
end
local item=SendQueue[SendIndex]
if item.type=="wp" then
  emitter.send(OrgChannel,"<SyncWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(OrgChannel,"<SyncRoute>"..json.encode(item.data):gsub('"',"@@@"))
end
SendIndex=SendIndex+1


--[[@
slot=-1
event=onTimer(tag)
args="heartbeat"
]]
LoadData()
if receiver then receiver.setChannelList({OrgChannel}) end
system.print("[ORG-SYNC] Alive  ch:"..OrgChannel.."  WPs:"..#WaypointList.."  Routes:"..#RouteList.."  Served:"..RequestCount)
DrawScreen()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
if message:find("<RequestSync>",1,true) then
  if Sending then return end  -- already serving, queue next after completion
  local who=message:gsub("<RequestSync>","")
  StartSend(who)
end
-- All other messages ignored — this PB never writes to the databank
