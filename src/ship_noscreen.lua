-- ================================================================
-- NAVIGATOR SHIP - NO SCREEN VERSION v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: databank   (Databank)
--   Slot 1: receiver   (Receiver)
--   Slot 2: emitter    (Emitter)
--
-- Output via Lua chat. AR marker via system.setWaypoint().
-- Alt+Up/Down = browse menu  |  Alt+Right = activate  |  Alt+Shift+Ins = toggle HUD
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
function FormatDist(m)
  if not m then return "---" end
  if m>=2e7  then return string.format("%.2f su",m/200000)
  elseif m>=1e6  then return string.format("%.1f Mm",m/1e6)
  elseif m>=1000 then return string.format("%.1f km",m/1000)
  else return string.format("%.0f m",m) end
end
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if not x then return nil end
  w,b,x,y,z=tonumber(w),tonumber(b),tonumber(x),tonumber(y),tonumber(z)
  -- world coords (body=0) — already XYZ
  if b==0 then return {x=x,y=y,z=z} end
  -- planet-relative — convert via atlas
  if Atlas then
    for _,body in pairs(Atlas[0]) do
      if body.id==b then
        local deg=math.pi/180
        local lat,lon,alt=x*deg,y*deg,z
        local r=body.radius+alt
        local cx=r*math.cos(lat)*math.cos(lon)
        local cy=r*math.cos(lat)*math.sin(lon)
        local cz=r*math.sin(lat)
        local c=body.center
        return {x=c[1]+cx,y=c[2]+cy,z=c[3]+cz}
      end
    end
  end
  -- atlas missing for this body — return nil so distance shows ---
  return nil
end
function CalcDist(p1,p2)
  if not p1 or not p2 then return nil end
  local dx,dy,dz=p1.x-p2.x,p1.y-p2.y,p1.z-p2.z
  return math.sqrt(dx*dx+dy*dy+dz*dz)
end
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end
function OrgKey(n) return "org_"..n:gsub("[^%w]","_") end
function AutoName(prefix,list)
  local i=1
  while true do
    local c=prefix.."-"..i; local taken=false
    for _,v in ipairs(list) do if v.n:lower()==c:lower() then taken=true;break end end
    if not taken then return c end; i=i+1
  end
end
function BuildShipID()
  local name=construct and construct.getName() or "Ship"
  local cid=construct and tostring(construct.getId()) or ""
  if cid~="" then return name.."#"..cid:sub(-6) end
  return name
end
function SetStatus(msg) system.print("[NAV] "..msg) end


--[[@
slot=-1
event=onStart()
args=
]]

local VERSION="v2.0.0"
CustomAtlas  ="atlas"  --export: Atlas file to load (default=atlas, set to custom filename in autoconf/custom/)
BaseChannel ="NavBase" --export: Personal base channel
OrgChannel1 ="NavOrg"  --export: Org base channel 1
OrgChannel2 =""        --export: Org base channel 2 (optional)
OrgChannel3 =""        --export: Org base channel 3 (optional)

PersonalWPs    = {}
PersonalRoutes = {}
OrgNames       = {}
OrgData        = {}
NavTarget      = nil
ShipID         = ""
SyncReceived   = 0
SyncOrgName    = ""
MenuIndex      = 0   -- keyboard cursor position
ActiveContext  = "personal"  -- "personal" or org name
L_ALT          = false
L_SHIFT        = false
HUD_VISIBLE    = true

