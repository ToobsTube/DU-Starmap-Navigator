-- ================================================================
-- NAVIGATOR ORG BASE - SYNC PB v2.0.0
-- Dual Universe Navigation System
--
-- PURPOSE: Read-only sync server. Safe to give "use element" to all
-- org members — it NEVER writes to the databank.
-- The screen shows the channel name and org name so any member can
-- configure their ship without asking for help.
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (SHARED databank — same one orgbase_admin uses)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
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

-- ── Theme utilities (read-only) ─────────────────────────────
function HSV2RGB(h,s,v)
  h=h%360; local c=v*s; local x=c*(1-math.abs((h/60)%2-1)); local m=v-c
  local r,g,b
  if     h<60  then r,g,b=c,x,0
  elseif h<120 then r,g,b=x,c,0
  elseif h<180 then r,g,b=0,c,x
  elseif h<240 then r,g,b=0,x,c
  elseif h<300 then r,g,b=x,0,c
  else              r,g,b=c,0,x end
  return r+m,g+m,b+m
end

function DefaultOrgTheme()
  return {
    {h=30, s=0.85,v=0.65},  -- accent (warm amber)
    {h=20, s=0.50,v=0.02},  -- background (dark brown)
    {h=0,  s=0,   v=0.82},  -- text
    {h=40, s=1.0, v=1.0},   -- header (orange-gold)
    {h=30, s=1.0, v=0.22},  -- btnNormal (dark brown buttons)
    {h=30, s=0.85,v=0.55},  -- btnHover (brighter brown hover)
    {h=30, s=0.85,v=0.55},  -- selected (warm selection)
    {h=140,s=0.70,v=1.0},   -- route (green)
  }
end

function DeriveTheme(slots)
  local p={}
  p.ar,p.ag,p.ab=HSV2RGB(slots[1].h,slots[1].s,slots[1].v)
  local mx=math.max(p.ar,p.ag,p.ab,0.001)
  p.nr,p.ng,p.nb=p.ar/mx,p.ag/mx,p.ab/mx
  p.bgr,p.bgg,p.bgb=HSV2RGB(slots[2].h,slots[2].s,slots[2].v)
  p.txr,p.txg,p.txb=HSV2RGB(slots[3].h,slots[3].s,slots[3].v)
  p.hdr,p.hdg,p.hdb=HSV2RGB(slots[4].h,slots[4].s,slots[4].v)
  p.str,p.stg,p.stb=1.0,0.78,0.2
  p.lnr,p.lng,p.lnb=HSV2RGB(slots[1].h,slots[1].s*0.5,slots[1].v*0.4)
  p.bnfr,p.bnfg,p.bnfb=HSV2RGB(slots[5].h,slots[5].s,slots[5].v)
  p.bnsr,p.bnsg,p.bnsb=HSV2RGB(slots[5].h,slots[5].s*0.85,math.min(slots[5].v*1.6,1))
  p.bhfr,p.bhfg,p.bhfb=HSV2RGB(slots[6].h,slots[6].s,slots[6].v)
  p.bhsr,p.bhsg,p.bhsb=HSV2RGB(slots[6].h,slots[6].s*0.75,math.min(slots[6].v*1.35,1))
  p.slr,p.slg,p.slb=HSV2RGB(slots[7].h,slots[7].s,slots[7].v)
  p.rtr,p.rtg,p.rtb=HSV2RGB(slots[8].h,slots[8].s,slots[8].v)
  p.phdr,p.phdg,p.phdb=HSV2RGB(slots[1].h,slots[1].s*0.6,slots[1].v*0.12)
  p.ftr,p.ftg,p.ftb=HSV2RGB(slots[2].h,slots[2].s*0.7,math.max(slots[2].v*1.5,0.06))
  p.dmr,p.dmg,p.dmb=p.txr*0.51,p.txg*0.51,p.txb*0.76
  return p
end

function LoadTheme()
  if not databank then return DefaultOrgTheme() end
  local name=databank.getStringValue("orgtheme_profile_active")
  if name=="" then return DefaultOrgTheme() end
  local raw=databank.getStringValue("orgtheme_p_"..name)
  if raw=="" then return DefaultOrgTheme() end
  local ok,data=pcall(json.decode,raw)
  if not ok or not data then return DefaultOrgTheme() end
  if #data<8 then return DefaultOrgTheme() end
  for i=1,8 do
    if type(data[i])~="table" or not data[i].h then return DefaultOrgTheme() end
  end
  return data
