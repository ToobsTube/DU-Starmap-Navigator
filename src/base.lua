-- ================================================================
-- NAVIGATOR PERSONAL BASE v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (Databank)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
--
-- Stores personal waypoints and routes.
-- Ships push data here; this station syncs back on request.
-- Screen: paste dist/Navigator_Base_Screen_v2.0.txt into the Screen's Lua editor.
-- PB pushes state via setScriptInput() and reads clicks via getScriptOutput() on a 0.05s tick.
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
pending_ack  = false

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

-- ── Screen (setScriptInput/getScriptOutput pattern) ──────────
function PushState()
  if not screen then return end
  local selRoutePts={}
  if SelRoute~="" then
    for _,r in ipairs(RouteList) do if r.n==SelRoute then selRoutePts=r.pts;break end end
  end
  screen.setScriptInput(json.encode({
    scrollWP=ScrollWP, scrollRT=ScrollRT,
    selWP=SelWP,       selRT=SelRoute,   selStop=SelStop,
    status=StatusMsg,  sending=Sending,
    wps=WaypointList,  routes=RouteList, stops=selRoutePts,
    ack=pending_ack
  }))
  pending_ack=false
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
if receiver then receiver.setChannelList({BaseChannel}) end
unit.setTimer("heartbeat",30)
unit.setTimer("tick",0.05)
unit.setTimer("screen_init",1)
system.print("=== Nav Base "..VERSION.." ===  WPs:"..#WaypointList.."  Routes:"..#RouteList)
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
if not ok or type(d)~="table" or not d.action or d.action=="" then return end
pending_ack=true
local act_data
ok,act_data=pcall(json.decode,d.action)
if not ok or type(act_data)~="table" then PushState(); return end
local act=act_data[1]
if     act=="selwp"         then SelWP=(SelWP==act_data[2] and "" or act_data[2]); SelRoute=""; SelStop=0
elseif act=="selrt"         then
  if SelRoute==act_data[2] then SelStop=(SelStop==0 and 1 or 0)
  else SelRoute=act_data[2]; SelStop=0; SelWP="" end
elseif act=="selstop"       then SelStop=(SelStop==act_data[2] and 0 or act_data[2])
elseif act=="delete"        then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0 end
elseif act=="clearwps"      then WaypointList={}; SelWP=""; SaveData(); SetStatus("All WPs cleared")
elseif act=="clearroutes"   then RouteList={}; SelRoute=""; SelStop=0; SaveData(); SetStatus("All routes cleared")
elseif act=="hint_add"      then SetStatus("Chat: add NAME ::pos{0,0,x,y,z}",8)
elseif act=="hint_rename"   then SetStatus("Chat: rename NEWNAME",8)
elseif act=="hint_setpos"   then SetStatus("Chat: setpos ::pos{0,0,x,y,z}",8)
elseif act=="hint_newroute" then SetStatus("Chat: newroute NAME",8)
elseif act=="hint_addstop"  then SetStatus("Chat: addstop WPname  or  addstop ::pos{...}",8)
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
  PushState(); return
end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(Trim(nrN)); PushState(); return end

local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  if SelWP~="" then RenameWP(SelWP,rnN)
  elseif SelRoute~="" then RenameRoute(SelRoute,rnN)
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

SetStatus("Unknown: '"..lo.."'  type help"); PushState()
