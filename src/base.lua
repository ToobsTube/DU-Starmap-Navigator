-- ================================================================
-- NAVIGATOR PERSONAL BASE v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS:
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (Databank)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
--
-- Stores personal waypoints and routes.
-- Ships push data here; this station syncs back on request.
-- Screen: click to select, chat to edit.
-- ================================================================

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
  StatusMsg=msg; StatusExpiry=os.clock()+(dur or 6)
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


--[[@
slot=-1
event=onStart()
args=
]]
local VERSION="v2.0.0"
BaseChannel ="NavBase" --export: Channel ships use to reach this base

WaypointList = {}
RouteList    = {}
SelWP        = ""
SelRoute     = ""
SelStop      = 0
ScrollWP     = 0
ScrollRT     = 0
StatusMsg    = ""; StatusExpiry=0
SendQueue    = {}
SendIndex    = 1
Sending      = false

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
  DrawScreen()
end

-- ── Screen ───────────────────────────────────────────────────
function DrawScreen() if not screen then return end; screen.setRenderScript(BuildScreenScript()) end

function BuildScreenScript()
  local selRoutePts={}
  if SelRoute~="" then
    for _,r in ipairs(RouteList) do if r.n==SelRoute then selRoutePts=r.pts;break end end
  end
  local wpEnc=json.encode(WaypointList):gsub('"',"@@@")
  local rtEnc=json.encode(RouteList):gsub('"',"@@@")
  local ptEnc=json.encode(selRoutePts):gsub('"',"@@@")

  local S={}
  S[1]=string.format([[
local json=require('dkjson')
local C=32 local SW,SH=1024,576
local ScrollWP=%d local ScrollRT=%d
local SelWP=%q local SelRT=%q local SelStop=%d
local StatusMsg=%q local Sending=%s
local _w=%q local _r=%q local _p=%q
local WP=json.decode(_w:gsub("@@@",'"'))or{}
local RT=json.decode(_r:gsub("@@@",'"'))or{}
local STOPS=json.decode(_p:gsub("@@@",'"'))or{}
]],
    ScrollWP,ScrollRT,SelWP,SelRoute,SelStop,
    StatusMsg,tostring(Sending),wpEnc,rtEnc,ptEnc)

  S[2]=[[
local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer() local Ls=createLayer() local Lt=createLayer()
local Lh=createLayer() local Lx=createLayer() local Lst=createLayer()
local cx,cy=getCursor() local pr=getCursorPressed() local Out=""
local fT=loadFont("Montserrat-Light",18) local fS=loadFont("Montserrat-Light",13)
local fH=loadFont("Montserrat-Light",20) local fB=loadFont("Montserrat-Light",24)
setDefaultFillColor(Lt,Shape_Text,0.82,0.82,0.82,1)
setDefaultFillColor(Lh,Shape_Text,0.70,0.85,1.0,1)
setDefaultFillColor(Ls,Shape_Text,0.0,0.87,1.0,1)
setDefaultFillColor(Lx,Shape_Text,1.0,0.86,0.0,1)
setDefaultFillColor(Lst,Shape_Text,1.0,0.78,0.2,1)
setDefaultStrokeColor(Ll,Shape_Line,0.15,0.32,0.62,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)
setNextFillColor(Lbg,0,0.008,0.04,1) addBox(Lbg,0,0,SW,SH)
local wpX,wpW=0,400 local rtX,rtW=400,300 local actX,actW=700,324
local CON_Y=32 local CON_H=SH-64 local vis=math.floor(CON_H/C)-1
local function PH(x,w,r,g,b)
  setNextFillColor(Lp,r,g,b,0.88) addBox(Lp,x,CON_Y,w,C)
end
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,0.06,0.06,0.14,0.7) setNextStrokeColor(Lb,0.18,0.18,0.28,0.5)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,0.28,0.28,0.38,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fT,tx,x+w/2,y+h/2) return false
  elseif hv then
    setNextFillColor(Lb,0.0,0.31,0.78,1) setNextStrokeColor(Lb,0.4,0.63,1.0,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  else
    setNextFillColor(Lb,0.0,0.16,0.55,0.9) setNextStrokeColor(Lb,0.32,0.5,0.87,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  end
  return hv and pr
end
]]

  S[3]=[[
-- HEADER
setNextFillColor(Lp,0,0.04,0.16,1) setNextStrokeColor(Lp,0.15,0.32,0.62,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,C)
setNextTextAlign(Lx,AlignH_Left,AlignV_Middle) addText(Lx,fB,"◄ NAV BASE v2.0 ►",8,C/2)
if Sending then
  setNextFillColor(Lst,1.0,0.78,0.2,1) setNextTextAlign(Lst,AlignH_Right,AlignV_Middle)
  addText(Lst,fT,"⟳ SYNCING...",SW-8,C/2)
else
  setNextFillColor(Lt,0.35,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fT,#WP.." WPs  |  "..#RT.." Routes",SW-8,C/2)
end
addLine(Ll,0,C,SW,C)
addLine(Ll,wpX+wpW,CON_Y,wpX+wpW,SH-32)
addLine(Ll,rtX+rtW,CON_Y,rtX+rtW,SH-32)
]]

  S[4]=[[
-- WAYPOINTS
PH(wpX,wpW,0,0.04,0.14)
setNextFillColor(Lx,1.0,0.86,0.0,1) setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
addText(Lx,fH,"WAYPOINTS ["..#WP.."]",wpX+wpW/2,CON_Y+C/2)
addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
local maxSW=math.max(0,#WP-vis) local sCW=math.max(0,math.min(ScrollWP,maxSW))
for i=1,vis do
  local idx=i+sCW if idx>#WP then break end
  local wp=WP[idx] local ry=CON_Y+C+(i-1)*C
  local sel=(wp.n==SelWP) local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
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
  if hv and pr then Out=json.encode({"selwp",wp.n}) end
end
if #WP>vis then
  local sbX=wpX+wpW-5 local sbY=CON_Y+C+2 local sbH=vis*C-4
  local tH=math.max(12,sbH*(vis/#WP)) local tY=sbY+(sbH-tH)*(sCW/math.max(1,maxSW))
  setNextFillColor(Ll,0.1,0.22,0.44,0.4) addBox(Ll,sbX,sbY,4,sbH)
  setNextFillColor(Ll,0.0,0.63,1.0,0.8) addBox(Ll,sbX,tY,4,tH)
end
]]

  S[5]=[[
-- ROUTES / STOPS
if SelStop>0 and SelRT~="" then
  PH(rtX,rtW,0.0,0.06,0.14)
  setNextFillColor(Lh,0.70,0.85,1.0,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH,"◄ "..SelRT,rtX+8,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#STOPS-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#STOPS then break end
    local st=STOPS[idx] local ry=CON_Y+C+(i-1)*C
    local sel=(SelStop==idx) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,0.0,0.40,0.80,0.22) setNextStrokeColor(Lp,0.3,0.7,1.0,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    setNextFillColor(Lt,0.30,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",rtX+22,ry+C/2)
    local lbl=st.label or st.c:sub(1,24)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.4,0.8,1.0,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,lbl,rtX+26,ry+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=json.encode({"selstop",idx}) end
  end
else
  PH(rtX,rtW,0,0.08,0.06)
  setNextFillColor(Lh,0.4,1.0,0.6,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
  addText(Lh,fH,"ROUTES ["..#RT.."]",rtX+rtW/2,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#RT-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#RT then break end
    local r=RT[idx] local ry=CON_Y+C+(i-1)*C
    local sel=(r.n==SelRT) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,0.0,0.50,0.25,0.22) setNextStrokeColor(Lp,0.2,0.86,0.47,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.3,1.0,0.55,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,r.n,rtX+8,ry+C/2)
    local np=#(r.pts or {})
    setNextFillColor(Lt,0.35,0.50,0.35,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,np.."▶",rtX+rtW-6,ry+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=json.encode({"selrt",r.n}) end
  end
end
]]

  S[6]=[[
-- ACTION PANEL
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
if Btn("★ ADD WP (chat: add NAME)",bX,by,bW,bH,true)            then Out=json.encode({"hint_add"})            end by=by+bH+bG
if Btn("✎ RENAME",                 bX,by,bW,bH,selInfo~="")     then Out=json.encode({"hint_rename"})         end by=by+bH+bG
if Btn("✎ SET COORDS",             bX,by,bW,bH,selInfo~="")     then Out=json.encode({"hint_setpos"})         end by=by+bH+bG
if Btn("+ NEW ROUTE",              bX,by,bW,bH,true)            then Out=json.encode({"hint_newroute"})       end by=by+bH+bG
if Btn("+ ADD STOP TO ROUTE",      bX,by,bW,bH,SelRT~="" and SelStop==0) then Out=json.encode({"hint_addstop"}) end by=by+bH+bG
if Btn("✕ DELETE SELECTED",        bX,by,bW,bH,selInfo~="")     then Out=json.encode({"delete"})              end by=by+bH+bG
if Btn("✕ CLEAR ALL WPs",          bX,by,bW,bH,#WP>0)           then Out=json.encode({"clearwps"})            end by=by+bH+bG
if Btn("✕ CLEAR ALL ROUTES",       bX,by,bW,bH,#RT>0)           then Out=json.encode({"clearroutes"})         end
]]

  S[7]=[[
-- FOOTER
addLine(Ll,0,SH-32,SW,SH-32)
setNextFillColor(Lp,0,0.02,0.08,0.95) addBox(Lp,0,SH-32,SW,32)
if StatusMsg~="" then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle) addText(Lst,fT,StatusMsg,SW/2,SH-16)
else
  setNextFillColor(Lt,0.28,0.28,0.44,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"Click to select  |  chat: add / del / rename / setpos / newroute / addstop / delstop / help",SW/2,SH-16)
end
setOutput(Out) requestAnimationFrame(1)
]]
  return table.concat(S)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
if screen   then screen.activate() end
if receiver then receiver.setChannelList({BaseChannel}) end
unit.setTimer("heartbeat",30)
system.print("=== Nav Base "..VERSION.." ===  WPs:"..#WaypointList.."  Routes:"..#RouteList)
DrawScreen()


--[[@
slot=-1
event=onStop()
args=
]]
if screen then screen.setCenteredText("Nav Base") end


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
  DrawScreen(); return
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
if StatusMsg~="" and os.clock()>StatusExpiry then StatusMsg=""; DrawScreen() end
system.print("[BASE] Alive  WPs:"..#WaypointList.."  Routes:"..#RouteList)


--[[@
slot=0
event=onMouseUp(x,y)
args=*,*
]]
local raw=screen.getScriptOutput()
if not raw or raw=="" then return end
local ok,d=pcall(json.decode,raw)
if not ok or type(d)~="table" then return end
local act=d[1]
if     act=="selwp"       then SelWP=(SelWP==d[2] and "" or d[2]); SelRoute=""; SelStop=0
elseif act=="selrt"       then
  if SelRoute==d[2] then SelStop=(SelStop==0 and 1 or 0)
  else SelRoute=d[2]; SelStop=0; SelWP="" end
elseif act=="selstop"     then SelStop=(SelStop==d[2] and 0 or d[2])
elseif act=="delete"      then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0 end
elseif act=="clearwps"    then
  WaypointList={}; SelWP=""; SaveData(); SetStatus("All WPs cleared")
elseif act=="clearroutes" then
  RouteList={}; SelRoute=""; SelStop=0; SaveData(); SetStatus("All routes cleared")
elseif act=="hint_add"    then SetStatus("Chat: add NAME ::pos{0,0,x,y,z}",8)
elseif act=="hint_rename" then SetStatus("Chat: rename NEWNAME",8)
elseif act=="hint_setpos" then SetStatus("Chat: setpos ::pos{0,0,x,y,z}",8)
elseif act=="hint_newroute" then SetStatus("Chat: newroute NAME",8)
elseif act=="hint_addstop"  then SetStatus("Chat: addstop WPname  or  addstop ::pos{...}",8)
end
DrawScreen()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    MergeWP(wp.n,wp.c); SetStatus("Received WP: "..wp.n); DrawScreen()
  end
end

if message:find("<PushRoute>",1,true) then
  local raw=message:gsub("<PushRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    MergeRoute(r); SetStatus("Received route: "..r.n); DrawScreen()
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

if lo=="help" then
  system.print("══════════════════════════════════")
  system.print("  NAV BASE v2.0  CHAT COMMANDS")
  system.print("══════════════════════════════════")
  system.print("add NAME ::pos{..}  add/update WP")
  system.print("del                 delete selected item")
  system.print("rename NEWNAME      rename selected item")
  system.print("setpos ::pos{..}    update selected WP coords")
  system.print("newroute NAME       create empty route")
  system.print("addstop WPname      add stop to selected route")
  system.print("addstop ::pos{..}   add raw pos stop")
  system.print("delstop N           remove stop N")
  system.print("list                list all waypoints")
  system.print("routes              list all routes")
  return
end

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(%S+)%s*(.*)")
if addN then
  addC=Trim(addC)
  if ParsePos(addC) then AddWP(addN,addC)
  else SetStatus("Provide coords: add NAME ::pos{0,0,x,y,z}",8) end
  DrawScreen(); return
end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(Trim(nrN)); DrawScreen(); return end

local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  if SelWP~="" then RenameWP(SelWP,rnN)
  elseif SelRoute~="" then RenameRoute(SelRoute,rnN)
  else SetStatus("Select a WP or route first") end
  DrawScreen(); return
end

local spC=t:match("^[Ss][Ee][Tt][Pp][Oo][Ss]%s+(.*)")
if spC then
  spC=Trim(spC)
  if not ParsePos(spC) then SetStatus("Bad coords") DrawScreen(); return end
  if SelWP~="" then SetWPCoords(SelWP,spC)
  elseif SelRoute~="" and SelStop>0 then
    for _,r in ipairs(RouteList) do
      if r.n==SelRoute and r.pts[SelStop] then
        r.pts[SelStop].c=spC; SaveData(); SetStatus("Stop updated")
      end
    end
  else SetStatus("Select a WP or stop first") end
  DrawScreen(); return
end

local asA=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.*)")
if asA then
  if SelRoute=="" then SetStatus("Select a route first")
  else AddStop(SelRoute,Trim(asA)) end
  DrawScreen(); return
end

local dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%d+)")
if dsN then
  if SelRoute=="" then SetStatus("Select a route first")
  else DelStop(SelRoute,tonumber(dsN)) end
  DrawScreen(); return
end

if lo=="del" then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0
  else SetStatus("Select something first") end
  DrawScreen(); return
end

if lo=="list" then
  system.print("─── WAYPOINTS ("..#WaypointList..") ───")
  for i,wp in ipairs(WaypointList) do system.print(i..".  "..wp.n.."  "..wp.c) end
  return
end

if lo=="routes" then
  system.print("─── ROUTES ("..#RouteList..") ───")
  for i,r in ipairs(RouteList) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  return
end

SetStatus("Unknown: '"..lo.."'  type help"); DrawScreen()