end


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
Whitelist       = {}  -- {[playerID]=displayName}
SendQueue       = {}
SendIndex       = 1
Sending         = false
RequestCount    = 0
LastRequester   = "---"
DeniedCount     = 0
PendingSession  = nil  -- {pid,shipID,count,received} — active unwhitelisted push

-- Theme state (read-only from shared databank)
ThemeSlots      = nil
Palette         = nil

function LoadData()
  if not databank then WaypointList={};RouteList={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  WaypointList = jd("waypoints") or {}
  RouteList    = jd("routes")    or {}
  Whitelist    = jd("org_whitelist") or {}
  local ch=databank.getStringValue("org_channel")
  if ch and ch~="" then OrgChannel=ch end
  local nm=databank.getStringValue("org_name")
  if nm and nm~="" then OrgName=nm end
end

function IsWhitelisted(pid)
  return Whitelist[pid]~=nil
end

function ParsePID(msg)
  return msg:match("|pid:(%d+)") or "0"
end

function ParsePlayerName(msg)
  return msg:match("|pname:([^|]+)") or "Unknown"
end

function ParseShipID(msg)
  return msg:match("^(.+)|pid:") or msg
end

function LoadPending()
  if not databank then return {},{}  end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  return jd("pending_wps") or {}, jd("pending_routes") or {}
end

function SavePendingItem(item)
  if not databank then return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  if item.type=="wp" then
    local pws=jd("pending_wps") or {}
    table.insert(pws,item); databank.setStringValue("pending_wps",json.encode(pws))
  elseif item.type=="route" then
    local prs=jd("pending_routes") or {}
    table.insert(prs,item); databank.setStringValue("pending_routes",json.encode(prs))
  end
end

function StartSend(requester, targetChannel)
  LoadData()
  local ch=targetChannel or OrgChannel
  SendQueue={}
  for _,wp in ipairs(WaypointList) do
    table.insert(SendQueue,{type="wp",   data={n=wp.n,c=wp.c}, ch=ch})
  end
  for _,r in ipairs(RouteList) do
    table.insert(SendQueue,{type="route",data={n=r.n,pts=r.pts}, ch=ch})
  end
  -- Prepend header messages so they go through the same queued timer
  table.insert(SendQueue,1,{type="hdr",msg="<SyncCount>"..#SendQueue, ch=ch})
  table.insert(SendQueue,1,{type="hdr",msg="<OrgName>"..OrgName,      ch=ch})
  SendIndex=1; Sending=true
  RequestCount=RequestCount+1; LastRequester=requester
  unit.setTimer("send_tick",0.3)
  system.print("[ORG-SYNC] Serving "..(#SendQueue-2).." items to: "..requester.."  ch:"..ch)
  DrawScreen()
end

-- ── Screen ────────────────────────────────────────────────────
function DrawScreen()
  if not screen then return end
  screen.setRenderScript(BuildScreenScript())
end

function BuildScreenScript()
  local S={}
  local P=Palette
  local wlSize=0; for _ in pairs(Whitelist) do wlSize=wlSize+1 end
  S[1]=string.format([[
local OrgChannel=%q
local OrgName=%q
local WPCount=%d
local RTCount=%d
local ReqCount=%d
local DeniedCount=%d
local WLSize=%d
local LastReq=%q
local IsSending=%s
local VERSION=%q
local Ar,Ag,Ab=%f,%f,%f
local Bgr,Bgg,Bgb=%f,%f,%f
local Txr,Txg,Txb=%f,%f,%f
local Hdr,Hdg,Hdb=%f,%f,%f
local Str,Stg,Stb=%f,%f,%f
local Lnr,Lng,Lnb=%f,%f,%f
local PHr,PHg,PHb=%f,%f,%f
local FTr,FTg,FTb=%f,%f,%f
local Dmr,Dmg,Dmb=%f,%f,%f
]],
    OrgChannel, OrgName,
    #WaypointList, #RouteList,
    RequestCount, DeniedCount, wlSize,
    LastRequester, tostring(Sending), VERSION,
    P.ar,P.ag,P.ab,  P.bgr,P.bgg,P.bgb,
    P.txr,P.txg,P.txb,  P.hdr,P.hdg,P.hdb,
    P.str,P.stg,P.stb,  P.lnr,P.lng,P.lnb,
    P.phdr,P.phdg,P.phdb,  P.ftr,P.ftg,P.ftb,
    P.dmr,P.dmg,P.dmb)

  S[2]=[[
local Lbg=createLayer() local Lpnl=createLayer() local Lln=createLayer()
local Ltxt=createLayer() local Ltit=createLayer() local Lch=createLayer()
local Lst=createLayer()
local fBig=loadFont("Montserrat-Light",36) local fTit=loadFont("Montserrat-Light",22)
local fTxt=loadFont("Montserrat-Light",18) local fSm=loadFont("Montserrat-Light",14)
local ScrW,ScrH=1024,576
setDefaultFillColor(Ltxt,Shape_Text,Txr,Txg,Txb,1)
setDefaultFillColor(Ltit,Shape_Text,Hdr,Hdg,Hdb,1)
setDefaultFillColor(Lch, Shape_Text,Ar,Ag,Ab,1)
setDefaultFillColor(Lst, Shape_Text,Str,Stg,Stb,1)
setDefaultStrokeColor(Lln,Shape_Line,Lnr,Lng,Lnb,0.5)
setDefaultStrokeWidth(Lln,Shape_Line,1)
-- Background
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,ScrW,ScrH)
-- Header bar
setNextFillColor(Lpnl,PHr,PHg,PHb,1) setNextStrokeColor(Lpnl,Lnr,Lng,Lnb,0.9)
setNextStrokeWidth(Lpnl,2) addBox(Lpnl,0,0,ScrW,48)
setNextTextAlign(Ltit,AlignH_Left,AlignV_Middle)
addText(Ltit,fTit,"◄ ORG BASE  [ SYNC ]  "..OrgName.." ►",12,24)
setNextTextAlign(Ltit,AlignH_Right,AlignV_Middle) addText(Ltit,fTit,VERSION,ScrW-12,24)
addLine(Lln,0,48,ScrW,48)
-- Central channel display
setNextFillColor(Lpnl,Bgr*1.5,Bgg*1.5,Bgb*3,0.85) setNextStrokeColor(Lpnl,Ar*0.6,Ag*0.6,Ab*0.6,0.6)
setNextStrokeWidth(Lpnl,1) addBoxRounded(Lpnl,60,72,ScrW-120,138,8)
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fTxt,"SET THIS CHANNEL ON YOUR SHIP OR BASE STATION",ScrW/2,106)
setNextTextAlign(Lch,AlignH_Center,AlignV_Middle) addText(Lch,fBig,OrgChannel,ScrW/2,172)
addLine(Lln,60,228,ScrW-60,228)
-- Stats row
local col1=ScrW*0.20 local col2=ScrW*0.45 local col3=ScrW*0.70 local rowY=290
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"WAYPOINTS",col1,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(WPCount),col1,rowY+14)
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"ROUTES",col2,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(RTCount),col2,rowY+14)
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"SYNCS SERVED",col3,rowY-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(ReqCount),col3,rowY+14)
-- Whitelist / denied row
local row2Y=rowY+60
local col4=ScrW*0.33 local col5=ScrW*0.67
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"WHITELISTED",col4,row2Y-16)
setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle) addText(Ltit,fTit,tostring(WLSize),col4,row2Y+14)
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"DENIED",col5,row2Y-16)
local dc=DeniedCount>0 and 1 or 0.55
setNextFillColor(Ltit,1.0,dc*Hdg,0,1) setNextTextAlign(Ltit,AlignH_Center,AlignV_Middle)
addText(Ltit,fTit,tostring(DeniedCount),col5,row2Y+14)
-- Last requester / sending status
local statusY=390
if IsSending then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle)
  addText(Lst,fTxt,"⟳  Syncing to: "..LastReq,ScrW/2,statusY)
