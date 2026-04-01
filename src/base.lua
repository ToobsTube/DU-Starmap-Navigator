-- ================================================================
-- NAVIGATOR PERSONAL BASE v2.1.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (Databank)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
--
-- Screen script is embedded — no separate screen file needed.
-- Paste nothing into the Screen; the PB pushes the render script.
--
-- WP TAB SYSTEM:
--   OrgTabs = "Alliance,Corp"  (comma-separated prefixes)
--   Ships set OrgTag = "Alliance" → their WPs push as "Alliance-Name"
--   Base sorts WPs into tabs by matching prefix.
--   Untagged WPs → Personal tab.
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
-- ── Screen render script (embedded, TF Control pattern) ──────
ScreenScript = [[
local json=require('dkjson')
local input=json.decode(getInput()) or {}

local WP      = input.wps     or {}
local RT      = input.routes  or {}
local STOPS   = input.stops   or {}
local Tabs    = input.tabs    or {"Personal"}
local SelWP   = input.selWP   or ""
local SelRT   = input.selRT   or ""
local SelStop = input.selStop or 0
local Status  = input.status  or ""
local Sending = input.sending or false
local ack     = input.ack     or false

-- Screen-side state survives via output round-trip
if not _S then
  _S={tab=Tabs[1] or "Personal", scrollWP=0, scrollRT=0,
      action="", acked=false}
end
if ack then _S.action="" end
if input.tab and input.tab~="" then _S.tab=input.tab end

local function setAct(a) if _S.action=="" then _S.action=a end end

local SW,SH=getResolution()
local cx,cy=getCursor()
local pr=getCursorReleased()
local C=32

-- Layers
local Lbg=createLayer() local Lp=createLayer()  local Ll=createLayer()
local Lb=createLayer()  local Ls=createLayer()  local Lt=createLayer()
local Lh=createLayer()  local Lx=createLayer()  local Lst=createLayer()

local fT=loadFont("Montserrat-Light",math.floor(SH*0.031))
local fS=loadFont("Montserrat-Light",math.floor(SH*0.022))
local fH=loadFont("Montserrat-Light",math.floor(SH*0.035))
local fB=loadFont("Montserrat-Light",math.floor(SH*0.042))

setDefaultFillColor(Lt, Shape_Text,0.82,0.82,0.82,1)
setDefaultFillColor(Lh, Shape_Text,0.70,0.85,1.0,1)
setDefaultFillColor(Ls, Shape_Text,0.0,0.87,1.0,1)
setDefaultFillColor(Lx, Shape_Text,1.0,0.86,0.0,1)
setDefaultFillColor(Lst,Shape_Text,1.0,0.78,0.2,1)
setDefaultStrokeColor(Ll,Shape_Line,0.15,0.32,0.62,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)

-- Background
setNextFillColor(Lbg,0,0.008,0.04,1) addBox(Lbg,0,0,SW,SH)

-- Helpers
local function PH(x,w,r,g,b)
  setNextFillColor(Lp,r,g,b,0.88) addBox(Lp,x,C,w,C)
end
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,0.06,0.06,0.14,0.7)
    setNextStrokeColor(Lb,0.18,0.18,0.28,0.5) setNextStrokeWidth(Lb,1)
    addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,0.28,0.28,0.38,1)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
    return false
  elseif hv then
    setNextFillColor(Lb,0.0,0.31,0.78,1)
    setNextStrokeColor(Lb,0.4,0.63,1.0,1) setNextStrokeWidth(Lb,1)
    addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  else
    setNextFillColor(Lb,0.0,0.16,0.55,0.9)
    setNextStrokeColor(Lb,0.32,0.5,0.87,1) setNextStrokeWidth(Lb,1)
    addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  end
  return hv and pr
end