-- ── Databank ──────────────────────────────────────────────────
function LoadData()
  if not databank then PersonalWPs={};PersonalRoutes={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  PersonalWPs    = jd("personal_wps")    or {}
  PersonalRoutes = jd("personal_routes") or {}
  OrgNames       = jd("org_names")       or {}
  OrgData={}
  for _,org in ipairs(OrgNames) do
    local k=OrgKey(org)
    OrgData[org]={wps=jd(k.."_wps") or {},routes=jd(k.."_routes") or {}}
  end
  NavTarget=jd("nav_target")
  ShipID=BuildShipID()
end

function SaveData()
  if not databank then return end
  databank.setStringValue("personal_wps",    json.encode(PersonalWPs))
  databank.setStringValue("personal_routes", json.encode(PersonalRoutes))
  databank.setStringValue("org_names",       json.encode(OrgNames))
  for _,org in ipairs(OrgNames) do
    local k=OrgKey(org)
    databank.setStringValue(k.."_wps",    json.encode(OrgData[org].wps))
    databank.setStringValue(k.."_routes", json.encode(OrgData[org].routes))
  end
  databank.setStringValue("nav_target", NavTarget and json.encode(NavTarget) or "")
end

-- ── Context helpers ───────────────────────────────────────────
function ContextWPs()
  if ActiveContext=="personal" then return PersonalWPs end
  return OrgData[ActiveContext] and OrgData[ActiveContext].wps or {}
end
function ContextRoutes()
  if ActiveContext=="personal" then return PersonalRoutes end
  return OrgData[ActiveContext] and OrgData[ActiveContext].routes or {}
end
function ContextTabIdx()
  if ActiveContext=="personal" then return 0 end
  for i,o in ipairs(OrgNames) do if o==ActiveContext then return i end end
  return 0
end

-- ── WP / Route management ─────────────────────────────────────
function AddWP(name,posStr)
  local list=ContextWPs()
  for _,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); SetStatus("Updated: "..name); return true end
  end
  table.insert(list,{n=name,c=posStr})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Saved WP: "..name); return true
end

function DelWP(name)
  local list=ContextWPs()
  for i,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then
      table.remove(list,i)
      if NavTarget and NavTarget.t=="wp" and NavTarget.n:lower()==name:lower() then NavTarget=nil end
      SaveData(); SetStatus("Deleted: "..name); return true
    end
  end
  SetStatus("Not found: "..name); return false
end

function AddRoute(name)
  local list=ContextRoutes()
  for _,r in ipairs(list) do if r.n:lower()==name:lower() then SetStatus("Route exists: "..name) return false end end
  table.insert(list,{n=name,pts={}})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Route created: "..name); return true
end