else
  setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
  addText(Ltxt,fSm,"Last sync: "..LastReq,ScrW/2,statusY)
end
-- First sync instruction
setNextFillColor(Ltxt,Dmr,Dmg,Dmb,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"First time on a new ship? Type in LUA chat on the ship:",ScrW/2,ScrH-88)
setNextTextAlign(Lch,AlignH_Center,AlignV_Middle)
addText(Lch,fTxt,"firstsync "..OrgChannel,ScrW/2,ScrH-62)
-- Footer
addLine(Lln,0,ScrH-40,ScrW,ScrH-40)
setNextFillColor(Lpnl,FTr,FTg,FTb,0.95) addBox(Lpnl,0,ScrH-40,ScrW,40)
setNextFillColor(Ltxt,Dmr*0.8,Dmg*0.8,Dmb*0.5,1) setNextTextAlign(Ltxt,AlignH_Center,AlignV_Middle)
addText(Ltxt,fSm,"Read-only sync server  |  Channel managed by Org Admin PB",ScrW/2,ScrH-20)
requestAnimationFrame(2)
]]
  return table.concat(S)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
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
  local finCh=SendQueue[#SendQueue] and SendQueue[#SendQueue].ch or OrgChannel
  emitter.send(finCh,"<SyncComplete>")
  Sending=false
  FirstSyncTarget=nil
  system.print("[ORG-SYNC] Done ("..#SendQueue.." items)")
  DrawScreen(); return
end
local item=SendQueue[SendIndex]
local ch=item.ch or OrgChannel
if item.type=="hdr" then
  emitter.send(ch,item.msg)
elseif item.type=="wp" then
  emitter.send(ch,"<SyncWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(ch,"<SyncRoute>"..json.encode(item.data):gsub('"',"@@@"))
end
SendIndex=SendIndex+1


--[[@
slot=-1
event=onTimer(tag)
args="heartbeat"
]]
LoadData()
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
if receiver then receiver.setChannelList({OrgChannel}) end
system.print("[ORG-SYNC] Alive  ch:"..OrgChannel.."  WPs:"..#WaypointList.."  Routes:"..#RouteList.."  Served:"..RequestCount)
DrawScreen()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
if message:find("<RequestSync>",1,true) then
  if Sending then return end
  local pid=ParsePID(message)
  local shipID=ParseShipID(message:gsub("<RequestSync>",""))
  local label=Whitelist[pid] and (shipID.." ["..Whitelist[pid].."]") or shipID
  StartSend(label)
end

if message:find("<PushAuth>",1,true) then
  local pid=ParsePID(message)
  local pname=ParsePlayerName(message)
  local shipID=ParseShipID(message:gsub("<PushAuth>",""))
  local count=tonumber(message:match("|count:(%d+)")) or 0
  if IsWhitelisted(pid) then
    -- Whitelisted — open a normal session, items go straight through to Admin PB receiver
    PendingSession=nil
    system.print("[ORG-SYNC] PUSH OK (whitelisted): "..pname.." on "..shipID)
  else
    -- Unknown player — open a pending session to collect their items
    PendingSession={pid=pid,pname=pname,shipID=shipID,count=count,received=0}
    emitter.send(OrgChannel,"<PushPending>"..shipID)
    system.print("[ORG-SYNC] PUSH QUEUED: "..pname.." on "..shipID.."  items:"..count)
    DrawScreen()
  end
end

if message:find("<PushWP>",1,true) then
  if PendingSession then
    local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
    local ok,wp=pcall(json.decode,raw)
    if ok and wp and wp.n and wp.c then
      SavePendingItem({type="wp",data=wp,from=PendingSession.shipID,pname=PendingSession.pname,pid=PendingSession.pid})
      PendingSession.received=PendingSession.received+1
      if PendingSession.received>=PendingSession.count then
        system.print("[ORG-SYNC] Pending complete: "..PendingSession.received.." items from "..PendingSession.pname)
        PendingSession=nil; DrawScreen()
      end
    end
  end
  -- If no pending session, this is from a whitelisted ship — Admin PB handles it via its own receiver
end

if message:find("<PushRoute>",1,true) then
  if PendingSession then
    local raw=message:gsub("<PushRoute>",""):gsub("@@@",'"')
    local ok,r=pcall(json.decode,raw)
    if ok and r and r.n then
      SavePendingItem({type="route",data=r,from=PendingSession.shipID,pname=PendingSession.pname,pid=PendingSession.pid})
      PendingSession.received=PendingSession.received+1
      if PendingSession.received>=PendingSession.count then
        system.print("[ORG-SYNC] Pending complete: "..PendingSession.received.." items from "..PendingSession.pname)
        PendingSession=nil; DrawScreen()
      end
    end
  end
end