-- ── TAB BAR ──────────────────────────────────────────────────
local tabH=C
local tabW=math.floor(SW/#Tabs)
setNextFillColor(Lp,0,0.02,0.10,1) addBox(Lp,0,0,SW,tabH)
for i,tn in ipairs(Tabs) do
  local tx=(i-1)*tabW
  local sel=(_S.tab==tn)
  if sel then
    setNextFillColor(Lp,0.0,0.18,0.55,1)
    setNextStrokeColor(Lp,0.32,0.55,1.0,0.9) setNextStrokeWidth(Lp,1)
    addBox(Lp,tx,0,tabW,tabH)
    setNextFillColor(Lx,1.0,0.86,0.0,1)
  else
    setNextFillColor(Lt,0.55,0.55,0.70,1)
  end
  local L=sel and Lx or Lt
  setNextTextAlign(L,AlignH_Center,AlignV_Middle)
  addText(L,fT,tn,tx+tabW/2,tabH/2)
  addLine(Ll,tx,0,tx,tabH)
  local hv=(cx>=tx and cx<tx+tabW and cy>=0 and cy<tabH)
  if hv and pr and not sel then
    setAct(json.encode({"tab",tn}))
    _S.tab=tn _S.scrollWP=0 _S.scrollRT=0
  end
end
addLine(Ll,0,tabH,SW,tabH)

-- ── COLUMN LAYOUT ────────────────────────────────────────────
local CON_Y=tabH+C  -- header row starts below tab bar
local wpX=0
local wpW=math.floor(SW*0.39)
local rtX=wpW
local rtW=math.floor(SW*0.29)
local actX=rtX+rtW
local actW=SW-actX
local vis=math.floor((SH-CON_Y-32)/C)-1

-- Column header bar
setNextFillColor(Lp,0,0.04,0.16,1) setNextStrokeColor(Lp,0.15,0.32,0.62,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,tabH,SW,C)
if Sending then
  setNextFillColor(Lst,1.0,0.78,0.2,1) setNextTextAlign(Lst,AlignH_Right,AlignV_Middle)
  addText(Lst,fT,"⟳ SYNCING...",SW-8,tabH+C/2)
else
  setNextFillColor(Lt,0.35,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fT,#WP.." WPs  |  "..#RT.." Routes",SW-8,tabH+C/2)
end
setNextFillColor(Lx,1.0,0.86,0.0,1) setNextTextAlign(Lx,AlignH_Left,AlignV_Middle)
addText(Lx,fB,"◄ NAV BASE v2.1 ►",8,tabH+C/2)
addLine(Ll,0,tabH+C,SW,tabH+C)
addLine(Ll,wpX+wpW,CON_Y,wpX+wpW,SH-32)
addLine(Ll,rtX+rtW,CON_Y,rtX+rtW,SH-32)

-- ── WAYPOINTS ────────────────────────────────────────────────
PH(wpX,wpW,0,0.04,0.14)
setNextFillColor(Lx,1.0,0.86,0.0,1) setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
addText(Lx,fH,"WAYPOINTS ["..#WP.."]",wpX+wpW/2,CON_Y+C/2)
addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
local maxSW=math.max(0,#WP-vis)
local sCW=math.max(0,math.min(_S.scrollWP,maxSW))
for i=1,vis do
  local idx=i+sCW if idx>#WP then break end
  local wp=WP[idx] local ry=CON_Y+C+(i-1)*C
  local sel=(wp.n==SelWP)
  local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
  if sel then
    setNextFillColor(Lp,0.0,0.59,0.86,0.22) setNextStrokeColor(Lp,0.0,0.78,1.0,0.9)
    setNextStrokeWidth(Lp,1) addBox(Lp,wpX,ry,wpW,C)
  elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,wpX,ry,wpW,C) end
  setNextFillColor(Lt,0.30,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fS,idx..".",wpX+26,ry+C/2)
  local L=(sel or hv) and Ls or Lt
  if sel then setNextFillColor(Ls,0.0,0.87,1.0,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,wp.n,wpX+30,ry+C/2)
  setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,wpX,ry+C,wpX+wpW,ry+C)
  if hv and pr then setAct(json.encode({"selwp",wp.n})) end
end
if #WP>vis then
  local sbX=wpX+wpW-5 local sbY=CON_Y+C+2 local sbH=vis*C-4
  local tH=math.max(12,sbH*(vis/#WP))
  local tY=sbY+(sbH-tH)*(sCW/math.max(1,maxSW))
  setNextFillColor(Ll,0.1,0.22,0.44,0.4) addBox(Ll,sbX,sbY,4,sbH)
  setNextFillColor(Ll,0.0,0.63,1.0,0.8) addBox(Ll,sbX,tY,4,tH)
end

-- ── ROUTES / STOPS ───────────────────────────────────────────
if SelStop>0 and SelRT~="" then
  PH(rtX,rtW,0.0,0.06,0.14)
  setNextFillColor(Lh,0.70,0.85,1.0,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH,"◄ "..SelRT,rtX+8,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#STOPS-vis)
  local sCR=math.max(0,math.min(_S.scrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#STOPS then break end
    local st=STOPS[idx] local ry2=CON_Y+C+(i-1)*C
    local sel=(SelStop==idx)
    local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry2 and cy<ry2+C)
    if sel then
      setNextFillColor(Lp,0.0,0.40,0.80,0.22) setNextStrokeColor(Lp,0.3,0.7,1.0,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry2,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry2,rtW,C) end
    setNextFillColor(Lt,0.30,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",rtX+22,ry2+C/2)
    local lbl=st.label or st.c:sub(1,24)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.4,0.8,1.0,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,lbl,rtX+26,ry2+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry2+C,rtX+rtW,ry2+C)
    if hv and pr then setAct(json.encode({"selstop",idx})) end
  end
else
  PH(rtX,rtW,0,0.08,0.06)
  setNextFillColor(Lh,0.4,1.0,0.6,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
  addText(Lh,fH,"ROUTES ["..#RT.."]",rtX+rtW/2,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#RT-vis)
  local sCR=math.max(0,math.min(_S.scrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#RT then break end
    local r=RT[idx] local ry2=CON_Y+C+(i-1)*C
    local sel=(r.n==SelRT)
    local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry2 and cy<ry2+C)
    if sel then
      setNextFillColor(Lp,0.0,0.50,0.25,0.22) setNextStrokeColor(Lp,0.2,0.86,0.47,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry2,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry2,rtW,C) end
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.3,1.0,0.55,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,r.n,rtX+8,ry2+C/2)
    local np=#(r.pts or {})
    setNextFillColor(Lt,0.35,0.50,0.35,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,np.."▶",rtX+rtW-6,ry2+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry2+C,rtX+rtW,ry2+C)
    if hv and pr then setAct(json.encode({"selrt",r.n})) end
  end
end

-- ── ACTION PANEL ─────────────────────────────────────────────
PH(actX,actW,0.04,0.01,0.12)
setNextFillColor(Lh,0.70,0.47,1.0,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
addText(Lh,fH,"ACTIONS",actX+actW/2,CON_Y+C/2)
addLine(Ll,actX,CON_Y+C,actX+actW,CON_Y+C)
local selInfo=""
if SelWP~="" then selInfo="[WP] "..SelWP
elseif SelRT~="" and SelStop>0 then selInfo="[STOP "..SelStop.."] "..SelRT
elseif SelRT~="" then selInfo="[ROUTE] "..SelRT end
if selInfo~="" then
  setNextFillColor(Ls,0.0,0.87,1.0,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
  addText(Ls,fS,"SELECTED:",actX+8,CON_Y+C+8)
  setNextFillColor(Ls,0.0,0.87,1.0,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
  addText(Ls,fT,selInfo,actX+8,CON_Y+C+22)
end
local bX=actX+6 local bW=actW-12 local bH=26 local bG=4
local by=SH-32-(bH+bG)*8
if Btn("★ ADD WP (chat: add NAME)",    bX,by,bW,bH,true)                       then setAct(json.encode({"hint_add"}))      end by=by+bH+bG
if Btn("✎ RENAME",                     bX,by,bW,bH,selInfo~="")                then setAct(json.encode({"hint_rename"}))   end by=by+bH+bG
if Btn("✎ SET COORDS",                 bX,by,bW,bH,selInfo~="")                then setAct(json.encode({"hint_setpos"}))   end by=by+bH+bG
if Btn("+ NEW ROUTE",                  bX,by,bW,bH,true)                       then setAct(json.encode({"hint_newroute"})) end by=by+bH+bG
if Btn("+ ADD STOP TO ROUTE",          bX,by,bW,bH,SelRT~="" and SelStop==0)   then setAct(json.encode({"hint_addstop"}))  end by=by+bH+bG
if Btn("✕ DELETE SELECTED",            bX,by,bW,bH,selInfo~="")                then setAct(json.encode({"delete"}))        end by=by+bH+bG
if Btn("✕ CLEAR ALL WPs",              bX,by,bW,bH,#WP>0)                      then setAct(json.encode({"clearwps"}))      end by=by+bH+bG
if Btn("✕ CLEAR ALL ROUTES",           bX,by,bW,bH,#RT>0)                      then setAct(json.encode({"clearroutes"}))   end

-- ── FOOTER ───────────────────────────────────────────────────
addLine(Ll,0,SH-32,SW,SH-32)
setNextFillColor(Lp,0,0.02,0.08,0.95) addBox(Lp,0,SH-32,SW,32)
if Status~="" then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle) addText(Lst,fT,Status,SW/2,SH-16)
else
  setNextFillColor(Lt,0.28,0.28,0.44,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"Click to select  |  chat: add / del / rename / setpos / newroute / addstop / delstop / help",SW/2,SH-16)
end

setOutput(json.encode({action=_S.action, tab=_S.tab,
  scrollWP=_S.scrollWP, scrollRT=_S.scrollRT}))
requestAnimationFrame(1)
]]


--[[@
slot=-5
event=onStart()
args=
]]
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if x then return {w=tonumber(w),b=tonumber(b),x=tonumber(x),y=tonumber(y),z=tonumber(z)} end
  return nil
end
function SetStatus(msg,dur)
  StatusMsg=msg; StatusExpiry=system.getTime()+(dur or 6)
  system.print("[BASE] "..msg)
end
function AutoName(prefix,list)
  local i=1
  while true do
    local c=prefix.."-"..i; local taken=false
    for _,v in ipairs(list) do if v.n:lower()==c:lower() then taken=true;break end end
    if not taken then return c end; i=i+1
  end
end

-- ── Tab/prefix helpers ────────────────────────────────────────
-- Returns the tab name for a WP/route name given the known prefix list.
-- "Alliance-HomeBase" with prefix "Alliance" → tab="Alliance", short="HomeBase"
-- No matching prefix → tab="Personal", short=name
function GetTab(name)
  for _,pfx in ipairs(TabList) do
    if name:sub(1,#pfx+1):lower()==pfx:lower().."-" then
      return pfx, name:sub(#pfx+2)
    end
  end
  return "Personal", name
end

-- Filter WaypointList to the current tab, returning display names (prefix stripped)
function WPsForTab(tab)
  local out={}
  for _,wp in ipairs(WaypointList) do
    local t,short=GetTab(wp.n)
    if t==tab then table.insert(out,{n=short,c=wp.c,full=wp.n}) end
  end
  return out
end

-- Filter RouteList to the current tab
function RoutesForTab(tab)
  local out={}
  for _,r in ipairs(RouteList) do
    local t,short=GetTab(r.n)
    if t==tab then table.insert(out,{n=short,pts=r.pts,full=r.n}) end
  end
  return out
end


--[[@
slot=-1
event=onStart()
args=
]]

local VERSION="v2.1.0"
BaseChannel = "NavBase" --export: Channel ships use to reach this base
OrgTabs     = ""        --export: Comma-separated org prefixes e.g. "Alliance,Corp"

WaypointList = {}
RouteList    = {}
SelWP        = ""   -- full name (with prefix)
SelRoute     = ""   -- full name (with prefix)
SelStop      = 0
ActiveTab    = "Personal"
StatusMsg    = ""; StatusExpiry=0
SendQueue    = {}
SendIndex    = 1
Sending      = false
pending_ack  = false

-- Build tab list from OrgTabs export
TabList = {"Personal"}
for pfx in (OrgTabs..","):gmatch("([^,]+),") do
  local p=Trim(pfx)
  if p~="" then table.insert(TabList,p) end
end

function LoadData()
  if not databank then WaypointList={};RouteList={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  WaypointList = jd("waypoints") or {}
  RouteList    = jd("routes")    or {}
end

function SaveData()
  if not databank then return end
  databank.setStringValue("waypoints",json.encode(WaypointList))
  databank.setStringValue("routes",   json.encode(RouteList))
end

-- ── WP management ────────────────────────────────────────────
function MergeWP(name,posStr)
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); return end
  end
  table.insert(WaypointList,{n=name,c=posStr})
  table.sort(WaypointList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData()
end

function AddWP(name,posStr)
  MergeWP(name,posStr); SetStatus("Saved WP: "..name)
end

function DelWP(name)
  for i,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then
      table.remove(WaypointList,i)
      if SelWP==name then SelWP="" end
      SaveData(); SetStatus("Deleted WP: "..name); return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function RenameWP(old,new_)
  for _,v in ipairs(WaypointList) do if v.n:lower()==new_:lower() then SetStatus("Name exists: "..new_) return end end
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==old:lower() then
      wp.n=new_; if SelWP==old then SelWP=new_ end
      table.sort(WaypointList,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed to: "..new_); return
    end
  end
  SetStatus("WP not found: "..old)
end

function SetWPCoords(name,posStr)
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); SetStatus("Coords updated: "..name); return end
  end
  SetStatus("WP not found: "..name)
end

-- ── Route management ─────────────────────────────────────────
function MergeRoute(r)
  for i,e in ipairs(RouteList) do
    if e.n:lower()==r.n:lower() then RouteList[i]=r; SaveData(); return end
  end
  table.insert(RouteList,r)
  table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData()
end

function AddRoute(name)
  for _,r in ipairs(RouteList) do if r.n:lower()==name:lower() then SetStatus("Route exists: "..name) return false end end
  table.insert(RouteList,{n=name,pts={}})
  table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Route created: "..name); return true
end

function DelRoute(name)
  for i,r in ipairs(RouteList) do
    if r.n:lower()==name:lower() then
      table.remove(RouteList,i)
      if SelRoute==name then SelRoute="";SelStop=0 end
      SaveData(); SetStatus("Route deleted: "..name); return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function RenameRoute(old,new_)
  for _,v in ipairs(RouteList) do if v.n:lower()==new_:lower() then SetStatus("Name exists: "..new_) return end end
  for _,r in ipairs(RouteList) do
    if r.n:lower()==old:lower() then
      r.n=new_; if SelRoute==old then SelRoute=new_ end
      table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed to: "..new_); return
    end
  end
  SetStatus("Route not found: "..old)
end

function AddStop(routeName,arg)
  for _,r in ipairs(RouteList) do
    if r.n:lower()==routeName:lower() then
      local c,lbl=arg,arg
      if not ParsePos(arg) then
        local found=false
        for _,wp in ipairs(WaypointList) do
          if wp.n:lower()==arg:lower() then c=wp.c;lbl=wp.n;found=true;break end
        end
        if not found then SetStatus("Not a WP name or ::pos{}") return end
      end
      table.insert(r.pts,{c=c,label=lbl})
      SaveData(); SetStatus("Stop added ("..#r.pts..")"); return
    end
  end
  SetStatus("Route not found: "..routeName)
end

function DelStop(routeName,idx)
  for _,r in ipairs(RouteList) do
    if r.n:lower()==routeName:lower() then
      if idx<1 or idx>#r.pts then SetStatus("Index out of range") return end
      table.remove(r.pts,idx)
      if SelStop==idx then SelStop=math.max(0,idx-1) end
      SaveData(); SetStatus("Stop "..idx.." removed"); return
    end
  end
end

-- ── Send queue (throttled sync to ship) ──────────────────────
function StartSend(requester)
  LoadData()
  SendQueue={}
  for _,wp in ipairs(WaypointList) do
    table.insert(SendQueue,{type="wp",data={n=wp.n,c=wp.c}})
  end
  for _,r in ipairs(RouteList) do
    table.insert(SendQueue,{type="route",data={n=r.n,pts=r.pts}})
  end
  SendIndex=1; Sending=true
  emitter.send(BaseChannel,"<SyncCount>"..#SendQueue)
  unit.setTimer("send_tick",0.2)
  SetStatus("Sending "..#SendQueue.." items to: "..requester)
  PushState()
end

-- ── Screen push ───────────────────────────────────────────────
function PushState()
  if not screen then return end
  -- Build filtered lists for the active tab (strip prefix from display names)
  local dispWPs   = WPsForTab(ActiveTab)
  local dispRTs   = RoutesForTab(ActiveTab)
  -- Resolve stops for selected route (using full name)
  local selRoutePts={}
  if SelRoute~="" then
    for _,r in ipairs(RouteList) do if r.n==SelRoute then selRoutePts=r.pts;break end end
  end
  -- Convert SelWP/SelRoute to short name for screen display
  local _,selWPShort   = GetTab(SelWP)
  local _,selRTShort   = GetTab(SelRoute)
  screen.setScriptInput(json.encode({
    tabs    = TabList,
    tab     = ActiveTab,
    wps     = dispWPs,
    routes  = dispRTs,
    stops   = selRoutePts,
    selWP   = selWPShort,
    selRT   = selRTShort,
    selStop = SelStop,
    status  = StatusMsg,
    sending = Sending,
    ack     = pending_ack,
  }))
  pending_ack=false
  screen.setRenderScript(ScreenScript)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
if receiver then receiver.setChannelList({BaseChannel}) end
unit.setTimer("heartbeat",30)
unit.setTimer("tick",0.05)
unit.setTimer("screen_init",1)
system.print("=== Nav Base "..VERSION.." ===  WPs:"..#WaypointList.."  Routes:"..#RouteList)
system.print("Tabs: "..table.concat(TabList,", "))
if screen then screen.activate() end
PushState()


--[[@
slot=-1
event=onStop()
args=
]]
if screen then screen.setCenteredText("Nav Base") end


--[[@
slot=-1
event=onTimer(tag)
args="screen_init"
]]
unit.stopTimer("screen_init")
PushState()


--[[@
slot=-1
event=onTimer(tag)
args="send_tick"
]]
if not Sending then return end
if SendIndex>#SendQueue then
  emitter.send(BaseChannel,"<SyncComplete>")
  Sending=false
  SetStatus("Sync complete ("..#SendQueue.." items sent)")
  PushState(); return
end
local item=SendQueue[SendIndex]
if item.type=="wp" then
  emitter.send(BaseChannel,"<SyncWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(BaseChannel,"<SyncRoute>"..json.encode(item.data):gsub('"',"@@@"))
end
SendIndex=SendIndex+1


--[[@
slot=-1
event=onTimer(tag)
args="heartbeat"
]]
if StatusMsg~="" and system.getTime()>StatusExpiry then StatusMsg=""; PushState() end
system.print("[BASE] Alive  WPs:"..#WaypointList.."  Routes:"..#RouteList)


--[[@
slot=-1
event=onTimer(tag)
args="tick"
]]
if not screen then return end
local raw=screen.getScriptOutput()
if not raw or raw=="" then return end
screen.clearScriptOutput()
local ok,d=pcall(json.decode,raw)
if not ok or type(d)~="table" then return end

-- Sync screen-side scroll/tab state back to PB
if d.tab and d.tab~="" and d.tab~=ActiveTab then
  ActiveTab=d.tab; SelWP=""; SelRoute=""; SelStop=0
end

if not d.action or d.action=="" then PushState(); return end
pending_ack=true

local ok2,act
ok2,act=pcall(json.decode,d.action)
if not ok2 or type(act)~="table" then PushState(); return end
local cmd=act[1]

-- Tab switch comes through action channel too (belt-and-suspenders)
if cmd=="tab" then
  ActiveTab=act[2]; SelWP=""; SelRoute=""; SelStop=0

-- WP selection — screen sends short name; resolve to full name
elseif cmd=="selwp" then
  local tab,_ = ActiveTab,act[2]
  local pfx=(tab=="Personal") and "" or tab.."-"
  local full=pfx..act[2]
  SelWP=(SelWP:lower()==full:lower() and "" or full)
  SelRoute=""; SelStop=0

-- Route selection — same short→full resolution
elseif cmd=="selrt" then
  local pfx=(ActiveTab=="Personal") and "" or ActiveTab.."-"
  local full=pfx..act[2]
  if SelRoute:lower()==full:lower() then
    SelStop=(SelStop==0 and 1 or 0)
  else SelRoute=full; SelStop=0; SelWP="" end

elseif cmd=="selstop"     then SelStop=(SelStop==act[2] and 0 or act[2])

elseif cmd=="delete" then
  if SelWP~=""  then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0 end

elseif cmd=="clearwps" then
  -- Only clear WPs belonging to the active tab
  local keep={}
  for _,wp in ipairs(WaypointList) do
    local t=GetTab(wp.n)
    if t~=ActiveTab then table.insert(keep,wp) end
  end
  WaypointList=keep; SelWP=""; SaveData()
  SetStatus("Cleared WPs for tab: "..ActiveTab)

elseif cmd=="clearroutes" then
  local keep={}
  for _,r in ipairs(RouteList) do
    local t=GetTab(r.n)
    if t~=ActiveTab then table.insert(keep,r) end
  end
  RouteList=keep; SelRoute=""; SelStop=0; SaveData()
  SetStatus("Cleared routes for tab: "..ActiveTab)

elseif cmd=="hint_add"      then SetStatus("Chat: add NAME ::pos{0,0,x,y,z}",8)
elseif cmd=="hint_rename"   then SetStatus("Chat: rename NEWNAME",8)
elseif cmd=="hint_setpos"   then SetStatus("Chat: setpos ::pos{0,0,x,y,z}",8)
elseif cmd=="hint_newroute" then SetStatus("Chat: newroute NAME",8)
elseif cmd=="hint_addstop"  then SetStatus("Chat: addstop WPname  or  addstop ::pos{...}",8)
end
PushState()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    MergeWP(wp.n,wp.c); SetStatus("Received WP: "..wp.n); PushState()
  end
end

if message:find("<PushRoute>",1,true) then
  local raw=message:gsub("<PushRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    MergeRoute(r); SetStatus("Received route: "..r.n); PushState()
  end
end

if message:find("<RequestSync>",1,true) then
  if Sending then return end
  local who=message:gsub("<RequestSync>","")
  StartSend(who)
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

-- Chat commands use the active tab prefix automatically.
-- For org tabs, prefix is prepended to names automatically.
local function TabPrefix()
  return (ActiveTab=="Personal") and "" or ActiveTab.."-"
end

if lo=="help" then
  system.print("══════════════════════════════════")
  system.print("  NAV BASE v2.1  CHAT COMMANDS")
  system.print("══════════════════════════════════")
  system.print("add NAME ::pos{..}  add/update WP (prefixed for active tab)")
  system.print("del                 delete selected item")
  system.print("rename NEWNAME      rename selected item")
  system.print("setpos ::pos{..}    update selected WP coords")
  system.print("newroute NAME       create route (prefixed for active tab)")
  system.print("addstop WPname      add stop to selected route")
  system.print("addstop ::pos{..}   add raw pos stop")
  system.print("delstop N           remove stop N")
  system.print("list                list waypoints on active tab")
  system.print("routes              list routes on active tab")
  system.print("tab NAME            switch active tab")
  return
end

local tabN=t:match("^[Tt][Aa][Bb]%s+(.+)")
if tabN then
  tabN=Trim(tabN)
  for _,tn in ipairs(TabList) do
    if tn:lower()==tabN:lower() then
      ActiveTab=tn; SelWP=""; SelRoute=""; SelStop=0
      SetStatus("Tab: "..ActiveTab); PushState(); return
    end
  end
  SetStatus("Unknown tab: "..tabN); PushState(); return
end

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(%S+)%s*(.*)")
if addN then
  addC=Trim(addC)
  if ParsePos(addC) then AddWP(TabPrefix()..addN,addC)
  else SetStatus("Provide coords: add NAME ::pos{0,0,x,y,z}",8) end
  PushState(); return
end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(TabPrefix()..Trim(nrN)); PushState(); return end

local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  local newFull=TabPrefix()..rnN
  if SelWP~="" then RenameWP(SelWP,newFull)
  elseif SelRoute~="" then RenameRoute(SelRoute,newFull)
  else SetStatus("Select a WP or route first") end
  PushState(); return
end

local spC=t:match("^[Ss][Ee][Tt][Pp][Oo][Ss]%s+(.*)")
if spC then
  spC=Trim(spC)
  if not ParsePos(spC) then SetStatus("Bad coords") PushState(); return end
  if SelWP~="" then SetWPCoords(SelWP,spC)
  elseif SelRoute~="" and SelStop>0 then
    for _,r in ipairs(RouteList) do
      if r.n==SelRoute and r.pts[SelStop] then
        r.pts[SelStop].c=spC; SaveData(); SetStatus("Stop updated")
      end
    end
  else SetStatus("Select a WP or stop first") end
  PushState(); return
end

local asA=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.*)")
if asA then
  if SelRoute=="" then SetStatus("Select a route first")
  else AddStop(SelRoute,Trim(asA)) end
  PushState(); return
end

local dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%d+)")
if dsN then
  if SelRoute=="" then SetStatus("Select a route first")
  else DelStop(SelRoute,tonumber(dsN)) end
  PushState(); return
end

if lo=="del" then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0
  else SetStatus("Select something first") end
  PushState(); return
end

if lo=="list" then
  local wps=WPsForTab(ActiveTab)
  system.print("─── WAYPOINTS ["..ActiveTab.."] ("..#wps..") ───")
  for i,wp in ipairs(wps) do system.print(i..".  "..wp.n.."  "..wp.c) end
  return
end

if lo=="routes" then
  local rts=RoutesForTab(ActiveTab)
  system.print("─── ROUTES ["..ActiveTab.."] ("..#rts..") ───")
  for i,r in ipairs(rts) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  return
end

SetStatus("Unknown: '"..lo.."'  type help"); PushState()