function DelRoute(name)
  local list=ContextRoutes()
  for i,r in ipairs(list) do
    if r.n:lower()==name:lower() then
      table.remove(list,i)
      if NavTarget and NavTarget.t=="route" and NavTarget.n:lower()==name:lower() then NavTarget=nil end
      SaveData(); SetStatus("Route deleted: "..name); return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function AddStop(routeName,arg)
  local routes=ContextRoutes(); local wps=ContextWPs()
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      local c,lbl=arg,arg
      if not ParsePos(arg) then
        local found=false
        for _,wp in ipairs(wps) do
          if wp.n:lower()==arg:lower() then c=wp.c;lbl=wp.n;found=true;break end
        end
        if not found then SetStatus("Not a WP name or ::pos{}") return end
      end
      table.insert(r.pts,{c=c,label=lbl})
      SaveData(); SetStatus("Stop added ("..#r.pts.." total)"); return
    end
  end
  SetStatus("Route not found: "..routeName)
end

function DelStop(routeName,idx)
  local routes=ContextRoutes()
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      if idx<1 or idx>#r.pts then SetStatus("Stop index out of range") return end
      table.remove(r.pts,idx)
      SaveData(); SetStatus("Stop "..idx.." removed"); return
    end
  end
end

-- ── Navigation ───────────────────────────────────────────────
function GetCurrentPos()
  local p=construct.getWorldPosition(); if p then return {x=p[1],y=p[2],z=p[3]} end
  return nil
end
function GetCurrentPosStr()
  local p=GetCurrentPos(); if not p then return nil end
  return string.format("::pos{0,0,%.4f,%.4f,%.4f}",p.x,p.y,p.z)
end
function UpdateWaypoint()
  if NavTarget and NavTarget.c and NavTarget.c~="" then
    system.setWaypoint(NavTarget.c)
  end
end
function ClearWaypoint()
  NavTarget=nil; system.setWaypoint(""); SaveData()
end

function SetNavWP(name)
  for _,wp in ipairs(ContextWPs()) do
    if wp.n:lower()==name:lower() then
      NavTarget={t="wp",n=wp.n,c=wp.c,tab=ContextTabIdx()}
      SaveData(); UpdateWaypoint(); SetStatus("Navigating: "..wp.n); return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function SetNavRoute(name,startStop)
  for _,r in ipairs(ContextRoutes()) do
    if r.n:lower()==name:lower() then
      if #r.pts==0 then SetStatus("Route has no stops") return false end
      local idx=startStop or 1
      NavTarget={t="route",n=r.n,c=r.pts[idx].c,tab=ContextTabIdx(),stopIdx=idx,stopTotal=#r.pts}
      SaveData(); UpdateWaypoint()
      SetStatus("Route: "..r.n.."  stop "..idx.."/"..#r.pts); return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function NextStop()
  if not NavTarget or NavTarget.t~="route" then SetStatus("Not navigating a route") return end
  local tab=NavTarget.tab
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx+1
      if idx>#r.pts then SetStatus("Already at last stop") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      SetStatus("Stop "..idx.."/"..#r.pts.."  "..(r.pts[idx].label or r.pts[idx].c:sub(1,30))); return
    end
  end
end

function PrevStop()
  if not NavTarget or NavTarget.t~="route" then return end
  local tab=NavTarget.tab
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx-1
      if idx<1 then SetStatus("Already at first stop") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      SetStatus("Stop "..idx.."/"..#r.pts.."  "..(r.pts[idx].label or r.pts[idx].c:sub(1,30))); return
    end
  end
end

-- ── Sync / Push ──────────────────────────────────────────────
function RequestSync(ch)
  if not emitter then SetStatus("No emitter") return end
  emitter.send(ch,"<RequestSync>"..ShipID); SetStatus("Sync requested on "..ch)
end

function PushToChannel(ch,wps,routes)
  if not emitter then SetStatus("No emitter") return end
  local n=0
  for _,wp in ipairs(wps) do emitter.send(ch,"<PushWP>"..json.encode({n=wp.n,c=wp.c}):gsub('"',"@@@")); n=n+1 end
  for _,r in ipairs(routes) do emitter.send(ch,"<PushRoute>"..json.encode({n=r.n,pts=r.pts}):gsub('"',"@@@")); n=n+1 end
  SetStatus("Pushed "..n.." items to "..ch)
end

function EnsureOrg(name)
  for _,v in ipairs(OrgNames) do if v==name then return end end
  table.insert(OrgNames,name); OrgData[name]={wps={},routes={}}; SaveData()
end

function OrgChannelForContext()
  if ActiveContext==OrgChannel1 then return OrgChannel1 end
  if OrgChannel2~="" and ActiveContext==OrgChannel2 then return OrgChannel2 end
  if OrgChannel3~="" and ActiveContext==OrgChannel3 then return OrgChannel3 end
  return OrgChannel1
end

-- ── Keyboard menu ─────────────────────────────────────────────
-- Menu structure: all personal WPs, all personal routes,
-- then per-org WPs/routes, then fixed actions
function GetMenuItems()
  local items={}
  for _,wp in ipairs(PersonalWPs) do
    local cp=GetCurrentPos(); local tp=ParsePos(wp.c)
    local d=(cp and tp) and "  "..FormatDist(CalcDist(cp,tp)) or ""
    table.insert(items,{type="wp",ctx="personal",n=wp.n,c=wp.c,
      label="[WP]    "..wp.n..d})
  end
  for _,r in ipairs(PersonalRoutes) do
    table.insert(items,{type="route",ctx="personal",n=r.n,
      label="[ROUTE] "..r.n.."  ("..#r.pts.." stops)"})
  end
  for _,org in ipairs(OrgNames) do
    for _,wp in ipairs(OrgData[org].wps) do
      local cp=GetCurrentPos(); local tp=ParsePos(wp.c)
      local d=(cp and tp) and "  "..FormatDist(CalcDist(cp,tp)) or ""
      table.insert(items,{type="wp",ctx=org,n=wp.n,c=wp.c,
        label="["..org.."/WP] "..wp.n..d})
    end
    for _,r in ipairs(OrgData[org].routes) do
      table.insert(items,{type="route",ctx=org,n=r.n,
        label="["..org.."/RT] "..r.n.."  ("..#r.pts.." stops)"})
    end
  end
  table.insert(items,{type="mark_wp",   label="[ACT] Mark WP Here"})
  table.insert(items,{type="next_stop", label="[ACT] Next Stop"})
  table.insert(items,{type="prev_stop", label="[ACT] Prev Stop"})
  table.insert(items,{type="clear_nav", label="[ACT] Clear Navigation"})
  table.insert(items,{type="sync_base", label="[ACT] Sync from Base"})
  table.insert(items,{type="sync_org",  label="[ACT] Sync from Org (ch1)"})
  table.insert(items,{type="push_base", label="[ACT] Push to Base"})
  return items
end

function DrawHUD()
  if not HUD_VISIBLE then system.showScreen(0) return end
  local W=system.getScreenWidth(); local H=system.getScreenHeight()
  local sc=H/1080
  local pw=math.floor(340*sc)
  local fs=math.floor(14*sc); local fsS=math.floor(12*sc)
  local rh=math.floor(26*sc)
  local px=math.floor(W*0.18); local py=math.floor(H*0.30)

  local items=GetMenuItems()
  local winSize=12
  local si=math.max(1, MenuIndex-5)
  local ei=math.min(#items, si+winSize-1)
  if ei-si < winSize-1 then si=math.max(1,ei-winSize+1) end

  local h={}
  h[#h+1]=string.format([[<style>
   .np{position:absolute;top:%dpx;left:%dpx;width:%dpx;background:rgba(0,5,25,0.88);border:1px solid rgba(0,140,255,0.55);}
   .nt{font-family:Arial;font-size:%dpx;color:rgb(0,210,255);text-align:center;padding:3px 6px;background:rgba(0,70,150,0.5);}
   .nr{font-family:Arial;font-size:%dpx;color:rgb(160,190,230);padding:2px 8px;border-top:1px solid rgba(0,80,180,0.25);white-space:nowrap;overflow:hidden;}
   .ng{color:rgb(0,220,160);}
   .ns{background:rgba(0,110,240,0.55);color:white;}
   .nh{color:rgb(90,120,155);font-size:%dpx;text-align:center;padding:2px;}
  </style>]], py,px,pw, fs,fs,fsS)
  h[#h+1]='<div class="np">'
  h[#h+1]=string.format('<div class="nt">NAVIGATOR  %s</div>', ShipID)

  -- nav target
  if NavTarget then
    local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos()
    local dist=(tp and cp) and FormatDist(CalcDist(cp,tp)) or "---"
    local lbl=(NavTarget.t=="route") and "ROUTE" or "WP"
    local si2=(NavTarget.t=="route") and string.format(" [%d/%d]",NavTarget.stopIdx,NavTarget.stopTotal) or ""
    h[#h+1]=string.format('<div class="nr ng">&#9658; %s: %s%s  %s</div>', lbl, NavTarget.n, si2, dist)
  else
    h[#h+1]='<div class="nr ng">&#9658; No target</div>'
  end

  -- hint row
  if #items>0 then
    h[#h+1]=string.format('<div class="nh">(%d/%d)  Alt+&#8593;&#8595; browse  |  Alt+&#8594; select</div>', MenuIndex>0 and MenuIndex or 0, #items)
  else
    h[#h+1]='<div class="nh">No waypoints — type: add NAME</div>'
  end

  -- item list
  for i=si,ei do
    local item=items[i]
    local cls=(i==MenuIndex) and 'nr ns' or 'nr'
    local pre=(i==MenuIndex) and '&#9658; ' or '&#160;&#160;&#160;'
    h[#h+1]=string.format('<div class="%s">%s%s</div>', cls, pre, item.label)
  end

  h[#h+1]='</div>'
  system.setScreen(table.concat(h))
  system.showScreen(1)
end

function ActivateMenuItem()
  if MenuIndex<=0 then SetStatus("Alt+Up/Down to browse, Alt+Right to activate") return end
  local items=GetMenuItems()
  local item=items[MenuIndex]
  if not item then return end
  if item.type=="wp" then
    ActiveContext=item.ctx
    SetNavWP(item.n)
  elseif item.type=="route" then
    ActiveContext=item.ctx
    SetNavRoute(item.n,1)
  elseif item.type=="mark_wp" then
    local p=GetCurrentPosStr()
    if p then AddWP(AutoName("WP",ContextWPs()),p) else SetStatus("No position") end
  elseif item.type=="next_stop"  then NextStop()
  elseif item.type=="prev_stop"  then PrevStop()
  elseif item.type=="clear_nav"  then ClearWaypoint();SetStatus("Nav cleared")
  elseif item.type=="sync_base"  then RequestSync(BaseChannel)
  elseif item.type=="sync_org"   then RequestSync(OrgChannel1)
  elseif item.type=="push_base"  then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes)
  end
  DrawHUD()
end

-- ── Init ──────────────────────────────────────────────────────
do
  local ok,res=pcall(require,"autoconf/custom/"..CustomAtlas)
  if ok then Atlas=res; system.print("[NAV] Loaded custom atlas: "..CustomAtlas)
  else
    local ok2,res2=pcall(require,"atlas")
    if ok2 then Atlas=res2; system.print("[NAV] Loaded default atlas")
    else system.print("[NAV] WARNING: No atlas loaded — planet distances unavailable") end
  end
end
LoadData()
local chs={BaseChannel}
if OrgChannel1~="" then table.insert(chs,OrgChannel1) end
if OrgChannel2~="" then table.insert(chs,OrgChannel2) end
if OrgChannel3~="" then table.insert(chs,OrgChannel3) end
if receiver then receiver.setChannelList(chs) end
unit.setTimer("nav_tick",5)
UpdateWaypoint()
DrawHUD()
system.print("=== Navigator "..VERSION.." (No Screen) ===  "..ShipID)
system.print("Target: "..(NavTarget and NavTarget.n or "none"))
system.print("Alt+Up/Down = browse  |  Alt+Right = activate  |  type help")


--[[@
slot=-1
event=onStop()
args=
]]
system.setWaypoint("")
system.showScreen(0)


--[[@
slot=-1
event=onTimer(tag)
args="nav_tick"
]]
UpdateWaypoint()
DrawHUD()
if NavTarget then
  local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos()
  local dist=(tp and cp) and FormatDist(CalcDist(cp,tp)) or "---"
  local lbl=(NavTarget.t=="route") and "[ROUTE]" or "[WP]"
  system.print("[NAV] "..lbl.." "..NavTarget.n.."  "..dist)
  if NavTarget.t=="route" then system.print("[NAV] Stop "..NavTarget.stopIdx.."/"..NavTarget.stopTotal) end
end


--[[@
slot=-4
event=onActionLoop(action)
args="lalt"
]]
L_ALT=true


--[[@
slot=-4
event=onActionStop(action)
args="lalt"
]]
L_ALT=false


--[[@
slot=-4
event=onActionLoop(action)
args="lshift"
]]
L_SHIFT=true


--[[@
slot=-4
event=onActionStop(action)
args="lshift"
]]
L_SHIFT=false


--[[@
slot=-4
event=onActionStart(action)
args="insert"
]]
if L_ALT and L_SHIFT then
  HUD_VISIBLE=not HUD_VISIBLE
  DrawHUD()
end


--[[@
slot=-4
event=onActionStart(action)
args="up"
]]
if not L_ALT then return end
local items=GetMenuItems()
if #items==0 then SetStatus("No items") return end
MenuIndex=(MenuIndex<=1) and #items or (MenuIndex-1)
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="down"
]]
if not L_ALT then return end
local items=GetMenuItems()
if #items==0 then SetStatus("No items") return end
MenuIndex=(MenuIndex>=#items) and 1 or (MenuIndex+1)
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="right"
]]
if not L_ALT then return end
ActivateMenuItem()


--[[@
slot=1
event=onReceived(channel,message)
args=*,*
]]
local isOrg=(channel==OrgChannel1 or channel==OrgChannel2 or channel==OrgChannel3)

if message:find("<OrgName>",1,true) then
  SyncOrgName=Trim(message:gsub("<OrgName>",""))
  EnsureOrg(SyncOrgName)
end
if message:find("<SyncCount>",1,true) then
  SyncReceived=0
  SetStatus("Syncing from "..(isOrg and (SyncOrgName~="" and SyncOrgName or "org") or "base").."...")
end
if message:find("<SyncWP>",1,true) then
  local raw=message:gsub("<SyncWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    SyncReceived=(SyncReceived or 0)+1
    if isOrg and SyncOrgName~="" then
      EnsureOrg(SyncOrgName)
      local list=OrgData[SyncOrgName].wps
      local found=false
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    else
      local found=false
      for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(PersonalWPs,{n=wp.n,c=wp.c}) end
    end
  end
end
if message:find("<SyncRoute>",1,true) then
  local raw=message:gsub("<SyncRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    SyncReceived=(SyncReceived or 0)+1
    local list=((isOrg and SyncOrgName~="") and OrgData[SyncOrgName] and OrgData[SyncOrgName].routes) or PersonalRoutes
    local found=false
    for i,e in ipairs(list) do if e.n:lower()==r.n:lower() then list[i]=r;found=true;break end end
    if not found then table.insert(list,r) end
  end
end
if message:find("<SyncComplete>",1,true) then
  if isOrg and SyncOrgName~="" then
    table.sort(OrgData[SyncOrgName].wps,   function(a,b) return a.n:lower()<b.n:lower() end)
    table.sort(OrgData[SyncOrgName].routes,function(a,b) return a.n:lower()<b.n:lower() end)
  else
    table.sort(PersonalWPs,   function(a,b) return a.n:lower()<b.n:lower() end)
    table.sort(PersonalRoutes,function(a,b) return a.n:lower()<b.n:lower() end)
  end
  SaveData(); SetStatus("Sync done: "..SyncReceived.." items")
end
if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    local found=false
    for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
    if not found then table.insert(PersonalWPs,{n=wp.n,c=wp.c}) end
    SaveData()
  end
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

if lo=="help" then
  system.print("═══════════════════════════════")
  system.print("  NAVIGATOR v2.0  (No Screen)")
  system.print("═══════════════════════════════")
  system.print("add NAME [::pos{..}]   save WP")
  system.print("del NAME               delete WP")
  system.print("newroute NAME          create route")
  system.print("addstop ROUTE WP/pos   add stop")
  system.print("delstop ROUTE N        remove stop N")
  system.print("delroute NAME          delete route")
  system.print("nav NAME               navigate to WP or route")
  system.print("nav off                clear nav")
  system.print("next / prev            next/prev stop")
  system.print("sync / orgsync         sync from base")
  system.print("push / orgpush         push to base")
  system.print("org NAME               switch active context")
  system.print("list / routes          list items")
  system.print("status                 show current nav")
  system.print("Alt+Up/Down = browse  |  Alt+Right = activate")
  return
end

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(%S+)%s*(.*)")
if addN then
  addC=Trim(addC)
  if addC=="" then
    local p=GetCurrentPosStr()
    if p then AddWP(addN,p) else SetStatus("No position") end
  else
    if ParsePos(addC) then AddWP(addN,addC) else SetStatus("Bad coords") end
  end
  return
end

local delN=t:match("^[Dd][Ee][Ll]%s+(%S+)$")
if delN and delN:lower()~="route" then DelWP(Trim(delN)); return end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(Trim(nrN)); return end

local asRT,asArg=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(%S+)%s+(.*)")
if asRT then AddStop(Trim(asRT),Trim(asArg)); return end

local dsRT,dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%S+)%s+(%d+)")
if dsRT then DelStop(Trim(dsRT),tonumber(dsN)); return end

local drN=t:match("^[Dd][Ee][Ll][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if drN then DelRoute(Trim(drN)); return end

local navN=t:match("^[Nn][Aa][Vv]%s+(.*)")
if navN then
  navN=Trim(navN)
  if navN=="" or navN:lower()=="off" or navN:lower()=="clear" then
    ClearWaypoint();SetStatus("Nav cleared")
  else
    if not SetNavWP(navN) then SetNavRoute(navN,1) end
  end
  return
end

if lo=="next"    then NextStop(); return end
if lo=="prev"    then PrevStop(); return end
if lo=="sync"    then RequestSync(BaseChannel); return end
if lo=="orgsync" then RequestSync(OrgChannelForContext()); return end
if lo=="push"    then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes); return end
if lo=="orgpush" then
  local org=ActiveContext
  if org~="personal" and OrgData[org] then PushToChannel(OrgChannelForContext(),OrgData[org].wps,OrgData[org].routes)
  else SetStatus("Set org context first: org ORGNAME") end
  return
end

local orgCtx=t:match("^[Oo][Rr][Gg]%s+(.+)")
if orgCtx then
  orgCtx=Trim(orgCtx)
  if orgCtx:lower()=="personal" then ActiveContext="personal"; SetStatus("Context: personal")
  else
    local found=false
    for _,o in ipairs(OrgNames) do if o:lower()==orgCtx:lower() then ActiveContext=o;found=true;break end end
    if found then SetStatus("Context: "..ActiveContext)
    else SetStatus("Unknown org: "..orgCtx.."  known: "..table.concat(OrgNames,", ")) end
  end
  return
end

if lo=="status" then
  if not NavTarget then system.print("[NAV] No target") return end
  local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos()
  local dist=(tp and cp) and FormatDist(CalcDist(cp,tp)) or "---"
  system.print("[NAV] "..(NavTarget.t=="route" and "[ROUTE]" or "[WP]").." "..NavTarget.n.."  "..dist)
  if NavTarget.t=="route" then system.print("[NAV] Stop "..NavTarget.stopIdx.."/"..NavTarget.stopTotal) end
  return
end

if lo=="list" then
  system.print("─── PERSONAL WPs ("..#PersonalWPs..") ───")
  for i,wp in ipairs(PersonalWPs) do system.print(i..".  "..wp.n.."  "..wp.c) end
  for _,org in ipairs(OrgNames) do
    local wps=OrgData[org].wps
    system.print("─── "..org.." WPs ("..#wps..") ───")
    for i,wp in ipairs(wps) do system.print(i..".  "..wp.n.."  "..wp.c) end
  end
  return
end

if lo=="routes" then
  system.print("─── PERSONAL ROUTES ("..#PersonalRoutes..") ───")
  for i,r in ipairs(PersonalRoutes) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  for _,org in ipairs(OrgNames) do
    local rs=OrgData[org].routes
    system.print("─── "..org.." ROUTES ("..#rs..") ───")
    for i,r in ipairs(rs) do
      system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
      for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
    end
  end
  return
end

SetStatus("Unknown: '"..lo.."'  type help")
